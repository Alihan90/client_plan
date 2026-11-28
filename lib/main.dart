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

class _AppPalette {
  static const canvas = Color(0xFFF3F5F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF8FAFC);
  static const inkPrimary = Color(0xFF101828);
  static const inkSecondary = Color(0xFF667085);
  static const inkMuted = Color(0xFF98A2B3);
  static const hairline = Color(0xFFE4E7EC);

  static const primary = Color(0xFF0D5C54);
  static const primarySoft = Color(0xFFE6F4F1);

  static const pendingBg = Color(0xFFF2F4F7);
  static const pendingBorder = Color(0xFFD0D5DD);
  static const pendingPill = Color(0xFFE4E7EC);
  static const pendingText = Color(0xFF344054);

  static const doneBg = Color(0xFFECFDF3);
  static const doneBorder = Color(0xFFA6F4C5);
  static const donePill = Color(0xFFD1FADF);
  static const doneText = Color(0xFF027A48);

  static const missedBg = Color(0xFFFEF3F2);
  static const missedBorder = Color(0xFFFECDCA);
  static const missedPill = Color(0xFFFEE4E2);
  static const missedText = Color(0xFFB42318);
}

class ClientPlannerApp extends StatelessWidget {
  final PlannerController controller;

  const ClientPlannerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scheme = ColorScheme.fromSeed(
          seedColor: _AppPalette.primary,
          primary: _AppPalette.primary,
          surface: _AppPalette.surface,
          brightness: Brightness.light,
        );

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
            colorScheme: scheme,
            scaffoldBackgroundColor: _AppPalette.canvas,
            fontFamilyFallback: const ['Inter', 'SF Pro Text', 'Roboto', 'sans-serif'],
            appBarTheme: const AppBarTheme(
              backgroundColor: _AppPalette.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              foregroundColor: _AppPalette.inkPrimary,
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                side: const MaterialStatePropertyAll(
                  BorderSide(color: _AppPalette.hairline),
                ),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _AppPalette.primary;
                  }
                  return _AppPalette.surfaceSubtle;
                }),
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return _AppPalette.inkSecondary;
                }),
                textStyle: const MaterialStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
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
        final rawHeaderDate = DateFormat('d MMMM yyyy', locStr).format(controller.selectedDate);
        final headerDate = rawHeaderDate.isEmpty
            ? rawHeaderDate
            : '${rawHeaderDate[0].toUpperCase()}${rawHeaderDate.substring(1)}';

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 4,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
              tooltip: '-1',
              onPressed: () => controller.stepPeriod(-1),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.tr('app_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: _AppPalette.inkPrimary,
                  ),
                ),
                Text(
                  headerDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _AppPalette.inkSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 26),
                tooltip: '+1',
                onPressed: () => controller.stepPeriod(1),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _AppPalette.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _AppPalette.hairline),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: controller.cycleLanguage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: Text(
                      controller.languageCode.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: _AppPalette.inkPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _AppPalette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openCreateDialog(context, controller.selectedDate),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    controller.tr('book'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _AppPalette.surface,
                  border: Border(
                    bottom: BorderSide(color: _AppPalette.hairline),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<PlannerViewMode>(
                        segments: [
                          ButtonSegment<PlannerViewMode>(
                            value: PlannerViewMode.day,
                            label: Text(controller.tr('day')),
                          ),
                          ButtonSegment<PlannerViewMode>(
                            value: PlannerViewMode.week,
                            label: Text(controller.tr('week')),
                          ),
                          ButtonSegment<PlannerViewMode>(
                            value: PlannerViewMode.month,
                            label: Text(controller.tr('month')),
                          ),
                        ],
                        selected: <PlannerViewMode>{controller.viewMode},
                        onSelectionChanged: (Set<PlannerViewMode> set) {
                          if (set.isNotEmpty) {
                            controller.setViewMode(set.first);
                          }
                        },
                      ),
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
                    letterSpacing: 0.2,
                    color: _AppPalette.inkMuted,
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: _AppPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AppPalette.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _AppPalette.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 24,
                  color: _AppPalette.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.tr('no_appointments'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _AppPalette.inkSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _AppPalette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(controller.tr('book')),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isDone = item.isCompleted == true;
        final isMissed = item.isCompleted == false;

        Color rowBg = _AppPalette.pendingBg;
        Color borderColor = _AppPalette.pendingBorder;
        Color timeBadgeBg = _AppPalette.pendingPill;
        Color timeTextColor = _AppPalette.pendingText;

        if (isDone) {
          rowBg = _AppPalette.doneBg;
          borderColor = _AppPalette.doneBorder;
          timeBadgeBg = _AppPalette.donePill;
          timeTextColor = _AppPalette.doneText;
        } else if (isMissed) {
          rowBg = _AppPalette.missedBg;
          borderColor = _AppPalette.missedBorder;
          timeBadgeBg = _AppPalette.missedPill;
          timeTextColor = _AppPalette.missedText;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: timeBadgeBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  item.formattedTime,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: timeTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onEdit(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                          color: _AppPalette.inkPrimary,
                        ),
                      ),
                      if (item.serviceName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _AppPalette.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RowActionButton(
                icon: Icons.edit_outlined,
                active: false,
                activeColor: _AppPalette.primary,
                activeBg: _AppPalette.primarySoft,
                iconColor: _AppPalette.inkSecondary,
                onTap: () => onEdit(item),
              ),
              const SizedBox(width: 6),
              _RowActionButton(
                icon: Icons.check_rounded,
                active: isDone,
                activeColor: _AppPalette.doneText,
                activeBg: _AppPalette.donePill,
                iconColor: isDone ? _AppPalette.doneText : _AppPalette.inkSecondary,
                onTap: () => controller.toggleQuickStatus(item.id, true),
              ),
              const SizedBox(width: 6),
              _RowActionButton(
                icon: Icons.close_rounded,
                active: isMissed,
                activeColor: _AppPalette.missedText,
                activeBg: _AppPalette.missedPill,
                iconColor: isMissed ? _AppPalette.missedText : _AppPalette.inkSecondary,
                onTap: () => controller.toggleQuickStatus(item.id, false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RowActionButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _RowActionButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.activeBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? activeBg : _AppPalette.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active ? activeColor : _AppPalette.pendingBorder,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
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
    final locStr = controller.locale.toString();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final items = controller.appointmentsForDay(day);
        final isSelected = day == sel;
        final rawDayTitle = DateFormat('EEEE, d MMM', locStr).format(day);
        final dayTitle = rawDayTitle.isEmpty
            ? rawDayTitle
            : '${rawDayTitle[0].toUpperCase()}${rawDayTitle.substring(1)}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _AppPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _AppPalette.primary : _AppPalette.hairline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.selectDate(day),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? _AppPalette.primary : _AppPalette.inkPrimary,
                        ),
                      ),
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _AppPalette.primarySoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _AppPalette.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onEdit(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _AppPalette.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _AppPalette.hairline),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item.formattedTime,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _AppPalette.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _AppPalette.inkPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.statusLabel(now, lang: controller.languageCode),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _AppPalette.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
    final locStr = controller.locale.toString();
    final firstDay = DateTime(sel.year, sel.month, 1);
    final daysInMonth = DateTime(sel.year, sel.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    final rawMonthTitle = DateFormat('MMMM yyyy', locStr).format(firstDay);
    final monthTitle = rawMonthTitle.isEmpty
        ? rawMonthTitle
        : '${rawMonthTitle[0].toUpperCase()}${rawMonthTitle.substring(1)}';

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: _AppPalette.surface,
            border: Border(bottom: BorderSide(color: _AppPalette.hairline)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      final prevMonth = DateTime(sel.year, sel.month - 1, 1);
                      final maxDay = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
                      onSelectDay(DateTime(prevMonth.year, prevMonth.month, sel.day.clamp(1, maxDay)));
                    },
                  ),
                  Text(
                    monthTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _AppPalette.inkPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      final nextMonth = DateTime(sel.year, sel.month + 1, 1);
                      final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
                      onSelectDay(DateTime(nextMonth.year, nextMonth.month, sel.day.clamp(1, maxDay)));
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: 12,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, mIndex) {
                    final monthNum = mIndex + 1;
                    final mDate = DateTime(sel.year, monthNum, 1);
                    final isCurrentMonth = monthNum == sel.month;
                    final rawShort = DateFormat('MMM', locStr).format(mDate);
                    final shortMonth = rawShort.replaceAll('.', '');

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final maxDay = DateTime(sel.year, monthNum + 1, 0).day;
                        onSelectDay(DateTime(sel.year, monthNum, sel.day.clamp(1, maxDay)));
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isCurrentMonth ? _AppPalette.primary : _AppPalette.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrentMonth ? _AppPalette.primary : _AppPalette.hairline,
                          ),
                        ),
                        child: Text(
                          shortMonth,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCurrentMonth ? Colors.white : _AppPalette.inkSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
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
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  onSelectDay(date);
                  controller.setViewMode(PlannerViewMode.day);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _AppPalette.primary : _AppPalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _AppPalette.primary : _AppPalette.hairline,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? Colors.white : _AppPalette.inkPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.22)
                                : _AppPalette.primarySoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : _AppPalette.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
