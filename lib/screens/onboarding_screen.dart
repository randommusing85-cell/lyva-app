import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../widgets/workout_day_scheduler.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');

  String _sex = 'male';
  String _goal = 'cut';
  String _level = 'beginner';
  String _equipment = 'gym';
  int _trainingDays = 4;
  
  // NEW: Scheduled workout days
  List<int> _scheduledDays = [];

  // Cycle Tracking Variables
  bool _trackCycle = false;
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;

  // Post-Partum Variables
  String _postPartumStatus = 'no';
  DateTime? _deliveryDate;
  bool _medicalClearance = false;
  bool _checkDiastasis = false;
  String _deliveryType = 'unknown';

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Track onboarding started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsProvider);
      analytics.logOnboardingStarted();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
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

    // Validate cycle tracking data if enabled
    if (_trackCycle && _lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your last period start date'),
        ),
      );
      return;
    }

    // Validate post-partum data if applicable
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
            content: Text('Medical clearance is required for post-partum exercise'),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final profile = UserProfile()
        ..name = _nameCtrl.text.trim()
        ..lastLoginAt = DateTime.now()
        ..age = int.parse(_ageCtrl.text.trim())
        ..sex = _sex
        ..heightCm = int.parse(_heightCtrl.text.trim())
        ..weightKg = double.parse(_weightCtrl.text.trim())
        ..goal = _goal
        ..level = _level
        ..equipment = _equipment
        ..trainingDaysPerWeek = _trainingDays
        ..scheduledDaysList = _scheduledDays // NEW: Save scheduled days
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        // Cycle Tracking Fields
        ..trackCycle = _trackCycle
        ..lastPeriodDate = _lastPeriodDate
        ..cycleLength = _cycleLength
        ..periodDuration = 5
        // Post-Partum Fields
        ..postPartumStatus = _postPartumStatus
        ..deliveryDate = _deliveryDate
        ..medicalClearance = _medicalClearance
        ..checkDiastasis = _checkDiastasis
        ..deliveryType = _deliveryType;

      final repo = ref.read(userProfileRepoProvider);
      await repo.saveProfile(profile);

      // Track onboarding completion and demographics
      final analytics = ref.read(analyticsProvider);
      await analytics.logOnboardingCompleted(
        age: profile.age,
        sex: profile.sex,
        goal: profile.goal,
        tracksCycle: profile.trackCycle,
        isPostPartum: profile.postPartumStatus != 'no',
      );

      await analytics.setUserDemographics(
        age: profile.age,
        sex: profile.sex,
        goal: profile.goal,
        level: profile.level,
        equipment: profile.equipment,
        trainingDaysPerWeek: profile.trainingDaysPerWeek,
        tracksCycle: profile.trackCycle,
        postPartumStatus: profile.postPartumStatus,
      );

      // Refresh the profile provider
      ref.invalidate(userProfileProvider);

      if (!mounted) return;

      // Navigate to home screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/setup-guide',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to PrimeForm'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Philosophy Introduction
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Our Philosophy',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PrimeForm is built on one principle: consistency over perfection.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We understand women\'s bodies - cycles, post-partum recovery, and real-life challenges. We\'ll guide you safely and smartly.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Let\'s set up your profile',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us create a personalized plan for you.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Basic Info Section
              Text('Basic Information', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g. Sarah',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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

              const SizedBox(height: 24),

              // Fitness Goals Section
              Text('Fitness Goals', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(
                  labelText: 'Primary Goal',
                  helperText: 'What do you want to achieve?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cut',
                    child: Text('Fat Loss (Cut)'),
                  ),
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
                decoration: const InputDecoration(
                  labelText: 'Training Experience',
                  helperText: 'How familiar are you with working out?',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Equipment Access',
                  helperText: 'What equipment do you have?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'gym',
                    child: Text('Full Gym'),
                  ),
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
                  helperText: 'How many days can you train?',
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 days')),
                  DropdownMenuItem(value: 4, child: Text('4 days')),
                  DropdownMenuItem(value: 5, child: Text('5 days')),
                  DropdownMenuItem(value: 6, child: Text('6 days')),
                ],
                onChanged: (v) => setState(() {
                  _trainingDays = v ?? 4;
                  _scheduledDays = []; // Reset scheduled days when count changes
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

              // ===== WOMEN'S HEALTH SECTION (Female Only) =====
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Help us understand your body for smarter, safer training',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                // ===== POST-PARTUM STATUS =====
                const SizedBox(height: 24),

                Text('Post-Partum Status', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _postPartumStatus,
                  decoration: const InputDecoration(
                    labelText: 'Are you post-partum?',
                    helperText: 'Helps us provide safe guidance',
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
                  onChanged: (v) => setState(() => _postPartumStatus = v ?? 'no'),
                ),

                if (_postPartumStatus != 'no') ...[
                  const SizedBox(height: 12),

                  // Medical clearance warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Important: Only start exercising after getting medical clearance from your doctor (usually 6+ weeks post-delivery, 8+ for C-section).',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 545)), // 18 months
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
                      helperText: 'Affects recovery timeline',
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
                    onChanged: (v) => setState(() => _deliveryType = v ?? 'unknown'),
                  ),

                  const SizedBox(height: 12),

                  CheckboxListTile(
                    value: _medicalClearance,
                    onChanged: (v) => setState(() => _medicalClearance = v ?? false),
                    title: const Text('I have medical clearance to exercise'),
                    subtitle: const Text('Required to proceed'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  if (_postPartumStatus == 'early' ||
                      _postPartumStatus == 'mid') ...[
                    CheckboxListTile(
                      value: _checkDiastasis,
                      onChanged: (v) => setState(() => _checkDiastasis = v ?? false),
                      title: const Text('Check for diastasis recti guidance'),
                      subtitle: const Text('We\'ll provide core-safe exercises'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],

                // ===== CYCLE TRACKING =====
                const SizedBox(height: 24),

                Text('Cycle-Aware Training', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                // Info card explaining benefit
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your menstrual cycle affects energy and recovery. Track it for smarter training adjustments.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Toggle switch
                SwitchListTile(
                  value: _trackCycle,
                  onChanged: (v) => setState(() => _trackCycle = v),
                  title: const Text('Track my cycle for better training'),
                  subtitle: const Text('Optional but recommended'),
                ),

                // Show date picker if tracking enabled
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
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 60)),
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
                      helperText: 'Typical range: 21-35 days',
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
              ],

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _saving ? null : _saveProfile,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _saving ? 'Setting up...' : 'Get Started',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}