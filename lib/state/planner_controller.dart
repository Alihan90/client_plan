import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/widget_sync_service.dart';

enum CalendarViewMode { day, week, month }

class PlannerController extends ChangeNotifier {
  final List<Appointment> _appointments = [];
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.day;

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  DateTime get selectedDate =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  CalendarViewMode get viewMode => _viewMode;

  void setViewMode(CalendarViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _syncWidget();
    notifyListeners();
  }

  void goToToday() {
    selectDate(DateTime.now());
  }

  List<Appointment> appointmentsForDay(DateTime day) {
    final norm = DateTime(day.year, day.month, day.day);
    final list = _appointments.where((a) => a.normalizedDate == norm).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }

  Future<void> addAppointmentWithDuplicates({
    required String clientName,
    required String serviceNote,
    required DateTime date,
    required int startMinutes,
    List<DateTime> duplicateDates = const [],
  }) async {
    final baseId = DateTime.now().microsecondsSinceEpoch.toString();
    final allDates = <DateTime>{
      DateTime(date.year, date.month, date.day),
      ...duplicateDates.map((d) => DateTime(d.year, d.month, d.day)),
    };

    var index = 0;
    for (final d in allDates) {
      _appointments.add(
        Appointment(
          id: '${baseId}_$index',
          clientName: clientName.trim(),
          serviceNote: serviceNote.trim(),
          date: d,
          startMinutes: startMinutes,
          status: AppointmentStatus.waiting,
        ),
      );
      index++;
    }

    await _syncWidget();
    notifyListeners();
  }

  Future<void> updateAppointment(Appointment updated) async {
    final idx = _appointments.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _appointments[idx] = updated;
      await _syncWidget();
      notifyListeners();
    }
  }

  Future<void> setStatus(String id, AppointmentStatus status) async {
    final idx = _appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _appointments[idx] = _appointments[idx].copyWith(status: status);
      await _syncWidget();
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    await _syncWidget();
    notifyListeners();
  }

  Future<void> _syncWidget() async {
    try {
      await WidgetSyncService.syncTodayAppointments(_appointments, selectedDate);
    } catch (_) {}
  }
}
