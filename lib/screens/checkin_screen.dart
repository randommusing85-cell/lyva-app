import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/checkin.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int? _selectedMood;
  int? _selectedEnergy;

  bool _saving = false;

  // Mood options with emojis
  static const _moodOptions = [
    (1, '😢', 'Rough'),
    (2, '😕', 'Meh'),
    (3, '😐', 'Okay'),
    (4, '🙂', 'Good'),
    (5, '😊', 'Great'),
  ];

  // Energy options with emojis
  static const _energyOptions = [
    (1, '😴', 'Exhausted'),
    (2, '🥱', 'Tired'),
    (3, '😐', 'Normal'),
    (4, '⚡', 'Energized'),
    (5, '🔥', 'Pumped'),
  ];

  @override
  void initState() {
    super.initState();
    _autoFillSteps();
  }

  Future<void> _autoFillSteps() async {
    try {
      final service = ref.read(stepTrackingServiceProvider);
      final authorized = await service.isAuthorized();
      if (!authorized) return;
      final steps = await service.getTodaySteps();
      if (mounted && _stepsCtrl.text.isEmpty && steps > 0) {
        _stepsCtrl.text = steps.toString();
      }
    } catch (_) {
      // Silently fail — user can still enter manually
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _stepsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  num? _tryNum(String s) => num.tryParse(s.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final c = CheckIn()
        ..ts = DateTime.now()
        ..weightKg = (_tryNum(_weightCtrl.text) ?? 0).toDouble()
        ..waistCm = (_tryNum(_waistCtrl.text) ?? 0).toDouble()
        ..stepsToday = int.parse(_stepsCtrl.text.trim())
        ..note = _buildNote()
        ..moodScore = _selectedMood
        ..energyScore = _selectedEnergy;

      final repo = ref.read(lyvaRepoProvider);
      await repo.addCheckIn(c);

      // Track analytics
      final analytics = ref.read(analyticsProvider);
      await analytics.logCheckInCompleted(
        weightKg: c.weightKg,
        waistCm: c.waistCm,
        stepsToday: c.stepsToday,
        hasNote: c.note != null,
      );

      // refresh stream consumers
      ref.invalidate(latestCheckInsStreamProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in saved!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _buildNote() {
    final parts = <String>[];

    if (_selectedMood != null) {
      final moodLabel = _moodOptions.firstWhere((m) => m.$1 == _selectedMood).$3;
      parts.add('Mood: $moodLabel');
    }

    if (_selectedEnergy != null) {
      final energyLabel = _energyOptions.firstWhere((e) => e.$1 == _selectedEnergy).$3;
      parts.add('Energy: $energyLabel');
    }

    if (_noteCtrl.text.trim().isNotEmpty) {
      parts.add(_noteCtrl.text.trim());
    }

    return parts.isEmpty ? null : parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daily Check-in',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Date card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'How are you feeling today?',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mood section
                const Text(
                  'Mood',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _MoodSelector(
                  options: _moodOptions,
                  selectedValue: _selectedMood,
                  onSelected: (v) => setState(() => _selectedMood = v),
                ),

                const SizedBox(height: 24),

                // Energy section
                const Text(
                  'Energy Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _MoodSelector(
                  options: _energyOptions,
                  selectedValue: _selectedEnergy,
                  onSelected: (v) => setState(() => _selectedEnergy = v),
                ),

                const SizedBox(height: 24),

                // Measurements section
                const Text(
                  'Measurements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Side-by-side weight and waist inputs
                Row(
                  children: [
                    Expanded(
                      child: _InputCard(
                        controller: _weightCtrl,
                        label: 'Weight',
                        unit: 'kg',
                        icon: Icons.monitor_weight_outlined,
                        hint: '75.2',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = _tryNum(v ?? '');
                          if (n == null) return 'Required';
                          if (n < 30 || n > 250) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputCard(
                        controller: _waistCtrl,
                        label: 'Waist',
                        unit: 'cm',
                        icon: Icons.straighten,
                        hint: '80',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = _tryNum(v ?? '');
                          if (n == null) return 'Required';
                          if (n < 40 || n > 200) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Steps input
                _InputCard(
                  controller: _stepsCtrl,
                  label: 'Steps Today',
                  unit: 'steps',
                  icon: Icons.directions_walk,
                  hint: '8000',
                  keyboardType: TextInputType.number,
                  fullWidth: true,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null) return 'Enter a number';
                    if (n < 0 || n > 100000) return 'Invalid step count';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Notes section
                const Text(
                  'Notes (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'How was your sleep? Any hunger cravings? Training notes...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Check-in',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mood/Energy selector with emoji options
class _MoodSelector extends StatelessWidget {
  final List<(int, String, String)> options;
  final int? selectedValue;
  final ValueChanged<int> onSelected;

  const _MoodSelector({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((option) {
        final (value, emoji, label) = option;
        final isSelected = selectedValue == value;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textMuted.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Input card for measurements
class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;
  final bool fullWidth;
  final String? Function(String?)? validator;

  const _InputCard({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.hint,
    required this.keyboardType,
    this.fullWidth = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    errorStyle: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
