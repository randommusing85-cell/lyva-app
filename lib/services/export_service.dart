import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/checkin.dart';
import '../models/meal_log.dart';
import '../models/workout_session_doc.dart';
import '../repos/prime_repo.dart';

/// Service for exporting user data to CSV or PDF.
class ExportService {
  final PrimeRepo _repo;

  ExportService(this._repo);

  // ===== CSV EXPORT =====

  Future<File> exportCsv({
    required DateTime startDate,
    required DateTime endDate,
    required bool includeCheckIns,
    required bool includeMeals,
    required bool includeWorkouts,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    if (includeCheckIns) {
      final checkIns = await _repo.getCheckInsInDateRange(startDate, endDate);
      buffer.writeln('=== CHECK-INS ===');
      buffer.writeln('Date,Weight (kg),Waist (cm),Steps,Mood (1-5),Energy (1-5),Notes');
      for (final c in checkIns) {
        final date = dateFormat.format(c.ts);
        final note = (c.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        buffer.writeln(
          '$date,${c.weightKg},${c.waistCm ?? ''},${c.stepsToday ?? ''},${c.moodScore ?? ''},${c.energyScore ?? ''},$note',
        );
      }
      buffer.writeln();
    }

    if (includeMeals) {
      final days = endDate.difference(startDate).inDays + 1;
      final meals = await _repo.getMealsForLastDays(days);
      final filtered = meals.where((m) =>
          m.ts.isAfter(startDate.subtract(const Duration(days: 1))) &&
          m.ts.isBefore(endDate.add(const Duration(days: 1)))).toList();
      buffer.writeln('=== MEALS ===');
      buffer.writeln('Date,Time,Type,Protein (g),Carbs (g),Fat (g),Calories,Description');
      for (final m in filtered) {
        final date = dateFormat.format(m.ts);
        final time = timeFormat.format(m.ts);
        final desc = (m.description ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        buffer.writeln(
          '$date,$time,${m.mealType},${m.proteinG},${m.carbsG},${m.fatG},${m.calories},$desc',
        );
      }
      buffer.writeln();
    }

    if (includeWorkouts) {
      final sessions = await _repo.getSessionsInDateRange(startDate, endDate);
      buffer.writeln('=== WORKOUTS ===');
      buffer.writeln('Date,Day,Completed,Skipped,Skip Reason,Notes');
      for (final s in sessions) {
        final date = dateFormat.format(s.date);
        final reason = (s.skipReason ?? '').replaceAll(',', ';');
        final notes = (s.notes ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        buffer.writeln(
          '$date,Day ${s.dayIndex + 1},${s.completed ? 'Yes' : 'No'},${s.skipped ? 'Yes' : 'No'},$reason,$notes',
        );
      }
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/primeform_export_${dateFormat.format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  // ===== PDF EXPORT =====

  Future<File> exportPdf({
    required DateTime startDate,
    required DateTime endDate,
    required bool includeCheckIns,
    required bool includeMeals,
    required bool includeWorkouts,
    String? userName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRangeText =
        '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

    // Gather data
    List<CheckIn> checkIns = [];
    List<MealLog> meals = [];
    List<WorkoutSessionDoc> sessions = [];

    if (includeCheckIns) {
      checkIns = await _repo.getCheckInsInDateRange(startDate, endDate);
    }
    if (includeMeals) {
      final days = endDate.difference(startDate).inDays + 1;
      final allMeals = await _repo.getMealsForLastDays(days);
      meals = allMeals.where((m) =>
          m.ts.isAfter(startDate.subtract(const Duration(days: 1))) &&
          m.ts.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }
    if (includeWorkouts) {
      sessions = await _repo.getSessionsInDateRange(startDate, endDate);
    }

    // Page 1: Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PrimeForm Progress Report',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (userName != null)
              pw.Text(userName, style: const pw.TextStyle(fontSize: 16)),
            pw.Text(dateRangeText,
                style: pw.TextStyle(
                    fontSize: 14, color: PdfColor.fromInt(0xFF888888))),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),

            // Summary metrics
            pw.Text('Summary',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),

            if (checkIns.isNotEmpty) ...[
              _pdfMetricRow('Check-ins', '${checkIns.length}'),
              if (checkIns.length >= 2) ...[
                _pdfMetricRow('Starting Weight',
                    '${checkIns.last.weightKg.toStringAsFixed(1)} kg'),
                _pdfMetricRow('Current Weight',
                    '${checkIns.first.weightKg.toStringAsFixed(1)} kg'),
                _pdfMetricRow(
                  'Weight Change',
                  '${(checkIns.first.weightKg - checkIns.last.weightKg).toStringAsFixed(1)} kg',
                ),
              ],
            ],

            if (meals.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              _pdfMetricRow('Meals Logged', '${meals.length}'),
              _pdfMetricRow(
                'Avg Daily Calories',
                '${_avgDailyCalories(meals).round()}',
              ),
            ],

            if (sessions.isNotEmpty) ..._buildWorkoutSummary(sessions),
          ],
        ),
      ),
    );

    // Page 2+: Check-in table
    if (includeCheckIns && checkIns.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('Check-in History',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Weight', 'Waist', 'Steps', 'Mood', 'Energy'],
              data: checkIns.map((c) {
                final df = DateFormat('MMM d');
                return [
                  df.format(c.ts),
                  '${c.weightKg.toStringAsFixed(1)} kg',
                  c.waistCm != null ? '${c.waistCm} cm' : '-',
                  c.stepsToday?.toString() ?? '-',
                  c.moodScore?.toString() ?? '-',
                  c.energyScore?.toString() ?? '-',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    // Page 3+: Meal table
    if (includeMeals && meals.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('Meal History',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Protein', 'Carbs', 'Fat', 'Calories'],
              data: meals.map((m) {
                final df = DateFormat('MMM d');
                return [
                  df.format(m.ts),
                  m.mealType,
                  '${m.proteinG}g',
                  '${m.carbsG}g',
                  '${m.fatG}g',
                  '${m.calories}',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    // Page 4+: Workout table
    if (includeWorkouts && sessions.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('Workout History',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Day', 'Status', 'Notes'],
              data: sessions.map((s) {
                final df = DateFormat('MMM d');
                final status = s.completed
                    ? 'Completed'
                    : s.skipped
                        ? 'Skipped: ${s.skipReason ?? ''}'
                        : 'Pending';
                return [
                  df.format(s.date),
                  'Day ${s.dayIndex + 1}',
                  status,
                  s.notes ?? '',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/primeform_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Helpers

  pw.Widget _pdfMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  List<pw.Widget> _buildWorkoutSummary(List<WorkoutSessionDoc> sessions) {
    final completed = sessions.where((s) => s.completed).length;
    final rate = (completed / sessions.length * 100).round();
    return [
      pw.SizedBox(height: 8),
      _pdfMetricRow('Workouts Completed', '$completed'),
      _pdfMetricRow('Completion Rate', '$rate%'),
    ];
  }

  double _avgDailyCalories(List<MealLog> meals) {
    if (meals.isEmpty) return 0;
    final totalCal = meals.fold<int>(0, (sum, m) => sum + m.calories);
    final days = <String>{};
    for (final m in meals) {
      days.add(DateFormat('yyyy-MM-dd').format(m.ts));
    }
    return days.isEmpty ? 0 : totalCal / days.length;
  }
}
