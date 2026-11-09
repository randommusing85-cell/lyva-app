import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cycle_calendar_data.dart';
import '../models/cycle_log.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../state/providers.dart';
import '../widgets/cycle_calendar.dart';
import '../widgets/premium_gate.dart';

class CycleInsightsScreen extends ConsumerStatefulWidget {
  const CycleInsightsScreen({super.key});
  @override
  ConsumerState<CycleInsightsScreen> createState() =>
      _CycleInsightsScreenState();
}

class _CycleInsightsScreenState extends ConsumerState<CycleInsightsScreen>
    with WidgetsBindingObserver {
  Timer? _midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _scheduleDateRefresh() {
    _midnight?.cancel();
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) {
          setState(() {});
          _scheduleDateRefresh();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleDateRefresh();
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _saving = false, _showEstimate = false;
  String? _symptom;
  int _severity = 3;
  Future<void> editDetails(CycleLog original) async {
    if (_saving ||
        ref.read(userProfileProvider).valueOrNull?.trackCycle != true) {
      return;
    }
    var notes = original.notes ?? '';
    var severity = original.severity;
    if (severity != null && (severity < 1 || severity > 5)) {
      severity = null;
    }
    var pending = false;
    String? error;
    setState(() => _saving = true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => PopScope(
            canPop: !pending,
            child: AlertDialog(
              title: const Text('Edit recorded details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'The recorded date and event type stay unchanged.',
                    ),
                    TextFormField(
                      initialValue: notes,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Optional notes',
                      ),
                      enabled: !pending,
                      onChanged: (value) => notes = value,
                    ),
                    if (original.eventType == 'symptom')
                      DropdownButtonFormField<int>(
                        initialValue: severity ?? 0,
                        decoration: const InputDecoration(
                          labelText: 'Reported severity',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Not logged'),
                          ),
                          for (var i = 1; i <= 5; i++)
                            DropdownMenuItem(value: i, child: Text('$i / 5')),
                        ],
                        onChanged: pending
                            ? null
                            : (value) => severity = value == 0 ? null : value,
                      ),
                    if (error != null) Text(error!),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: pending ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: pending
                      ? null
                      : () async {
                          update(() {
                            pending = true;
                            error = null;
                          });
                          try {
                            if (ref
                                    .read(userProfileProvider)
                                    .valueOrNull
                                    ?.trackCycle !=
                                true) {
                              throw StateError('Tracking unavailable');
                            }
                            final saved = await ref
                                .read(lyvaRepoProvider)
                                .updateCycleLogDetails(
                                  original,
                                  notes: notes.isEmpty ? null : notes,
                                  severity: severity,
                                );
                            if (!ctx.mounted) return;
                            if (!saved) {
                              update(() {
                                pending = false;
                                error =
                                    'This record changed or was removed. Cancel and reopen the latest record.';
                              });
                              return;
                            }
                            ref.invalidate(cycleLogsProvider);
                            Navigator.pop(ctx);
                          } catch (_) {
                            if (ctx.mounted) {
                              update(() {
                                pending = false;
                                error =
                                    'Could not save. Your edits are still here.';
                              });
                            }
                          }
                        },
                  child: Text(pending ? 'Saving...' : 'Save details'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const symptoms = [
    'cramps',
    'bloating',
    'headache',
    'mood_change',
    'fatigue',
    'breast_tenderness',
  ];
  Future<void> save({required bool period}) async {
    if (_saving ||
        ref.read(userProfileProvider).valueOrNull?.trackCycle != true) {
      return;
    }
    if (!period && _symptom == null) return;
    if (period) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Log period start today?'),
          content: const Text(
            'This records today as a period start. It does not confirm ovulation or other bleeding days.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log start'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (ref.read(userProfileProvider).valueOrNull?.trackCycle != true) return;
    setState(() => _saving = true);
    var saved = false;
    try {
      final repo = ref.read(lyvaRepoProvider);
      if (period) {
        await repo.confirmPeriodStarted(DateTime.now());
      } else {
        await repo.saveTrackedCycleLog(
          CycleLog()
            ..ts = DateTime.now()
            ..eventType = 'symptom'
            ..symptomType = _symptom
            ..severity = _severity,
        );
      }
      saved = true;
      ref.invalidate(cycleLogsProvider);
      if (period) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(currentCyclePhaseProvider);
        ref.invalidate(latestCyclePredictionProvider);
        final profile = await ref.read(userProfileRepoProvider).getProfile();
        if (profile != null) {
          await NotificationService().setupNotifications(profile);
        }
      }
      if (mounted) {
        setState(() => _symptom = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recorded for today')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Record saved, but reminders could not refresh. Do not log it again.'
                  : 'Could not save. Your selection is still here; please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    if (profile.valueOrNull?.trackCycle != true) {
      _showEstimate = false;
      _midnight?.cancel();
      _midnight = null;
      return Scaffold(
        appBar: AppBar(title: const Text('Cycle tracker')),
        body: Center(
          child: Text(
            profile.isLoading
                ? 'Loading preferences...'
                : 'Cycle tracking is off or unavailable. Manage it in your profile.',
          ),
        ),
      );
    }
    if (_midnight == null) {
      _scheduleDateRefresh();
    }
    final p = profile.valueOrNull!;
    final logs = ref.watch(cycleLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle tracker')),
      body: PremiumGate(
        feature: PremiumFeature.cyclePredictions,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your recorded experience',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Browse bleeding events and symptoms. Not logged is different from none. Calendar estimates cannot confirm ovulation and must not be used as contraception.',
              ),
              const SizedBox(height: 12),
              logs.when(
                data: (records) {
                  final data = CycleCalendarData(
                    profile: p,
                    logs: records,
                    today: DateTime.now(),
                    showEstimate: _showEstimate && p.postPartumStatus == 'no',
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CycleCalendar(
                        data: data,
                        onEdit: _saving ? null : editDetails,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Show a calendar-only period estimate',
                        ),
                        subtitle: const Text(
                          'Off by default. Use recorded-only tracking with hormonal contraception or when natural-cycle estimates do not apply. No phase or fertility estimates are made.',
                        ),
                        value: _showEstimate && p.postPartumStatus == 'no',
                        onChanged: p.postPartumStatus == 'no'
                            ? (value) => setState(() => _showEstimate = value)
                            : null,
                      ),
                      Text(data.estimateExplanation),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Column(
                  children: [
                    const Text(
                      'Cycle records could not load. No missing days have been assumed.',
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(cycleLogsProvider),
                      child: const Text('Retry records'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Log today',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Logging is optional. These controls record today, regardless of the date you are viewing above.',
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => save(period: true),
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Log period start today'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final symptom in symptoms)
                    ChoiceChip(
                      label: Text(symptom.replaceAll('_', ' ')),
                      selected: _symptom == symptom,
                      onSelected: _saving
                          ? null
                          : (selected) => setState(
                              () => _symptom = selected ? symptom : null,
                            ),
                    ),
                ],
              ),
              if (_symptom != null) ...[
                Text('Reported severity: $_severity / 5'),
                Slider(
                  value: _severity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_severity of 5',
                  semanticFormatterCallback: (value) =>
                      'Severity ${value.round()} of 5',
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _severity = value.round()),
                ),
                FilledButton(
                  onPressed: _saving ? null : () => save(period: false),
                  child: const Text('Log symptom today'),
                ),
              ],
              if (_saving) const Text('Saving...'),
            ],
          ),
        ),
      ),
    );
  }
}
