import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../services/export_service.dart';
import '../services/analytics_service.dart';
import '../state/providers.dart';
import '../widgets/premium_gate.dart';
import '../services/premium_service.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  // Data selection
  bool _includeCheckIns = true;
  bool _includeMeals = true;
  bool _includeWorkouts = true;

  // Date range
  int _selectedDays = 30; // 7, 30, 90, or 0 for all time

  // Format
  String _selectedFormat = 'csv'; // 'csv' or 'pdf'

  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: PremiumGate(
        feature: PremiumFeature.exportData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.download_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Your Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Download your data as CSV or PDF report',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data Selection
              _buildSectionTitle('Include Data'),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                    _buildCheckboxTile(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Check-ins',
                      subtitle: 'Weight, waist, mood, energy, steps',
                      value: _includeCheckIns,
                      onChanged: (v) =>
                          setState(() => _includeCheckIns = v ?? true),
                    ),
                    const Divider(height: 1),
                    _buildCheckboxTile(
                      icon: Icons.restaurant_outlined,
                      title: 'Meals',
                      subtitle: 'Nutrition logs with macros & calories',
                      value: _includeMeals,
                      onChanged: (v) =>
                          setState(() => _includeMeals = v ?? true),
                    ),
                    const Divider(height: 1),
                    _buildCheckboxTile(
                      icon: Icons.fitness_center_outlined,
                      title: 'Workouts',
                      subtitle: 'Session history & completion status',
                      value: _includeWorkouts,
                      onChanged: (v) =>
                          setState(() => _includeWorkouts = v ?? true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Date Range
              _buildSectionTitle('Date Range'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDateChip(7, 'Last 7 Days'),
                  _buildDateChip(30, 'Last 30 Days'),
                  _buildDateChip(90, 'Last 90 Days'),
                  _buildDateChip(0, 'All Time'),
                ],
              ),

              const SizedBox(height: 24),

              // Format
              _buildSectionTitle('Export Format'),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                    _buildRadioTile(
                      icon: Icons.table_chart_outlined,
                      title: 'CSV Spreadsheet',
                      subtitle: 'Raw data for Excel or Google Sheets',
                      value: 'csv',
                    ),
                    const Divider(height: 1),
                    _buildRadioTile(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'PDF Report',
                      subtitle: 'Formatted report with summary & tables',
                      value: 'pdf',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Export Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canExport ? _handleExport : null,
                  icon: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_outlined),
                  label: Text(
                    _exporting ? 'Generating...' : 'Export & Share',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              if (!_canExport && !_exporting) ...[
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Select at least one data type to export',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canExport =>
      !_exporting &&
      (_includeCheckIns || _includeMeals || _includeWorkouts);

  Future<void> _handleExport() async {
    setState(() => _exporting = true);

    try {
      final repo = ref.read(lyvaRepoProvider);
      final exportService = ExportService(repo);
      final profile = await ref.read(userProfileProvider.future);

      // Calculate date range
      final endDate = DateTime.now();
      final startDate = _selectedDays > 0
          ? endDate.subtract(Duration(days: _selectedDays))
          : DateTime(2020); // "All Time" = far back enough

      File file;
      if (_selectedFormat == 'pdf') {
        file = await exportService.exportPdf(
          startDate: startDate,
          endDate: endDate,
          includeCheckIns: _includeCheckIns,
          includeMeals: _includeMeals,
          includeWorkouts: _includeWorkouts,
          userName: profile?.name,
        );
      } else {
        file = await exportService.exportCsv(
          startDate: startDate,
          endDate: endDate,
          includeCheckIns: _includeCheckIns,
          includeMeals: _includeMeals,
          includeWorkouts: _includeWorkouts,
        );
      }

      // Track analytics
      final dataTypes = <String>[];
      if (_includeCheckIns) dataTypes.add('check_ins');
      if (_includeMeals) dataTypes.add('meals');
      if (_includeWorkouts) dataTypes.add('workouts');

      ref.read(analyticsProvider).logDataExported(
            format: _selectedFormat,
            dataTypes: dataTypes,
          );

      // Share via system share sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Lyva Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildCheckboxTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDateChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.textMuted.withOpacity(0.3),
      ),
      onSelected: (_) => setState(() => _selectedDays = days),
    );
  }

  Widget _buildRadioTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedFormat,
      onChanged: (v) => setState(() => _selectedFormat = v ?? 'csv'),
      activeColor: AppColors.primary,
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
