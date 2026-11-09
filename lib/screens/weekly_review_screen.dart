import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/weekly_review_service.dart';

final weeklyReviewServiceProvider = Provider<WeeklyReviewService>(
  (ref) => WeeklyReviewService(),
);

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});
  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewState();
}

class _WeeklyReviewState extends ConsumerState<WeeklyReviewScreen> {
  WeeklyReviewView? view;
  bool busy = false, confirmed = false;
  String? error;
  Future<void> _run(Future<void> Function(WeeklyReviewService) action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action(ref.read(weeklyReviewServiceProvider));
    } catch (_) {
      if (mounted) {
        setState(() {
          error =
              'Review could not be completed. Reload the evidence before deciding.';
          view = null;
          confirmed = false;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _load() => _run((service) async {
    final result = await service.prepare();
    if (mounted) {
      setState(() {
        view = result;
        confirmed = false;
      });
    }
  });
  Future<void> _decide(bool accept) => _run((service) async {
    final current = view!;
    final result = await service.decide(
      current.review.id,
      current.review.decisionToken,
      accept: accept,
    );
    if (mounted) {
      setState(() {
        view = result;
        confirmed = false;
      });
    }
  });
  @override
  Widget build(BuildContext context) {
    final current = view;
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly review decision')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Local review only. Personalised adaptation is not enabled. Acknowledging this review is not a recommendation to continue a plan or a clinical assessment.',
          ),
          const Text(
            'No coach memory is read or shared. Reviews belong to this device, like the existing activity history; they are not isolated by account or synced.',
          ),
          FilledButton(
            onPressed: busy ? null : _load,
            child: const Text('Load current week evidence'),
          ),
          if (busy)
            const LinearProgressIndicator(
              semanticsLabel: 'Updating local review',
            ),
          if (error != null) Semantics(liveRegion: true, child: Text(error!)),
          if (current != null) ...[
            Text(
              'Week of ${DateFormat.yMMMd().format(current.review.weekStart)}',
            ),
            Text(
              'Review created ${DateFormat.yMMMd().add_Hm().format(current.review.createdAt)}',
            ),
            Semantics(
              liveRegion: true,
              child: Text('Status: ${current.review.status}'),
            ),
            if (current.stale)
              const Text(
                'Sources changed. This review was not accepted. Load current evidence.',
              ),
            Text(
              '${current.week.workoutDays} recorded workout day(s); ${current.week.checkInDays} recorded check-in day(s).',
            ),
            for (final day in current.week.days)
              Text('${DateFormat.MMMd().format(day.date)}: ${day.label}'),
            const Text(
              'Data sufficiency: not established for adaptation. Missing entries do not mean inactivity; recorded days do not prove adherence or readiness. No approved change rules are available.',
            ),
            Text('Before: ${current.targets}'),
            Text('After: ${current.targets}'),
            const Text(
              'Workout prescriptions also remain unchanged. Rationale: no adaptation is enabled while policy, reviewed content and service verification are unresolved. No next review date is prescribed.',
            ),
            if (current.review.status == 'draft' && !current.stale) ...[
              CheckboxListTile(
                value: confirmed,
                onChanged: busy
                    ? null
                    : (value) => setState(() => confirmed = value ?? false),
                title: const Text(
                  'I reviewed the evidence and understand no targets will change.',
                ),
              ),
              FilledButton(
                onPressed: busy || !confirmed ? null : () => _decide(true),
                child: const Text('Acknowledge no-change review'),
              ),
              TextButton(
                onPressed: busy ? null : () => _decide(false),
                child: const Text('Decline review'),
              ),
              const Text(
                'If evidence needs correction, return to the original record where editing is available, then reload this review. Target editing is not enabled here.',
              ),
            ],
            if (current.review.status == 'accepted')
              TextButton(
                onPressed: busy
                    ? null
                    : () => _run((service) async {
                        await service.withdraw(
                          current.review.id,
                          current.review.decisionToken,
                        );
                        if (mounted) {
                          setState(() {
                            view = null;
                            confirmed = false;
                          });
                        }
                      }),
                child: const Text('Withdraw acknowledgement'),
              ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => _run((service) async {
                      await service.delete(current.review.id);
                      if (mounted) {
                        setState(() {
                          view = null;
                          confirmed = false;
                        });
                      }
                    }),
              child: const Text('Delete local review record'),
            ),
            const Text(
              'The local record stores the decision, dates and a source fingerprint, not copies of health notes or targets. Deleting it leaves original activity and plans intact.',
            ),
          ],
        ],
      ),
    );
  }
}
