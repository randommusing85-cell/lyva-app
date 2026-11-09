import 'package:flutter/material.dart';

/// Product orientation only; no example prescription or exercise technique.
class FirstSessionIntroScreen extends StatelessWidget {
  const FirstSessionIntroScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your first session')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Your profile is saved',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'You can use basic tracking without an account. Choosing a plan, notifications and optional setup can wait.',
        ),
        const SizedBox(height: 20),
        const Text(
          'When you have a saved workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Open Today’s Workout to see the current day. Sets are groups of repetitions; reps are repetitions within a set. Rest is the saved time between sets.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Workout facts reads the sets, reps and rest from your saved plan. It does not generate a new plan or provide technique or medical advice.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Mark exercises as you finish and save the session to keep it in history. If no plan is saved, Lyva will tell you rather than invent a workout.',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false),
          child: const Text('Explore basic tracking'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/setup-guide'),
          child: const Text('View optional setup'),
        ),
      ],
    ),
  );
}
