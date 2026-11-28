import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/widget_sync_service.dart';

enum PlannerViewMode { day, week, month }

class PlannerController extends ChangeNotifier {
  final List<Appointment> _appointments = [];
  DateTime _selectedDate = DateTime.now();
  PlannerViewMode _viewMode = PlannerViewMode.day;
  String _languageCode = 'ru';

  PlannerController() {
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    _syncWidget();
  }

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  DateTime get selectedDate => _selectedDate;

  PlannerViewMode get viewMode => _viewMode;

  String get languageCode => _languageCode;

  Locale get locale {
    switch (_languageCode) {
      case 'uk':
        return const Locale('uk', 'UA');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ru', 'RU');
    }
  }

  String tr(String key) {
    const dict = {
      'ru': {
        'app_title': 'Планер записей',
        'book': 'Записать',
        'day': 'День',
        'week': 'Неделя',
        'month': 'Месяц',
        'no_appointments': 'На этот день записей нет',
        'add_title': 'Новая запись',
        'edit_title': 'Редактировать запись',
        'client_label': 'Клиент',
        'client_hint': 'Введите имя клиента',
        'client_error': 'Укажите имя клиента',
        'service_label': 'Услуга',
        'service_hint': 'Например: Консультация',
        'date_label': 'Дата',
        'time_label': 'Время (24ч)',
        'hour': 'Час',
        'minute': 'Мин',
        'repeat_until_end': 'Повторять до конца месяца',
        'repeat_days': 'Дни недели для повтора',
        'status_label': 'Статус записи',
        'status_auto': 'Авто (Ожидание)',
        'status_done': 'Выполнено',
        'status_missed': 'Не выполнено',
        'delete': 'Удалить',
        'cancel': 'Отмена',
        'save': 'Сохранить',
        'create': 'Создать',
        'mon': 'Пн',
        'tue': 'Вт',
        'wed': 'Ср',
        'thu': 'Чт',
        'fri': 'Пт',
        'sat': 'Сб',
        'sun': 'Вс',
      },
      'uk': {
        'app_title': 'Планер записів',
        'book': 'Записати',
        'day': 'День',
        'week': 'Тиждень',
        'month': 'Місяць',
        'no_appointments': 'На цей день записів немає',
        'add_title': 'Новий запис',
        'edit_title': 'Редагувати запис',
        'client_label': 'Клієнт',
        'client_hint': "Введіть ім'я клієнта",
        'client_error': "Вкажіть ім'я клієнта",
        'service_label': 'Послуга',
        'service_hint': 'Наприклад: Консультація',
        'date_label': 'Дата',
        'time_label': 'Час (24г)',
        'hour': 'Год',
        'minute': 'Хв',
        'repeat_until_end': 'Повторювати до кінця місяця',
        'repeat_days': 'Дні тижня для повтору',
        'status_label': 'Статус запису',
        'status_auto': 'Авто (Очікування)',
        'status_done': 'Виконано',
        'status_missed': 'Не виконано',
        'delete': 'Видалити',
        'cancel': 'Скасувати',
        'save': 'Зберегти',
        'create': 'Створити',
        'mon': 'Пн',
        'tue': 'Вт',
        'wed': 'Ср',
        'thu': 'Чт',
        'fri': 'Пт',
        'sat': 'Сб',
        'sun': 'Нд',
      },
      'en': {
        'app_title': 'Client Planner',
        'book': 'Book',
        'day': 'Day',
        'week': 'Week',
        'month': 'Month',
        'no_appointments': 'No appointments for this day',
        'add_title': 'New Appointment',
        'edit_title': 'Edit Appointment',
        'client_label': 'Client',
        'client_hint': 'Enter client name',
        'client_error': 'Please enter client name',
        'service_label': 'Service',
        'service_hint': 'e.g. Consultation',
        'date_label': 'Date',
        'time_label': 'Time (24h)',
        'hour': 'Hour',
        'minute': 'Min',
        'repeat_until_end': 'Repeat until end of month',
        'repeat_days': 'Repeat on weekdays',
        'status_label': 'Status',
        'status_auto': 'Auto (Pending)',
        'status_done': 'Completed',
        'status_missed': 'Missed',
        'delete': 'Delete',
        'cancel': 'Cancel',
        'save': 'Save',
        'create': 'Create',
        'mon': 'Mon',
        'tue': 'Tue',
        'wed': 'Wed',
        'thu': 'Thu',
        'fri': 'Fri',
        'sat': 'Sat',
        'sun': 'Sun',
      },
    };
    return dict[_languageCode]?[key] ?? dict['ru']![key]!;
  }

