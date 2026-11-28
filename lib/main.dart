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

class _ThemeTokens {
  final bool isDark;
  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkMuted;
  final Color hairline;
  final Color primary;
  final Color primarySoft;

  final Color pendingBg;
  final Color pendingBorder;
  final Color pendingPill;
  final Color pendingText;

  final Color doneBg;
  final Color doneBorder;
  final Color donePill;
  final Color doneText;

  final Color missedBg;
  final Color missedBorder;
  final Color missedPill;
  final Color missedText;

  const _ThemeTokens._({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkMuted,
    required this.hairline,
    required this.primary,
    required this.primarySoft,
    required this.pendingBg,
    required this.pendingBorder,
    required this.pendingPill,
    required this.pendingText,
    required this.doneBg,
    required this.doneBorder,
    required this.donePill,
    required this.doneText,
    required this.missedBg,
    required this.missedBorder,
    required this.missedPill,
    required this.missedText,
  });

  factory _ThemeTokens.fromDark(bool isDark) {
    if (isDark) {
      return const _ThemeTokens._(
        isDark: true,
        canvas: Color(0xFF0B0F14),
        surface: Color(0xFF121821),
        surfaceSubtle: Color(0xFF18202C),
        inkPrimary: Color(0xFFF3F4F6),
        inkSecondary: Color(0xFF9CA3AF),
        inkMuted: Color(0xFF6B7280),
        hairline: Color(0xFF242E3D),
        primary: Color(0xFF14B8A6),
        primarySoft: Color(0xFF132E2C),
        pendingBg: Color(0xFF161E29),
        pendingBorder: Color(0xFF2A3546),
        pendingPill: Color(0xFF222C3B),
        pendingText: Color(0xFFD1D5DB),
        doneBg: Color(0xFF0E261D),
        doneBorder: Color(0xFF1E563F),
        donePill: Color(0xFF153B2C),
        doneText: Color(0xFF4ADE80),
        missedBg: Color(0xFF291316),
        missedBorder: Color(0xFF5C232A),
        missedPill: Color(0xFF3E191E),
        missedText: Color(0xFFF87171),
      );
    }

    return const _ThemeTokens._(
      isDark: false,
      canvas: Color(0xFFF3F5F4),
      surface: Color(0xFFFFFFFF),
      surfaceSubtle: Color(0xFFF8FAFC),
      inkPrimary: Color(0xFF101828),
      inkSecondary: Color(0xFF667085),
      inkMuted: Color(0xFF98A2B3),
      hairline: Color(0xFFE4E7EC),
      primary: Color(0xFF0D5C54),
      primarySoft: Color(0xFFE6F4F1),
      pendingBg: Color(0xFFF2F4F7),
      pendingBorder: Color(0xFFD0D5DD),
      pendingPill: Color(0xFFE4E7EC),
      pendingText: Color(0xFF344054),
      doneBg: Color(0xFFECFDF3),
      doneBorder: Color(0xFFA6F4C5),
      donePill: Color(0xFFD1FADF),
      doneText: Color(0xFF027A48),
      missedBg: Color(0xFFFEF3F2),
      missedBorder: Color(0xFFFECDCA),
      missedPill: Color(0xFFFEE4E2),
      missedText: Color(0xFFB42318),
    );
  }
}

class ClientPlannerApp extends StatelessWidget {
  final PlannerController controller;

