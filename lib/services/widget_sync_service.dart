import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/appointment.dart';

class WidgetSyncService {
  static const String androidWidgetProvider = 'PlannerWidgetProvider';
  static const String iosWidgetKind = 'PlannerWidget';
  static const String iosAppGroupId = 'group.com.example.clientPlanner';

  static Future<void> syncTodayAppointments(
    List<Appointment> all,
    DateTime targetDay,
  ) async {
    await HomeWidget.setAppGroupId(iosAppGroupId);

    final now = DateTime.now();
    final norm = DateTime(targetDay.year, targetDay.month, targetDay.day);
    final dayItems = all.where((a) => a.normalizedDate == norm).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final summaryLines = dayItems.isEmpty
        ? ['На выбранный день записей нет']
        : dayItems
            .take(5)
            .map((a) => '${a.formattedTime} — ${a.clientName} [${a.statusLabel(now)}]')
            .toList();

    await HomeWidget.saveWidgetData<String>(
      'widget_title',
      'Записи: ${norm.day.toString().padLeft(2, '0')}.${norm.month.toString().padLeft(2, '0')}',
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_items_json',
      jsonEncode(summaryLines),
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_items_text',
      summaryLines.join('\n'),
    );

    await HomeWidget.updateWidget(
      androidName: androidWidgetProvider,
      iOSName: iosWidgetKind,
    );
  }
}
