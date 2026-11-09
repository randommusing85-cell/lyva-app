import 'weekly_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state/providers.dart';
import '../widgets/recorded_week_card.dart';
import 'workout_facts_screen.dart';

/// Local evidence only. Opening this screen never requests an AI proposal.
class PlanReviewScreen extends ConsumerStatefulWidget {
  const PlanReviewScreen({super.key});
  @override
  ConsumerState<PlanReviewScreen> createState() => _PlanReviewState();
}

class _PlanReviewState extends ConsumerState<PlanReviewScreen> {
  final anchor = DateTime.now();
  int section = 0;
  String? change;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Plan review')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Review saved information on this device. These views are available without an account and do not send information to a coach.',
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final item in [
              'Explain my plan',
              'Review my week',
              'Something changed',
            ].asMap().entries)
              ChoiceChip(
                label: Text(item.value),
                selected: section == item.key,
                onSelected: (_) => setState(() => section = item.key),
              ),
          ],
        ),
        if (section == 0) ...[
          const Text('Saved nutrition targets'),
          ref
              .watch(activePlanProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Column(
                  children: [
                    const Text('Saved plan could not be loaded.'),
                    TextButton(
                      onPressed: () => ref.invalidate(activePlanProvider),
                      child: const Text('Retry plan'),
                    ),
                  ],
                ),
                data: (p) => p == null
                    ? const Text(
                        'Saved nutrition targets are unavailable in this view. This does not delete any records.',
                      )
                    : Text(
                        '${p.planName}\nSaved ${DateFormat.yMMMd().add_Hm().format(p.createdAt)}\n'
                        '${p.calories} kcal; protein ${p.proteinG} g; carbs ${p.carbsG} g; fat ${p.fatG} g; steps ${p.stepTarget}.\n'
                        'These are recorded targets, not a new recommendation.',
                      ),
              ),
          const Text(
            'A verified rationale and next review date are not stored with this plan. They cannot be reconstructed from the targets alone.',
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WorkoutFactsScreen(),
              ),
            ),
            child: const Text('View saved workout facts'),
          ),
        ],
        if (section == 1) ...[
          RecordedWeekCard(anchor: anchor),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WeeklyReviewScreen(),
              ),
            ),
            child: const Text('Review a local no-change decision'),
          ),
          const Text(
            'This summary describes recorded activity. It does not establish that a plan change is needed. No targets will change from this review.',
          ),
        ],
        if (section == 2) ...[
          const Text(
            'What changed? Your selection is temporary and is not saved or sent.',
          ),
          for (final label in [
            'A recorded entry is incorrect',
            'My availability or equipment changed',
            'My health or comfort changed',
          ])
            ChoiceChip(
              label: Text(label),
              selected: change == label,
              onSelected: (_) => setState(() => change = label),
            ),
          if (change == 'A recorded entry is incorrect')
            const Text(
              'Data: correct the original record where editing is available. This review cannot correct every history type yet and will not replace missing values with assumptions.',
            ),
          if (change == 'My availability or equipment changed')
            const Text(
              'Plan changes: review your saved workout facts first. Automatic revisions and reviewed exercise alternatives are not available here. Existing prescriptions remain unchanged.',
            ),
          if (change == 'My health or comfort changed')
            const Text(
              'Safety: this screen cannot assess symptoms or determine whether a workout or nutrition target is suitable. A subscription does not provide that assessment.',
            ),
          const Text(
            'Before any future revision, review its evidence, rationale and before/after targets. No revision is created or applied here.',
          ),
        ],
        const Divider(),
        const Text(
          'Data limits: missing records and missing rationale are shown explicitly.',
        ),
        const Text(
          'Safety limits: recorded targets and activity do not establish clinical suitability.',
        ),
        const Text(
          'Service access: remote coaching requires a recoverable account and verified server access. Paid access cannot resolve missing evidence or safety limits. This local review uses no AI quota.',
        ),
      ],
    ),
  );
}
