import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';
import '../db/isar_db.dart';
import '../models/checkin.dart';
import '../models/prime_plan.dart';
import '../models/workout_session_doc.dart';
import '../models/workout_template_doc.dart';
import '../models/weekly_review.dart';
import '../models/recorded_week.dart';
import '../utils/nutrition_adjustment.dart';

class WeeklyReviewView {
  final WeeklyReview review;
  final RecordedWeek week;
  final String targets;
  final bool stale;
  const WeeklyReviewView(this.review, this.week, this.targets, this.stale);
}

class _Evidence {
  final String revision, targets;
  final RecordedWeek week;
  const _Evidence(this.revision, this.targets, this.week);
}

/// Default-deny adaptation foundation: the only possible proposal is no change.
/// Device-local, like existing activity. No account, memory, AI or network use.
class WeeklyReviewService {
  final Future<Isar> Function() open;
  final DateTime Function() now;
  WeeklyReviewService({
    Future<Isar> Function()? openDatabase,
    DateTime Function()? clock,
  }) : open = openDatabase ?? IsarDb.instance,
       now = clock ?? DateTime.now;
  String _date(DateTime d) => d.toUtc().toIso8601String();
  Future<_Evidence> _evidence(Isar db, DateTime start, DateTime time) async {
    final end = DateTime(start.year, start.month, start.day + 7);
    final plans = await db.primePlans.where().sortByCreatedAtDesc().findAll();
    final templates = await db.workoutTemplateDocs
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    final checks = await db.checkIns
        .filter()
        .tsGreaterThan(start, include: true)
        .and()
        .tsLessThan(end)
        .findAll();
    final sessions = await db.workoutSessionDocs
        .filter()
        .dateGreaterThan(start, include: true)
        .and()
        .dateLessThan(end)
        .findAll();
    checks.sort((a, b) => a.id.compareTo(b.id));
    sessions.sort((a, b) => a.id.compareTo(b.id));
    plans.sort((a, b) {
      final time = b.createdAt.compareTo(a.createdAt);
      return time != 0 ? time : b.id.compareTo(a.id);
    });
    templates.sort((a, b) {
      final time = b.createdAt.compareTo(a.createdAt);
      return time != 0 ? time : b.id.compareTo(a.id);
    });
    final plan = plans.isEmpty ? null : plans.first;
    final template = templates.isEmpty ? null : templates.first;
    final payload = [
      1,
      _date(start),
      '${time.year}-${time.month}-${time.day}',
      plan == null ? null : nutritionPlanRevision(plan),
      template == null
          ? null
          : [
              template.id,
              _date(template.createdAt),
              template.json,
              template.planName,
              template.daysPerWeek,
              template.level,
              template.equipment,
              template.sex,
            ],
      checks
          .map(
            (c) => [
              c.id,
              _date(c.ts),
              !c.ts.isAfter(time),
              c.weightKg,
              c.waistCm,
              c.stepsToday,
              c.note,
              c.moodScore,
              c.energyScore,
            ],
          )
          .toList(),
      sessions
          .map(
            (s) => [
              s.id,
              _date(s.date),
              !s.date.isAfter(time),
              s.dayIndex,
              s.completed,
              s.skipped,
              s.skipReason,
              s.notes,
              s.planId,
              s.templateSnapshotJson,
              s.progressJson,
            ],
          )
          .toList(),
    ];
    return _Evidence(
      sha256.convert(utf8.encode(jsonEncode(payload))).toString(),
      plan == null
          ? 'No nutrition targets saved.'
          : '${plan.calories} kcal; protein ${plan.proteinG} g; carbs ${plan.carbsG} g; fat ${plan.fatG} g; steps ${plan.stepTarget}.',
      RecordedWeek.resolve(
        anchor: start,
        now: time,
        sessions: sessions,
        checkIns: checks,
      ),
    );
  }

  Future<WeeklyReviewView> prepare() async {
    final db = await open();
    return db.writeTxn(() async {
      final time = now().toLocal();
      final start = RecordedWeek.start(time);
      final evidence = await _evidence(db, start, time);
      final reviews = await db.weeklyReviews.where().findAll();
      for (final review in reviews) {
        if (review.schemaVersion == 1 &&
            review.weekStart == start &&
            review.sourceRevision == evidence.revision) {
          return WeeklyReviewView(
            review,
            evidence.week,
            evidence.targets,
            false,
          );
        }
      }
      for (final review in reviews.where((r) => r.status == 'draft')) {
        review.status = 'stale';
        await db.weeklyReviews.put(review);
      }
      final review = WeeklyReview()
        ..weekStart = start
        ..createdAt = time
        ..sourceRevision = evidence.revision
        ..decisionToken = List.generate(
          32,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
      await db.weeklyReviews.put(review);
      return WeeklyReviewView(review, evidence.week, evidence.targets, false);
    });
  }

  Future<WeeklyReviewView> decide(
    int id,
    String revision, {
    required bool accept,
  }) async {
    final db = await open();
    return db.writeTxn(() async {
      final review = await db.weeklyReviews.get(id);
      if (review == null ||
          review.schemaVersion != 1 ||
          review.decisionToken != revision ||
          review.status != 'draft') {
        throw StateError('Review is missing or already decided. Reload.');
      }
      final time = now().toLocal();
      final evidence = await _evidence(db, review.weekStart, time);
      final stale =
          evidence.revision != review.sourceRevision ||
          RecordedWeek.start(time) != review.weekStart;
      review.status = stale
          ? 'stale'
          : accept
          ? 'accepted'
          : 'declined';
      review.decidedAt = time;
      await db.weeklyReviews.put(review);
      return WeeklyReviewView(review, evidence.week, evidence.targets, stale);
    });
  }

  /// Reverses only the recorded decision; no plan was changed to roll back.
  Future<void> withdraw(int id, String revision) async {
    final db = await open();
    await db.writeTxn(() async {
      final review = await db.weeklyReviews.get(id);
      if (review == null ||
          review.decisionToken != revision ||
          review.status != 'accepted' ||
          review.schemaVersion != 1) {
        throw StateError('Decision is no longer current.');
      }
      review.status = 'withdrawn';
      review.decidedAt = now();
      await db.weeklyReviews.put(review);
    });
  }

  Future<void> delete(int id) async {
    final db = await open();
    await db.writeTxn(() async {
      await db.weeklyReviews.delete(id);
    });
  }
}
