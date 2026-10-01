import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../state/providers.dart';
import '../services/notification_service.dart';
import '../widgets/workout_day_scheduler.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  late String _sex;
  late String _goal;
  late String _level;
  late String _equipment;
  late int _trainingDays;
  
  // NEW: Scheduled workout days
  late List<int> _scheduledDays;

  // Cycle tracking
  late bool _trackCycle;
  DateTime? _lastPeriodDate;
  late int _cycleLength;

  // Post-partum
  late String _postPartumStatus;
  DateTime? _deliveryDate;
  late bool _medicalClearance;
  late bool _checkDiastasis;
  late String _deliveryType;

  bool _saving = false;
  bool _initialized = false;

  UserProfile? _originalProfile;

  @override
  void initState() {
    super.initState();
    _ageCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _initializeFromProfile(UserProfile profile) {
    if (_initialized) return;

    _originalProfile = profile;

    _ageCtrl.text = profile.age.toString();
    _heightCtrl.text = profile.heightCm.toString();
    _weightCtrl.text = profile.weightKg.toString();

    _sex = profile.sex;
    _goal = profile.goal;
    _level = profile.level;
    _equipment = profile.equipment;
    _trainingDays = profile.trainingDaysPerWeek;
    _scheduledDays = List<int>.from(profile.scheduledDaysList); // NEW

    _trackCycle = profile.trackCycle;
    _lastPeriodDate = profile.lastPeriodDate;
    _cycleLength = profile.cycleLength;

    _postPartumStatus = profile.postPartumStatus;
    _deliveryDate = profile.deliveryDate;
    _medicalClearance = profile.medicalClearance;
    _checkDiastasis = profile.checkDiastasis;
    _deliveryType = profile.deliveryType;

    setState(() => _initialized = true);
  }

  List<String> _getChangedFields() {
    if (_originalProfile == null) return [];

    final changed = <String>[];

    if (int.parse(_ageCtrl.text) != _originalProfile!.age) changed.add('age');
    if (int.parse(_heightCtrl.text) != _originalProfile!.heightCm) {
      changed.add('height');
    }
    if (double.parse(_weightCtrl.text) != _originalProfile!.weightKg) {
      changed.add('weight');
    }
    if (_sex != _originalProfile!.sex) changed.add('sex');
    if (_goal != _originalProfile!.goal) changed.add('goal');
    if (_level != _originalProfile!.level) changed.add('level');
    if (_equipment != _originalProfile!.equipment) changed.add('equipment');
    if (_trainingDays != _originalProfile!.trainingDaysPerWeek) {
      changed.add('training_days');
    }
    // NEW: Check if schedule changed
    if (_scheduledDays.toString() != _originalProfile!.scheduledDaysList.toString()) {
      changed.add('workout_schedule');
    }
    if (_trackCycle != _originalProfile!.trackCycle) {
      changed.add('cycle_tracking');
    }
    if (_postPartumStatus != _originalProfile!.postPartumStatus) {
      changed.add('postpartum_status');
    }

    return changed;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // NEW: Validate scheduled workout days
    if (_scheduledDays.length != _trainingDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select $_trainingDays training days'),
        ),
      );
      return;
    }

    // Validate cycle tracking
    if (_trackCycle && _lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your last period start date'),
        ),
      );
      return;
    }

    // Validate post-partum
    if (_postPartumStatus != 'no') {
      if (_deliveryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your delivery date'),
          ),
        );
        return;
      }

      if (!_medicalClearance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Medical clearance is required for post-partum exercise'),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final changedFields = _getChangedFields();
      final repo = ref.read(userProfileRepoProvider);
      final current = await repo.getProfile();
      if (current == null) throw StateError('Profile no longer exists');
      final profile = current
        ..age = int.parse(_ageCtrl.text.trim())
        ..sex = _sex
        ..heightCm = int.parse(_heightCtrl.text.trim())
        ..weightKg = double.parse(_weightCtrl.text.trim())
        ..goal = _goal
        ..level = _level
        ..equipment = _equipment
        ..trainingDaysPerWeek = _trainingDays
        ..scheduledDaysList = _scheduledDays // NEW: Save scheduled days
        ..updatedAt = DateTime.now()
        // Cycle tracking
        ..trackCycle = _trackCycle
        ..lastPeriodDate = _lastPeriodDate
        ..cycleLength = _cycleLength
        // Post-partum
        ..postPartumStatus = _postPartumStatus
        ..deliveryDate = _deliveryDate
        ..medicalClearance = _medicalClearance
        ..checkDiastasis = _checkDiastasis
        ..deliveryType = _deliveryType;

      await repo.saveProfile(profile);
      ref.invalidate(userProfileProvider);
      await NotificationService().setupNotifications(profile);

      // Track analytics
      final analytics = ref.read(analyticsProvider);
      await analytics.logProfileUpdated(
        fieldsChanged: changedFields,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully! ✅')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: Text(
              _saving ? 'Saving...' : 'Save',
              style: TextStyle(
                color: _saving ? theme.disabledColor : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          _initializeFromProfile(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Basic Information
                Text(
                  'Basic Information',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    hintText: 'e.g. 30',
                  ),
                  validator: (v) {
                    final age = int.tryParse(v ?? '');
                    if (age == null) return 'Enter a valid age';
                    if (age < 15 || age > 100) return 'Age must be 15-100';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (v) => setState(() => _sex = v ?? 'male'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'e.g. 170',
                  ),
                  validator: (v) {
                    final height = int.tryParse(v ?? '');
                    if (height == null) return 'Enter a valid height';
                    if (height < 120 || height > 250) {
                      return 'Height must be 120-250 cm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 70',
                  ),
                  validator: (v) {
                    final weight = double.tryParse(v ?? '');
                    if (weight == null) return 'Enter a valid weight';
                    if (weight < 30 || weight > 300) {
                      return 'Weight must be 30-300 kg';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Fitness Goals
                Text(
                  'Fitness Goals',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _goal,
                  decoration: const InputDecoration(labelText: 'Primary Goal'),
                  items: const [
                    DropdownMenuItem(value: 'cut', child: Text('Fat Loss (Cut)')),
                    DropdownMenuItem(
                      value: 'recomp',
                      child: Text('Body Recomposition'),
                    ),
                    DropdownMenuItem(
                      value: 'bulk',
                      child: Text('Muscle Gain (Bulk)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _goal = v ?? 'cut'),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _level,
                  decoration:
                      const InputDecoration(labelText: 'Training Experience'),
                  items: const [
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text('Beginner (0-1 years)'),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermediate (1-3 years)'),
                    ),
                    DropdownMenuItem(
                      value: 'advanced',
                      child: Text('Advanced (3+ years)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _level = v ?? 'beginner'),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _equipment,
                  decoration:
                      const InputDecoration(labelText: 'Equipment Access'),
                  items: const [
                    DropdownMenuItem(value: 'gym', child: Text('Full Gym')),
                    DropdownMenuItem(
                      value: 'home_dumbbells',
                      child: Text('Home (Dumbbells)'),
                    ),
                    DropdownMenuItem(
                      value: 'calisthenics',
                      child: Text('Bodyweight Only'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _equipment = v ?? 'gym'),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: _trainingDays,
                  decoration: const InputDecoration(
                    labelText: 'Training Days per Week',
                  ),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 days')),
                    DropdownMenuItem(value: 4, child: Text('4 days')),
                    DropdownMenuItem(value: 5, child: Text('5 days')),
                    DropdownMenuItem(value: 6, child: Text('6 days')),
                  ],
                  onChanged: (v) => setState(() {
                    _trainingDays = v ?? 4;
                    _scheduledDays = []; // Reset schedule when days change
                  }),
                ),

                // NEW: Workout Day Scheduler
                const SizedBox(height: 24),
                
                if (_trainingDays > 0) ...[
                  WorkoutDayScheduler(
                    selectedDays: _scheduledDays,
                    maxDays: _trainingDays,
                    onChanged: (days) => setState(() => _scheduledDays = days),
                  ),
                ],

                // Women's Health Section
                if (_sex == 'female') ...[
                  const SizedBox(height: 32),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.favorite, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Women\'s Health',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Cycle Tracking
                  Text(
                    'Cycle Tracking',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    value: _trackCycle,
                    onChanged: (v) => setState(() => _trackCycle = v),
                    title: const Text('Track my cycle for better training'),
                    subtitle: const Text('Optional but recommended'),
                  ),

                  if (_trackCycle) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Last period start date'),
                      subtitle: Text(
                        _lastPeriodDate == null
                            ? 'Tap to select'
                            : '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _lastPeriodDate ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 60)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _lastPeriodDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _cycleLength,
                      decoration: const InputDecoration(
                        labelText: 'Average cycle length (days)',
                      ),
                      items: List.generate(15, (i) => i + 21).map((days) {
                        return DropdownMenuItem(
                          value: days,
                          child: Text('$days days'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _cycleLength = v ?? 28),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Post-Partum
                  Text(
                    'Post-Partum Status',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _postPartumStatus,
                    decoration: const InputDecoration(
                      labelText: 'Are you post-partum?',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'no', child: Text('No')),
                      DropdownMenuItem(
                        value: 'early',
                        child: Text('Yes (0-12 weeks)'),
                      ),
                      DropdownMenuItem(
                        value: 'mid',
                        child: Text('Yes (3-6 months)'),
                      ),
                      DropdownMenuItem(
                        value: 'late',
                        child: Text('Yes (6-18 months)'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _postPartumStatus = v ?? 'no'),
                  ),

                  if (_postPartumStatus != 'no') ...[
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Delivery date'),
                      subtitle: Text(
                        _deliveryDate == null
                            ? 'Tap to select'
                            : '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 545),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _deliveryDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _deliveryType,
                      decoration: const InputDecoration(
                        labelText: 'Delivery type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'unknown',
                          child: Text('Prefer not to say'),
                        ),
                        DropdownMenuItem(
                          value: 'vaginal',
                          child: Text('Vaginal birth'),
                        ),
                        DropdownMenuItem(
                          value: 'cesarean',
                          child: Text('C-section'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _deliveryType = v ?? 'unknown'),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _medicalClearance,
                      onChanged: (v) =>
                          setState(() => _medicalClearance = v ?? false),
                      title: const Text('I have medical clearance to exercise'),
                      subtitle: const Text('Required to proceed'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_postPartumStatus == 'early' ||
                        _postPartumStatus == 'mid') ...[
                      CheckboxListTile(
                        value: _checkDiastasis,
                        onChanged: (v) =>
                            setState(() => _checkDiastasis = v ?? false),
                        title: const Text('Check for diastasis recti guidance'),
                        subtitle: const Text('We\'ll provide core-safe exercises'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ],
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}