import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';

class WorkoutFactsScreen extends ConsumerStatefulWidget {
  const WorkoutFactsScreen({super.key});
  @override
  ConsumerState<WorkoutFactsScreen> createState() => _WorkoutFactsScreenState();
}

class _WorkoutFactsScreenState extends ConsumerState<WorkoutFactsScreen> {
  final _input = TextEditingController();
  String? _answer;
  bool _busy = false;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask(String question) async {
    if (_busy || question.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _answer = null;
    });
    final result = await ref
        .read(routineWorkoutAnswersProvider)
        .answer(question);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _answer = result.text;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Workout facts')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Read your saved prescriptions locally. No AI allowance is used. These are saved targets, not technique or medical advice.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final question in ["Today's workout", 'Plan schedule'])
              ActionChip(
                label: Text(question),
                onPressed: _busy ? null : () => _ask(question),
              ),
          ],
        ),
        TextField(
          controller: _input,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Ask about your saved workout',
            hintText: 'rest for exercise 1',
          ),
          onSubmitted: _ask,
        ),
        FilledButton(
          onPressed: _busy ? null : () => _ask(_input.text),
          child: const Text('Read saved data'),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_answer != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SelectableText(_answer!),
          ),
      ],
    ),
  );
}
