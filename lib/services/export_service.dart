import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/checkin.dart';
import '../models/meal_log.dart';
import '../models/workout_session_doc.dart';
import '../repos/lyva_repo.dart';

/// Service for exporting user data to CSV or PDF.
class ExportService {
  final LyvaRepo _repo;

  ExportService(this._repo, {Future<Directory> Function()? temporaryDirectory,
    pw.Document Function()? documentFactory})
      : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
        _documentFactory = documentFactory ?? pw.Document.new;
  final Future<Directory> Function() _temporaryDirectory;
  final pw.Document Function() _documentFactory;

  static String workoutDayLabel(WorkoutSessionDoc session) =>
      session.dayIndex > 0 ? 'Day ${session.dayIndex}' : 'Unknown day';

  static void _validateRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) throw ArgumentError('Export end precedes start');
  }

  // ===== CSV EXPORT =====

  Future<File> exportCsv({
    required DateTime startDate,
    required DateTime endDate,
    required bool includeCheckIns,
    required bool includeMeals,
    required bool includeWorkouts,
  }) async {
    _validateRange(startDate, endDate);
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    if (includeCheckIns) {
      final checkIns = await _repo.getCheckInsInDateRange(startDate, endDate);
      buffer.writeln('=== CHECK-INS ===');
      buffer.writeln('Date,Weight (kg),Waist (cm),Steps,Mood (1-5),Energy (1-5),Notes,Sleep (1-5),Stress (1-5),Soreness (1-5),Hunger (1-5)');
      for (final c in checkIns) {
        final date = dateFormat.format(c.ts.toLocal());
        final note = (c.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        buffer.writeln(
          '$date,${c.weightKg ?? ''},${c.waistCm ?? ''},${c.stepsToday ?? ''},${c.moodScore ?? ''},${c.energyScore ?? ''},$note,${c.sleepScore ?? ''},${c.stressScore ?? ''},${c.sorenessScore ?? ''},${c.hungerScore ?? ''}',
        );
      }
      buffer.writeln();
    }

    if (includeMeals) {
      final filtered = await _repo.getMealsInDateRange(startDate, endDate);
      buffer.writeln('=== MEALS ===');
      buffer.writeln('Date,Time,Type,Protein (g),Carbs (g),Fat (g),Calories,Description');
      for (final m in filtered) {
        final date = dateFormat.format(m.ts.toLocal());
        final time = timeFormat.format(m.ts.toLocal());
        final desc = (m.description ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        buffer.writeln(
          '$date,$time,${m.mealType},${m.proteinG},${m.carbsG},${m.fatG},${m.calories},$desc',
        );
      }
      buffer.writeln();
    }

    if (includeWorkouts) {
      final sessions = await _repo.getSessionsInDateRange(startDate, endDate);
      buffer.writeln('=== WORKOUTS ===');
      buffer.writeln('Date,Day,Completed,Skipped,Skip Reason,Notes,Perceived exertion (1-5)');
      for (final s in sessions) {
        final date = dateFormat.format(s.date.toLocal());
        final reason = (s.skipReason ?? '').replaceAll(',', ';');
        final notes = (s.notes ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        buffer.writeln(
          '$date,${workoutDayLabel(s)},${s.completed ? 'Yes' : 'No'},${s.skipped ? 'Yes' : 'No'},$reason,$notes,${s.perceivedExertion ?? ''}',
        );
      }
    }

    final dir = await _temporaryDirectory();
    final file = File('${dir.path}/lyva_export_${dateFormat.format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  // ===== PDF EXPORT =====

  Future<File> exportPdf({
    required DateTime startDate,
    required DateTime endDate,
    required bool includeCheckIns,
    required bool includeMeals,
    required bool includeWorkouts,
    String? userName,
  }) async {
    _validateRange(startDate, endDate);
    final pdf = _documentFactory();
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRangeText =
        '${dateFormat.format(startDate.toLocal())} - ${dateFormat.format(endDate.toLocal())}';

    // Gather data
    List<CheckIn> checkIns = [];
    List<MealLog> meals = [];
    List<WorkoutSessionDoc> sessions = [];

    if (includeCheckIns) {
      checkIns = await _repo.getCheckInsInDateRange(startDate, endDate);
    }
    if (includeMeals) {
      meals = await _repo.getMealsInDateRange(startDate, endDate);
    }
    if (includeWorkouts) {
      sessions = await _repo.getSessionsInDateRange(startDate, endDate);
    }

    final weights = checkIns.where((c) => c.weightKg != null && c.weightKg!.isFinite && c.weightKg! > 0).toList();

    // Page 1: Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Lyva Progress Report',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (userName != null)
              pw.Text(userName, style: const pw.TextStyle(fontSize: 16)),
            pw.Text(dateRangeText,
                style: pw.TextStyle(
                    fontSize: 14, color: PdfColor.fromInt(0xFF888888))),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),

            // Summary metrics
            pw.Text('Summary',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),

            if (checkIns.isNotEmpty) ...[
              _pdfMetricRow('Check-ins', '${checkIns.length}'),
              if (weights.length >= 2) ...[
                _pdfMetricRow('Starting Weight',
                    '${weights.last.weightKg!.toStringAsFixed(1)} kg'),
                _pdfMetricRow('Current Weight',
                    '${weights.first.weightKg!.toStringAsFixed(1)} kg'),
                _pdfMetricRow(
                  'Weight Change',
                  '${(weights.first.weightKg! - weights.last.weightKg!).toStringAsFixed(1)} kg',
                ),
              ],
            ],

            if (meals.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              _pdfMetricRow('Meals Logged', '${meals.length}'),
              _pdfMetricRow(
                'Avg Daily Calories',
                '${_avgDailyCalories(meals).round()}',
              ),
            ],

            if (sessions.isNotEmpty) ..._buildWorkoutSummary(sessions),
          ],
        ),
      ),
    );

    // Page 2+: Check-in table
    if (includeCheckIns && checkIns.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('Check-in History',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Weight', 'Waist', 'Steps', 'Mood', 'Energy', 'Recovery'],
              data: checkIns.map((c) {
                final df = DateFormat('MMM d');
                return [
                  df.format(c.ts.toLocal()),
                  c.weightKg == null ? '-' : '${c.weightKg!.toStringAsFixed(1)} kg',
                  c.waistCm != null ? '${c.waistCm} cm' : '-',
                  c.stepsToday?.toString() ?? '-',
                  c.moodScore?.toString() ?? '-',
                  c.energyScore?.toString() ?? '-',
                  'Sleep:${c.sleepScore ?? '-'} Stress:${c.stressScore ?? '-'} Soreness:${c.sorenessScore ?? '-'} Hunger:${c.hungerScore ?? '-'}',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    // Page 3+: Meal table
    if (includeMeals && meals.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('Meal History',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Protein', 'Carbs', 'Fat', 'Calories'],
              data: meals.map((m) {
                final df = DateFormat('MMM d');
                return [
                  df.format(m.ts.toLocal()),
                  m.mealType,
                  '${m.proteinG}g',
                  '${m.carbsG}g',
                  '${m.fatG}g',
                  '${m.calories}',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    // Page 4+: Workout table
    if (includeWorkouts && sessions.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('Workout History',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Day', 'Status', 'Notes', 'Effort (1-5)'],
              data: sessions.map((s) {
                final df = DateFormat('MMM d');
                final status = s.completed
                    ? 'Completed'
                    : s.skipped
                        ? 'Skipped: ${s.skipReason ?? ''}'
                        : 'Pending';
                return [
                  df.format(s.date.toLocal()),
                  workoutDayLabel(s),
                  status,
                  s.notes ?? '',
                  s.perceivedExertion?.toString() ?? '',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    final dir = await _temporaryDirectory();
    final file = File(
        '${dir.path}/lyva_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Helpers

  pw.Widget _pdfMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  List<pw.Widget> _buildWorkoutSummary(List<WorkoutSessionDoc> sessions) {
    final completed = sessions.where((s) => s.completed).length;
    final rate = (completed / sessions.length * 100).round();
    return [
      pw.SizedBox(height: 8),
      _pdfMetricRow('Workouts Completed', '$completed'),
      _pdfMetricRow('Completion Rate', '$rate%'),
    ];
  }

  double _avgDailyCalories(List<MealLog> meals) {
    if (meals.isEmpty) return 0;
    final totalCal = meals.fold<int>(0, (sum, m) => sum + m.calories);
    final days = <String>{};
    for (final m in meals) {
      days.add(DateFormat('yyyy-MM-dd').format(m.ts.toLocal()));
    }
    return days.isEmpty ? 0 : totalCal / days.length;
  }
}
