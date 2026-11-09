import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cycle_calendar_data.dart';
import '../models/cycle_log.dart';
import '../theme/app_theme.dart';

enum CycleCalendarView { month, week, day }

class CycleCalendar extends StatefulWidget {
  const CycleCalendar({super.key, required this.data, this.onEdit});
  final CycleCalendarData data;
  final ValueChanged<CycleLog>? onEdit;
  @override
  State<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends State<CycleCalendar> {
  late DateTime selected = widget.data.today;
  CycleCalendarView view = CycleCalendarView.month;
  @override
  void didUpdateWidget(covariant CycleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selected == oldWidget.data.today &&
        widget.data.today != oldWidget.data.today) {
      selected = widget.data.today;
    }
  }

  void move(int direction) => setState(() {
    selected = switch (view) {
      CycleCalendarView.month => DateTime(
        selected.year,
        selected.month + direction,
        selected.day.clamp(
          1,
          DateTime(selected.year, selected.month + direction + 1, 0).day,
        ),
      ),
      CycleCalendarView.week => DateTime(
        selected.year,
        selected.month,
        selected.day + 7 * direction,
      ),
      CycleCalendarView.day => DateTime(
        selected.year,
        selected.month,
        selected.day + direction,
      ),
    };
  });
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.of(context).accessibleNavigation;
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final mode in CycleCalendarView.values)
              ChoiceChip(
                label: Text(
                  mode.name[0].toUpperCase() + mode.name.substring(1),
                ),
                selected: view == mode,
                onSelected: (_) => setState(() => view = mode),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous ${view.name}',
              onPressed: () => move(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                view == CycleCalendarView.month
                    ? DateFormat.yMMMM().format(selected)
                    : DateFormat.yMMMd().format(selected),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Next ${view.name}',
              onPressed: () => move(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => selected = data.today),
            child: const Text('Today'),
          ),
        ),
        const Text(
          'B Bleeding event   S Symptom   L Other log   \u25c7 Calendar estimate   \u2014 Not logged',
        ),
        const Text(
          'Color fades are decorative, not intensity, hormone levels or confidence.',
        ),
        const SizedBox(height: 12),
        if (view == CycleCalendarView.month)
          LayoutBuilder(
            builder: (context, constraints) {
              final first = DateTime(selected.year, selected.month);
              final start = DateTime(
                first.year,
                first.month,
                1 - (first.weekday - 1),
              );
              final width = (constraints.maxWidth / 7).clamp(52.0, 100.0);
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width * 7,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final label in [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ])
                            SizedBox(
                              width: width,
                              child: Text(label, textAlign: TextAlign.center),
                            ),
                        ],
                      ),
                      for (var row = 0; row < 6; row++)
                        Row(
                          children: [
                            for (var col = 0; col < 7; col++)
                              SizedBox(
                                width: width,
                                height: 76 * scale,
                                child: dayTile(
                                  DateTime(
                                    start.year,
                                    start.month,
                                    start.day + row * 7 + col,
                                  ),
                                  duration,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (view == CycleCalendarView.week) ...[
          for (var offset = 0; offset < 7; offset++)
            weekTile(
              DateTime(
                selected.year,
                selected.month,
                selected.day - selected.weekday + 1 + offset,
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          '${view == CycleCalendarView.day ? 'Day details' : 'Selected day'} · ${DateFormat.yMMMMd().format(selected)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (view != CycleCalendarView.day) ...[
          Text(data.summary(selected)),
          TextButton(
            onPressed: () => setState(() => view = CycleCalendarView.day),
            child: const Text('Open day details'),
          ),
        ] else
          ...details(selected),
      ],
    );
  }

  Color tint(DateTime date) {
    final records = widget.data.events(date);
    if (records.any(
      (e) => ['period_start', 'period_end', 'spotting'].contains(e.eventType),
    )) {
      return AppColors.fatPink;
    }
    if (records.isNotEmpty) return AppColors.primary;
    if (widget.data.projectedStart == date) return AppColors.seasonAccent;
    return AppColors.surface;
  }

  Widget dayTile(DateTime date, Duration duration) {
    final records = widget.data.events(date);
    final markers = records
        .map(
          (record) =>
              [
                'period_start',
                'period_end',
                'spotting',
              ].contains(record.eventType)
              ? 'B'
              : record.eventType == 'symptom'
              ? 'S'
              : 'L',
        )
        .toSet()
        .join(' ');
    final estimate = widget.data.projectedStart == date;
    final text =
        '${DateFormat.yMMMMd().format(date)}. ${widget.data.summary(date)}';
    return Semantics(
      button: true,
      selected: date == selected,
      label: text,
      onTap: () => setState(() => selected = date),
      child: ExcludeSemantics(
        child: Tooltip(
          message: text,
          child: InkWell(
            onTap: () => setState(() => selected = date),
            child: AnimatedContainer(
              duration: duration,
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: date == selected
                      ? AppColors.action
                      : AppColors.textSecondary,
                  width: date == selected ? 2 : 0.5,
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.surface,
                    Color.lerp(AppColors.surface, tint(date), .3)!,
                    AppColors.surface,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${markers.isEmpty ? '\u2014' : markers}${estimate ? ' ◇' : ''}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget weekTile(DateTime date) => Card(
    child: ListTile(
      leading: Icon(
        widget.data.events(date).isEmpty ? Icons.remove : Icons.circle,
        color: AppColors.action,
      ),
      title: Text(DateFormat.MMMEd().format(date)),
      subtitle: Text(widget.data.summary(date)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setState(() {
        selected = date;
        view = CycleCalendarView.day;
      }),
    ),
  );
  List<Widget> details(DateTime date) {
    final events = widget.data.events(date);
    return [
      if (events.isEmpty)
        const Text(
          'No events logged. This does not mean no bleeding or no symptoms.',
        ),
      for (final log in events)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CycleCalendarData.eventLabel(log),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Recorded for ${DateFormat.yMMMd().format(log.ts.toLocal())}',
                ),
                if (log.eventType == 'symptom')
                  Text(
                    log.severity != null &&
                            log.severity! >= 1 &&
                            log.severity! <= 5
                        ? 'Reported severity: ${log.severity}/5'
                        : 'Severity not available',
                  ),
                if (log.notes?.trim().isNotEmpty == true) Text(log.notes!),
                if (widget.onEdit != null)
                  TextButton.icon(
                    onPressed: () => widget.onEdit!(log),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit recorded details'),
                  ),
              ],
            ),
          ),
        ),
      if (widget.data.projectedStart == date)
        const Text(
          '◇ Estimated period start — not confirmed. Actual timing can differ.',
        ),
      const SizedBox(height: 8),
      const Text(
        'Only explicitly logged dates are marked as recorded. A period start or end does not confirm bleeding on intervening days.',
      ),
    ];
  }
}
