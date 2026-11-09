import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';

/// Compatibility widget name; no phase or hormone inference is displayed.
class CyclePhaseCard extends ConsumerWidget {
  const CyclePhaseCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(userProfileProvider).valueOrNull?.trackCycle != true) {
      return const SizedBox.shrink();
    }
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle records',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Record your own bleeding events and symptoms. Calendar dates cannot establish hormone levels, ovulation or how hard you should train.',
            ),
          ],
        ),
      ),
    );
  }
}