  void setLanguage(String code) {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    _syncWidget();
  }

  void cycleLanguage() {
    if (_languageCode == 'ru') {
      setLanguage('uk');
    } else if (_languageCode == 'uk') {
      setLanguage('en');
    } else {
      setLanguage('ru');
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    _syncWidget();
  }

  void setViewMode(PlannerViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void stepPeriod(int delta) {
    switch (_viewMode) {
      case PlannerViewMode.day:
        selectDate(_selectedDate.add(Duration(days: delta)));
        break;
      case PlannerViewMode.week:
        selectDate(_selectedDate.add(Duration(days: delta * 7)));
        break;
      case PlannerViewMode.month:
        final targetMonth = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
        final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
        final clampedDay = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
        selectDate(DateTime(targetMonth.year, targetMonth.month, clampedDay));
        break;
    }
  }

  List<Appointment> appointmentsForDay(DateTime day) {
    final norm = DateTime(day.year, day.month, day.day);
    final list = _appointments.where((a) => a.normalizedDate == norm).toList();
    list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }

  void addAppointment({
    required String clientName,
    required String serviceName,
    required DateTime date,
    required int startMinutes,
    int durationMinutes = 60,
    bool repeatUntilEndOfMonth = false,
    Set<int> repeatWeekdays = const {},
    bool? isCompleted,
  }) {
    final baseDate = DateTime(date.year, date.month, date.day);
    final List<DateTime> datesToCreate = [baseDate];

    if (repeatUntilEndOfMonth && repeatWeekdays.isNotEmpty) {
      final lastDayOfMonth = DateTime(baseDate.year, baseDate.month + 1, 0).day;
      for (int d = baseDate.day + 1; d <= lastDayOfMonth; d++) {
        final candidate = DateTime(baseDate.year, baseDate.month, d);
        if (repeatWeekdays.contains(candidate.weekday)) {
          datesToCreate.add(candidate);
        }
      }
    }

    for (int i = 0; i < datesToCreate.length; i++) {
      final itemDate = datesToCreate[i];
      _appointments.add(
        Appointment(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          clientName: clientName.trim(),
          serviceName: serviceName.trim(),
          date: itemDate,
          startMinutes: startMinutes,
          durationMinutes: durationMinutes,
          isCompleted: isCompleted,
        ),
      );
    }

    _selectedDate = baseDate;
    notifyListeners();
    _syncWidget();
  }

  void updateAppointment(Appointment updated) {
    final index = _appointments.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    _appointments[index] = updated.copyWith(
      date: DateTime(updated.date.year, updated.date.month, updated.date.day),
    );
    _selectedDate = _appointments[index].normalizedDate;
    notifyListeners();
    _syncWidget();
  }

  void toggleQuickStatus(String id, bool targetStatus) {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final current = _appointments[index];
    final bool? nextStatus = current.isCompleted == targetStatus ? null : targetStatus;
    _appointments[index] = current.copyWith(
      isCompleted: nextStatus,
      clearManualStatus: nextStatus == null,
    );
    notifyListeners();
    _syncWidget();
  }

  void deleteAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
    _syncWidget();
  }

  Future<void> _syncWidget() async {
    await WidgetSyncService.syncTodayAppointments(
      _appointments,
      _selectedDate,
      lang: _languageCode,
    );
  }
}
