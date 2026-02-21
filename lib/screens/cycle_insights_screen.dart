import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/cycle_log.dart';
import '../models/cycle_prediction.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/cycle_phase_card.dart';

class CycleInsightsScreen extends ConsumerStatefulWidget {
  const CycleInsightsScreen({super.key});

  @override
  ConsumerState<CycleInsightsScreen> createState() => _CycleInsightsScreenState();
}

class _CycleInsightsScreenState extends ConsumerState<CycleInsightsScreen> {
  bool _predicting = false;
  String? _selectedSymptom;
  int _severity = 3;

  static const _symptoms = [
    ('cramps', 'Cramps'),
    ('bloating', 'Bloating'),
    ('headache', 'Headache'),
    ('mood_change', 'Mood'),
    ('fatigue', 'Fatigue'),
    ('breast_tenderness', 'Tenderness'),
  ];

  Future<void> _generatePrediction() async {
    setState(() => _predicting = true);

    try {
      final repo = ref.read(primeRepoProvider);
      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) return;

      // Gather data
      final cycleLogs = await repo.getCycleLogs(limit: 90);
      final checkIns = await repo.latestCheckIns(limit: 30);
      final sessions = await repo.getThisWeekSessions();

      final cycleHistory = cycleLogs
          .where((l) => l.eventType == 'period_start')
          .map((l) => {'periodStart': l.ts.toIso8601String()})
          .toList();

      final checkInData = checkIns
          .map((c) => {
                'date': c.ts.toIso8601String(),
                'moodScore': c.moodScore,
                'energyScore': c.energyScore,
                'weightKg': c.weightKg,
              })
          .toList();

      final workoutData = sessions
          .map((s) => {
                'date': s.date.toIso8601String(),
                'completed': s.completed,
                'dayIndex': s.dayIndex,
              })
          .toList();

      final result = await repo.predictCycle(
        cycleHistory: cycleHistory,
        checkInData: checkInData,
        workoutData: workoutData,
        profileData: {
          'age': profile.age,
          'avgCycleLength': profile.cycleLength,
          'periodDuration': profile.periodDuration,
        },
      );

      // Save prediction
      final pred = result['prediction'] as Map<String, dynamic>;
      final prediction = CyclePrediction()
        ..ts = DateTime.now()
        ..predictedPeriodDate = DateTime.parse(pred['predictedPeriodDate'])
        ..predictedOvulation = DateTime.parse(pred['predictedOvulation'])
        ..fertileWindowStart = DateTime.parse(pred['fertileWindowStart'])
        ..fertileWindowEnd = DateTime.parse(pred['fertileWindowEnd'])
        ..predictedCycleLength = pred['predictedCycleLength'] as int
        ..confidence = (pred['confidence'] as num).toDouble()
        ..factorsJson = pred['factors'] != null ? pred['factors'].toString() : null;

      await repo.saveCyclePrediction(prediction);
      ref.invalidate(latestCyclePredictionProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prediction failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  Future<void> _logSymptom() async {
    if (_selectedSymptom == null) return;

    final repo = ref.read(primeRepoProvider);
    final log = CycleLog()
      ..ts = DateTime.now()
      ..eventType = 'symptom'
      ..symptomType = _selectedSymptom
      ..severity = _severity;

    await repo.saveCycleLog(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom logged'), duration: Duration(seconds: 1)),
      );
      setState(() => _selectedSymptom = null);
    }
  }

  Future<void> _logPeriodStart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Period Start'),
        content: const Text('Confirm that your period started today?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(primeRepoProvider).confirmPeriodStarted(DateTime.now());
      ref.invalidate(userProfileProvider);
      ref.invalidate(currentCyclePhaseProvider);
      ref.invalidate(latestCyclePredictionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period start logged')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionAsync = ref.watch(latestCyclePredictionProvider);
    final dateFormat = DateFormat('MMM d');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cycle Insights'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current phase card
            const CyclePhaseCard(),
            const SizedBox(height: 16),

            // Prediction card
            predictionAsync.when(
              data: (prediction) {
                if (prediction == null) {
                  return _buildGeneratePredictionCard();
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_graph, size: 20, color: AppColors.seasonAccent),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Prediction',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(prediction.confidence * 100).round()}% confident',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PredictionRow(
                        label: 'Next period',
                        value: dateFormat.format(prediction.predictedPeriodDate),
                        icon: Icons.water_drop,
                        color: const Color(0xFFE57373),
                      ),
                      const SizedBox(height: 10),
                      _PredictionRow(
                        label: 'Ovulation',
                        value: dateFormat.format(prediction.predictedOvulation),
                        icon: Icons.egg_outlined,
                        color: const Color(0xFFE5B94D),
                      ),
                      const SizedBox(height: 10),
                      _PredictionRow(
                        label: 'Fertile window',
                        value: '${dateFormat.format(prediction.fertileWindowStart)} - ${dateFormat.format(prediction.fertileWindowEnd)}',
                        icon: Icons.favorite_border,
                        color: const Color(0xFF8BA888),
                      ),
                      const SizedBox(height: 10),
                      _PredictionRow(
                        label: 'Predicted cycle length',
                        value: '${prediction.predictedCycleLength} days',
                        icon: Icons.calendar_today,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _predicting ? null : _generatePrediction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: Text(_predicting ? 'Refreshing...' : 'Refresh Prediction'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildGeneratePredictionCard(),
            ),
            const SizedBox(height: 20),

            // Log period start
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logPeriodStart,
                icon: const Icon(Icons.water_drop),
                label: const Text('Log Period Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE57373),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Symptom logger
            const Text(
              'Log Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptoms.map((s) {
                final isSelected = _selectedSymptom == s.$1;
                return ChoiceChip(
                  label: Text(s.$2),
                  selected: isSelected,
                  selectedColor: AppColors.seasonAccent.withOpacity(0.2),
                  onSelected: (selected) {
                    setState(() => _selectedSymptom = selected ? s.$1 : null);
                  },
                );
              }).toList(),
            ),

            if (_selectedSymptom != null) ...[
              const SizedBox(height: 16),
              const Text('Severity', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Slider(
                value: _severity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _severity.toString(),
                activeColor: AppColors.seasonAccent,
                onChanged: (v) => setState(() => _severity = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Mild', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('Severe', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logSymptom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log Symptom'),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratePredictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.seasonAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_graph, size: 40, color: AppColors.seasonAccent),
          const SizedBox(height: 12),
          const Text(
            'AI Cycle Predictions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get AI-powered predictions based on your cycle history, mood, energy, and workout patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _predicting ? null : _generatePrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.seasonAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _predicting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Generate Prediction', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PredictionRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