  const ClientPlannerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tokens = _ThemeTokens.fromDark(controller.isDarkTheme);
        final scheme = ColorScheme.fromSeed(
          seedColor: tokens.primary,
          primary: tokens.primary,
          surface: tokens.surface,
          brightness: tokens.isDark ? Brightness.dark : Brightness.light,
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
            scaffoldBackgroundColor: tokens.canvas,
            fontFamilyFallback: const ['Inter', 'SF Pro Text', 'Roboto', 'sans-serif'],
            appBarTheme: AppBarTheme(
              backgroundColor: tokens.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              foregroundColor: tokens.inkPrimary,
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

  Future<void> _openSettingsSheet(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final t = _ThemeTokens.fromDark(controller.isDarkTheme);
            return Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: t.hairline,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        controller.tr('settings'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          controller.tr('dark_theme'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.inkPrimary,
                          ),
                        ),
                        subtitle: Text(
                          controller.tr('dark_theme_sub'),
                          style: TextStyle(fontSize: 12, color: t.inkSecondary),
                        ),
                        value: controller.isDarkTheme,
                        onChanged: controller.setDarkTheme,
                      ),
                      Divider(color: t.hairline),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          controller.tr('compact_cards'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.inkPrimary,
                          ),
                        ),
                        subtitle: Text(
                          controller.tr('compact_cards_sub'),
                          style: TextStyle(fontSize: 12, color: t.inkSecondary),
                        ),
                        value: controller.compactCardView,
                        onChanged: controller.setCompactCardView,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: t.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        child: Text(controller.tr('close')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _ThemeTokens.fromDark(controller.isDarkTheme);
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
          onPressed: () => controller.stepPeriod(-1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.tr('app_title'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                color: tokens.inkPrimary,
              ),
            ),
            Text(
              headerDate,
              style: TextStyle(
                fontSize: 12,
                color: tokens.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 26),
            onPressed: () => controller.stepPeriod(1),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.hairline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: controller.cycleLanguage,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  controller.languageCode.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: tokens.inkPrimary,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 21, color: tokens.inkSecondary),
            tooltip: controller.tr('settings'),
            onPressed: () => _openSettingsSheet(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border(bottom: BorderSide(color: tokens.hairline)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Column(
              children: [
                _ViewModeBar(controller: controller, tokens: tokens),
                const SizedBox(height: 12),
                _WeekdayHeader(controller: controller, tokens: tokens),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, now, tokens)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DateTime now, _ThemeTokens tokens) {
    switch (controller.viewMode) {
      case PlannerViewMode.day:
        return _DayView(
          controller: controller,
          tokens: tokens,
          now: now,
          onEdit: (item) => _openEditDialog(context, item),
          onAdd: () => _openCreateDialog(context, controller.selectedDate),
        );
      case PlannerViewMode.week:
        return _WeekView(
          controller: controller,
          tokens: tokens,
          now: now,
          onEdit: (item) => _openEditDialog(context, item),
        );
      case PlannerViewMode.month:
        return _MonthView(
          controller: controller,
          tokens: tokens,
          onSelectDay: (d) => controller.selectDate(d),
        );
    }
  }
}

class _ViewModeBar extends StatelessWidget {
  final PlannerController controller;
  final _ThemeTokens tokens;

  const _ViewModeBar({required this.controller, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (PlannerViewMode.day, controller.tr('day')),
      (PlannerViewMode.week, controller.tr('week')),
      (PlannerViewMode.month, controller.tr('month')),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: tokens.hairline),
      ),
      child: Row(
        children: modes.map((entry) {
          final isSelected = controller.viewMode == entry.$1;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => controller.setViewMode(entry.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? tokens.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : tokens.inkSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final PlannerController controller;
  final _ThemeTokens tokens;

  const _WeekdayHeader({required this.controller, required this.tokens});

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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: tokens.inkMuted,
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
  final _ThemeTokens tokens;
  final DateTime now;
  final void Function(Appointment) onEdit;
  final VoidCallback onAdd;

  const _DayView({
    required this.controller,
    required this.tokens,
    required this.now,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final items = controller.appointmentsForDay(controller.selectedDate);
    final isCompact = controller.compactCardView;

    if (items.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  size: 24,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.tr('no_appointments'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.inkSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.primary,
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
      separatorBuilder: (_, __) => SizedBox(height: isCompact ? 7 : 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isDone = item.isCompleted == true;
        final isMissed = item.isCompleted == false;

        Color rowBg = tokens.pendingBg;
        Color borderColor = tokens.pendingBorder;
        Color timeBadgeBg = tokens.pendingPill;
        Color timeTextColor = tokens.pendingText;

        if (isDone) {
          rowBg = tokens.doneBg;
          borderColor = tokens.doneBorder;
          timeBadgeBg = tokens.donePill;
          timeTextColor = tokens.doneText;
        } else if (isMissed) {
          rowBg = tokens.missedBg;
          borderColor = tokens.missedBorder;
          timeBadgeBg = tokens.missedPill;
          timeTextColor = tokens.missedText;
        }

        final endH = (item.endMinutes ~/ 60).toString().padLeft(2, '0');
        final endM = (item.endMinutes % 60).toString().padLeft(2, '0');
        final durationLabel =
            '${item.formattedTime}–$endH:$endM (${item.durationMinutes} ${controller.tr('minutes_short')})';

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isCompact ? 8 : 11,
          ),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: isCompact ? 5 : 7,
                ),
                decoration: BoxDecoration(
                  color: timeBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.formattedTime,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: timeTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 14 : 15,
                          letterSpacing: -0.2,
                          color: tokens.inkPrimary,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.serviceName.isNotEmpty
                              ? '${item.serviceName} · $durationLabel'
                              : durationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.inkSecondary,
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
                activeColor: tokens.primary,
                activeBg: tokens.primarySoft,
                iconColor: tokens.inkSecondary,
                tokens: tokens,
                onTap: () => onEdit(item),
              ),
              const SizedBox(width: 6),
              _RowActionButton(
                icon: Icons.check_rounded,
                active: isDone,
                activeColor: tokens.doneText,
                activeBg: tokens.donePill,
                iconColor: isDone ? tokens.doneText : tokens.inkSecondary,
                tokens: tokens,
                onTap: () => controller.toggleQuickStatus(item.id, true),
              ),
              const SizedBox(width: 6),
              _RowActionButton(
                icon: Icons.close_rounded,
                active: isMissed,
                activeColor: tokens.missedText,
                activeBg: tokens.missedPill,
                iconColor: isMissed ? tokens.missedText : tokens.inkSecondary,
                tokens: tokens,
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
  final _ThemeTokens tokens;
  final VoidCallback onTap;

  const _RowActionButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.activeBg,
    required this.iconColor,
    required this.tokens,
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
          color: active ? activeBg : tokens.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active ? activeColor : tokens.pendingBorder,
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
  final _ThemeTokens tokens;
  final DateTime now;
  final void Function(Appointment) onEdit;

  const _WeekView({
    required this.controller,
    required this.tokens,
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
            color: tokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? tokens.primary : tokens.hairline,
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
                          color: isSelected ? tokens.primary : tokens.inkPrimary,
                        ),
                      ),
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.primarySoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${items.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tokens.primary,
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
                            color: tokens.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.hairline),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item.formattedTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: tokens.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: tokens.inkPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.statusLabel(now, lang: controller.languageCode),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.inkSecondary,
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
  final _ThemeTokens tokens;
  final void Function(DateTime) onSelectDay;

  const _MonthView({
    required this.controller,
    required this.tokens,
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
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border(bottom: BorderSide(color: tokens.hairline)),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: tokens.inkPrimary,
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
                          color: isCurrentMonth ? tokens.primary : tokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrentMonth ? tokens.primary : tokens.hairline,
                          ),
                        ),
                        child: Text(
                          shortMonth,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCurrentMonth ? Colors.white : tokens.inkSecondary,
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
                    color: isSelected ? tokens.primary : tokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? tokens.primary : tokens.hairline,
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
                          color: isSelected ? Colors.white : tokens.inkPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.22)
                                : tokens.primarySoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : tokens.primary,
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
