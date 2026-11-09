import '../widgets/personalization_boundary.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guided_progress.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan_snapshot.dart';
import '../models/workout_session_doc.dart';
import '../state/providers.dart';
import '../widgets/today_action_card.dart';

/// Reads and writes one persisted session; never follows the current plan.
class _GuidedWorkoutScreenContent extends ConsumerStatefulWidget {
  final int sessionId;
  const _GuidedWorkoutScreenContent({required this.sessionId});
  @override
  ConsumerState<_GuidedWorkoutScreenContent> createState() =>
      _GuidedWorkoutScreenState();
}

class _GuidedWorkoutScreenState extends ConsumerState<_GuidedWorkoutScreenContent> {
  WorkoutSessionDoc? session;
  WorkoutPlanSnapshot? plan;
  GuidedProgress? progress;
  List<WorkoutExercise> exercises = const [];
  bool busy = true, writing = false, notesDirty = false, allowDiscard = false;
  String? failure;
  Timer? timer;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && progress?.restUntil != null) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    notes.dispose();
    super.dispose();
  }

  void accept(WorkoutSessionDoc value) {
    final snapshot = WorkoutPlanSnapshot.fromSession(value);
    if (snapshot == null) {
      throw const FormatException('Saved prescription unavailable');
    }
    final items = GuidedProgress.exercises(snapshot, value.dayIndex);
    final saved = GuidedProgress.read(value.progressJson, items);
    session = value;
    plan = snapshot;
    exercises = items;
    progress = saved;
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      failure = null;
    });
    try {
      final saved = await ref
          .read(lyvaRepoProvider)
          .getWorkoutSession(widget.sessionId);
      if (!mounted) return;
      if (saved == null) throw StateError('Session missing');
      setState(() {
        accept(saved);
        if (!notesDirty) notes.text = saved.notes ?? '';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          session = null;
          failure =
              'Saved session unavailable. Retry to reload; no progress has been replaced.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> save(GuidedProgress next, {bool finish = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      writing = true;
      failure = null;
    });
    try {
      final saved = await ref
          .read(lyvaRepoProvider)
          .saveGuidedProgress(
            sessionId: widget.sessionId,
            planId: plan!.planId,
            progress: next,
            finish: finish,
            notes: finish ? notes.text.trim() : null,
          );
      if (!mounted) return;
      setState(() {
        accept(saved);
        if (finish) notesDirty = false;
      });
      ref.invalidate(todayActionProvider);
      ref.invalidate(todayWorkoutDayProvider);
      ref.invalidate(thisWeekSessionsProvider);
      ref.invalidate(monthlyWorkoutSessionsProvider);
    } catch (_) {
      if (mounted) {
        setState(() {
          failure =
              'Progress was not saved. Retry your action, or reload if this session changed elsewhere.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          writing = false;
        });
      }
    }
  }

  Future<void> editReps(WorkoutExercise exercise, int index) async {
    var raw = progress!.reps[exercise.id]![index]?.toString() ?? '';
    String? error;
    final result = await showPersonalizationDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Set ${index + 1} actual reps (optional)'),
          content: TextFormField(
            initialValue: raw,
            onChanged: (value) {
              raw = value;
            },
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Reps performed',
              hintText: 'Leave blank to clear',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                raw = raw.trim();
                final number = int.tryParse(raw);
                if (raw.isNotEmpty &&
                    (number == null || number < 0 || number > 1000)) {
                  update(() {
                    error = 'Enter a whole number from 0 to 1000.';
                  });
                  return;
                }
                Navigator.pop(context, raw);
              },
              child: const Text('Save reps'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      await save(
        progress!.change(
          exercises,
          exerciseId: exercise.id,
          setIndex: index,
          actualReps: int.tryParse(result),
          clearReps: result.isEmpty,
        ),
      );
    }
  }

  Future<void> finish(bool early) async {
    final confirmed = await showPersonalizationDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(early ? 'End this session early?' : 'Finish this session?'),
        content: Text(
          '${progress!.completedSets}/${progress!.totalSets} sets recorded. '
          '${early ? 'Remaining sets stay uncompleted. This day will remain next in your plan.' : 'Your summary will be saved.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save summary'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await save(progress!.change(exercises, endedEarly: early), finish: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = session, p = progress;
    return PopScope(
      canPop: !writing && (!notesDirty || allowDiscard),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || writing || !notesDirty) return;
        final discard = await showPersonalizationDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Leave without saving notes?'),
            content: const Text(
              'Your set progress is saved. These session notes are saved only when you finish; leaving will discard the notes you typed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard notes and leave'),
              ),
            ],
          ),
        );
        if (discard == true && mounted) {
          setState(() => allowDiscard = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Guided session')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (busy)
              const LinearProgressIndicator(
                semanticsLabel: 'Loading or saving session',
              ),
            if (failure != null) ...[
              Semantics(liveRegion: true, child: Text(failure!)),
              TextButton(
                onPressed: busy ? null : load,
                child: const Text('Reload saved session'),
              ),
            ],
            if (saved != null && p != null) ...[
              Text(
                '${plan!.name} · Day ${saved.dayIndex}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('${plan!.day(saved.dayIndex)!['title']}'),
              if (saved.completed || saved.skipped) ...[
                Text(
                  p.endedEarly
                      ? 'Session ended early'
                      : saved.completed
                      ? 'Session completed'
                      : 'Session skipped',
                ),
                Text('${p.completedSets}/${p.totalSets} sets recorded'),
                for (final e in exercises)
                  Text(
                    '${e.name}: ${p.done[e.id]!.where((d) => d).length}/${e.sets} sets',
                  ),
                for (final e in exercises)
                  for (var i = 0; i < e.sets; i++)
                    if (p.reps[e.id]![i] != null)
                      Text(
                        '${e.name}, set ${i + 1}: ${p.reps[e.id]![i]} actual reps${p.done[e.id]![i] ? '' : ' (not marked complete)'}',
                      ),
                if (saved.notes?.isNotEmpty == true) Text(saved.notes!),
                Text(
                  'Next in this saved plan: Day ${saved.completed ? (saved.dayIndex == plan!.daysPerWeek ? 1 : saved.dayIndex + 1) : saved.dayIndex}. Today reflects your current plan.',
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Today'),
                ),
              ] else ...[
                const ExpansionTile(
                  title: Text('Before you start'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'This flow displays your saved prescription. Mark each set you perform; actual reps are optional. '
                        'Rest uses the saved duration and can be stopped. Leaving keeps saved set progress. '
                        'Technique, demonstrations and reviewed alternatives are not available here.',
                      ),
                    ),
                  ],
                ),
                Text(
                  'Exercise ${p.currentExercise + 1} of ${exercises.length}',
                ),
                Text(
                  exercises[p.currentExercise].name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${exercises[p.currentExercise].sets} sets · ${exercises[p.currentExercise].repMin}-${exercises[p.currentExercise].repMax} reps · ${exercises[p.currentExercise].restSeconds}s rest',
                ),
                Text('${p.completedSets}/${p.totalSets} sets saved'),
                for (var i = 0; i < exercises[p.currentExercise].sets; i++) ...[
                  CheckboxListTile(
                    title: Text('Set ${i + 1}'),
                    subtitle: Text(
                      p.reps[exercises[p.currentExercise].id]![i] == null
                          ? 'Actual reps not recorded'
                          : '${p.reps[exercises[p.currentExercise].id]![i]} actual reps',
                    ),
                    value: p.done[exercises[p.currentExercise].id]![i],
                    onChanged: busy
                        ? null
                        : (value) => save(
                            p.change(
                              exercises,
                              exerciseId: exercises[p.currentExercise].id,
                              setIndex: i,
                              checked: value,
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => editReps(exercises[p.currentExercise], i),
                    child: Text('Log reps for set ${i + 1}'),
                  ),
                ],
                if (p.restUntil != null)
                  Text('Rest remaining: ${p.remainingRest(DateTime.now())}s'),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => save(
                              p.change(
                                exercises,
                                restUntil: DateTime.now().toUtc().add(
                                  Duration(
                                    seconds: exercises[p.currentExercise]
                                        .restSeconds,
                                  ),
                                ),
                              ),
                            ),
                      child: const Text('Start rest'),
                    ),
                    if (p.restUntil != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => save(p.change(exercises, clearRest: true)),
                        child: const Text('Stop rest'),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy || p.currentExercise == 0
                            ? null
                            : () => save(
                                p.change(
                                  exercises,
                                  current: p.currentExercise - 1,
                                ),
                              ),
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            busy || p.currentExercise == exercises.length - 1
                            ? null
                            : () => save(
                                p.change(
                                  exercises,
                                  current: p.currentExercise + 1,
                                ),
                              ),
                        child: const Text('Next exercise'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: notes,
                  onChanged: (_) => setState(
                    () => notesDirty = notes.text != (session?.notes ?? ''),
                  ),
                  maxLength: 2000,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Session notes (saved when you finish)',
                  ),
                ),
                FilledButton(
                  onPressed: busy || p.completedSets != p.totalSets
                      ? null
                      : () => finish(false),
                  child: const Text('Finish session'),
                ),
                TextButton(
                  onPressed: busy ? null : () => finish(true),
                  child: const Text('End early and save'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class GuidedWorkoutScreen extends StatelessWidget {
  final int sessionId;
const GuidedWorkoutScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) => PersonalizationBoundary(child: _GuidedWorkoutScreenContent(sessionId: sessionId));
}
