import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/personalization_safety.dart';
import '../state/providers.dart';

class PostPartumStatusCard extends ConsumerWidget {
  const PostPartumStatusCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(userProfileProvider).maybeWhen(
    data: (profile) => profile == null || profile.postPartumStatus == 'no'
      ? const SizedBox.shrink() : Card(child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Postpartum tracking', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(PersonalizationDecision.evaluate(profile).message),
          const SizedBox(height: 8),
          const Text('This is a requirement for Lyva’s tailored plans, not a rule that all movement must wait a fixed number of weeks. Follow your clinician’s individual guidance and restrictions.'),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/edit-profile'), child: const Text('Update reported clearance')),
        ]))),
    orElse: () => const SizedBox.shrink());
}
