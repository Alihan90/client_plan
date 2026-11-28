import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'models/appointment.dart';
import 'state/planner_controller.dart';
import 'widgets/appointment_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  await initializeDateFormatting('uk_UA');
  await initializeDateFormatting('en_US');

  final controller = PlannerController();
  runApp(ClientPlannerApp(controller: controller));
}

class ClientPlannerApp extends StatelessWidget {
  final PlannerController controller;

  const ClientPlannerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: controller.locale,
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('uk', 'UA'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          title: controller.tr('app_title'),
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7F8),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),
          ),
          home: PlannerHomePage(controller: controller),
        );
      },
    );
  }
}

class PlannerHomePage extends StatelessWidget {
  final PlannerController controller;

  const PlannerHomePage({super.key, required this.controller});

  Color _statusColor(Appointment a, DateTime now) {
    final label = a.statusLabel(now, lang: 'en');
    if (label == 'Completed') return const Color(0xFF15803D);
    if (label == 'Missed') return const Color(0xFFB91C1C);
    return const Color(0xFF64748B);
  }

  Color _statusBgColor(Appointment a, DateTime now) {
    final label = a.statusLabel(now, lang: 'en');
    if (label == 'Completed') return const Color(0xFFDCFCE7);
    if (label == 'Missed') return const Color(0xFFFEE2E2);
    return const Color(0xFFF1F5F9);
  }

  Future<void> _openCreateDialog(BuildContext context, DateTime date) async {
    FocusScope.of(context).unfocus();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppointmentDialog(
        controller: controller,
        initialDate: date,
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, Appointment item) async {
    FocusScope.of(context).unfocus();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppointmentDialog(
        controller: controller,
        existing: item,
        initialDate: item.normalizedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final now = DateTime.now();
        final locStr = controller.locale.toString();
        final headerDate = DateFormat('d MMMM yyyy', locStr).format(controller.selectedDate);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => controller.stepPeriod(-1),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.tr('app_title'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                Text(
                  headerDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: controller.cycleLanguage,
                  child: Text(
                    controller.languageCode.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openCreateDialog(context, controller.selectedDate),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(controller.tr('book')),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    SegmentedButton<PlannerViewMode>(
                      segments: [
                        ButtonSegment(
                          value: PlannerViewMode.day,
                          label: Text(controller.tr('day')),
                        ),
                        ButtonSegment(
                          value: PlannerViewMode.week,
                          label: Text(controller.tr('week')),
                        ),
                        ButtonSegment(
                          value: PlannerViewMode.month,
                          label: Text(controller.tr('month')),
                        ),
                      ],
                      selected: {controller.viewMode},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) {
                          controller.setViewMode(set.first);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _WeekdayHeader(controller: controller),
                  ],
                ),
              ),
              Expanded(child: _buildBody(context, now)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DateTime now) {
    switch (controller.viewMode) {
      case PlannerViewMode.day:
        return _DayView(
          controller: controller,
          now: now,
          onEdit: (item) => _openEditDialog(context, item),
          onAdd: () => _openCreateDialog(context, controller.selectedDate),
        );
      case PlannerViewMode.week:
        return _WeekView(
          controller: controller,
          now: now,
          onEdit: (item) => _openEditDialog(context, item),
        );
      case PlannerViewMode.month:
        return _MonthView(
          controller: controller,
          onSelectDay: (d) => controller.selectDate(d),
        );
    }
  }
}

class _WeekdayHeader extends StatelessWidget {
  final PlannerController controller;

  const _WeekdayHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final days = [
      controller.tr('mon'),
      controller.tr('tue'),
      controller.tr('wed'),
      controller.tr('thu'),
      controller.tr('fri'),
      controller.tr('sat'),
      controller.tr('sun'),
    ];
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DayView extends StatelessWidget {
  final PlannerController controller;
  final DateTime now;
  final void Function(Appointment) onEdit;
  final VoidCallback onAdd;

  const _DayView({
    required this.controller,
    required this.now,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final items = controller.appointmentsForDay(controller.selectedDate);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_rounded, size: 44, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              controller.tr('no_appointments'),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onAdd,
              child: Text(controller.tr('book')),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final color = _colorFor(item);
        final bg = _bgFor(item);
        final statusText = item.statusLabel(now, lang: controller.languageCode);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onEdit(item),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.formattedTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (item.serviceName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.serviceName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _colorFor(Appointment item) {
    final s = item.statusLabel(now, lang: 'en');
    if (s == 'Completed') return const Color(0xFF15803D);
    if (s == 'Missed') return const Color(0xFFB91C1C);
    return const Color(0xFF64748B);
  }

  Color _bgFor(Appointment item) {
    final s = item.statusLabel(now, lang: 'en');
    if (s == 'Completed') return const Color(0xFFDCFCE7);
    if (s == 'Missed') return const Color(0xFFFEE2E2);
    return const Color(0xFFF1F5F9);
  }
}

class _WeekView extends StatelessWidget {
  final PlannerController controller;
  final DateTime now;
  final void Function(Appointment) onEdit;

  const _WeekView({
    required this.controller,
    required this.now,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final sel = controller.selectedDate;
    final monday = sel.subtract(Duration(days: sel.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final items = controller.appointmentsForDay(day);
        final isSelected = day == sel;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => controller.selectDate(day),
                  child: Text(
                    DateFormat('EEEE, d MMM', controller.locale.toString()).format(day),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final item in items)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item.formattedTime} — ${item.clientName}'),
                      subtitle: item.serviceName.isNotEmpty ? Text(item.serviceName) : null,
                      trailing: Text(
                        item.statusLabel(now, lang: controller.languageCode),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onTap: () => onEdit(item),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthView extends StatelessWidget {
  final PlannerController controller;
  final void Function(DateTime) onSelectDay;

  const _MonthView({
    required this.controller,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final sel = controller.selectedDate;
    final firstDay = DateTime(sel.year, sel.month, 1);
    final daysInMonth = DateTime(sel.year, sel.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingEmpty) {
          return const SizedBox.shrink();
        }
        final dayNum = index - leadingEmpty + 1;
        final date = DateTime(sel.year, sel.month, dayNum);
        final isSelected = date == sel;
        final count = controller.appointmentsForDay(date).length;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            onSelectDay(date);
            controller.setViewMode(PlannerViewMode.day);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0F766E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : const Color(0xFF0F766E),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
