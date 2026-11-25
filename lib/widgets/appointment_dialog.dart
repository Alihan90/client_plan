import 'package:flutter/material.dart';
import '../models/appointment.dart';

class AppointmentFormResult {
  final String clientName;
  final String serviceNote;
  final DateTime date;
  final TimeOfDay time;
  final AppointmentStatus status;
  final List<DateTime> duplicateDates;

  AppointmentFormResult({
    required this.clientName,
    required this.serviceNote,
    required this.date,
    required this.time,
    required this.status,
    required this.duplicateDates,
  });
}

class AppointmentDialog extends StatefulWidget {
  final DateTime initialDate;
  final Appointment? existing;

  const AppointmentDialog({
    super.key,
    required this.initialDate,
    this.existing,
  });

  @override
  State<AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late AppointmentStatus _status;
  bool _repeatEnabled = false;
  final Set<int> _selectedWeekdays = {};

  static const Map<int, String> _weekdayLabels = {
    1: 'Пн',
    2: 'Вт',
    3: 'Ср',
    4: 'Чт',
    5: 'Пт',
    6: 'Сб',
    7: 'Вс',
  };

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.clientName ?? '');
    _noteController = TextEditingController(text: ex?.serviceNote ?? '');
    _selectedDate = ex?.normalizedDate ?? widget.initialDate;
    _selectedTime = ex != null
        ? TimeOfDay(
            hour: ex.startMinutes ~/ 60,
            minute: ex.startMinutes % 60,
          )
        : const TimeOfDay(hour: 10, minute: 0);
    _status = ex?.status ?? AppointmentStatus.waiting;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<DateTime> _buildDuplicateDates() {
    if (!_repeatEnabled || _selectedWeekdays.isEmpty) return const [];
    final result = <DateTime>[];
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    var cursor = _selectedDate.add(const Duration(days: 1));
    while (!cursor.isAfter(lastDayOfMonth)) {
      if (_selectedWeekdays.contains(cursor.weekday)) {
        result.add(DateTime(cursor.year, cursor.month, cursor.day));
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).pop(
      AppointmentFormResult(
        clientName: name,
        serviceNote: _noteController.text.trim(),
        date: _selectedDate,
        time: _selectedTime,
        status: _status,
        duplicateDates: widget.existing == null ? _buildDuplicateDates() : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'Редактировать запись' : 'Новая запись'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Клиент / пациент *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Услуга / заметка',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Статус записи:'),
            const SizedBox(height: 6),
            SegmentedButton<AppointmentStatus>(
              segments: const [
                ButtonSegment(
                  value: AppointmentStatus.waiting,
                  label: Text('Ожидание'),
                ),
                ButtonSegment(
                  value: AppointmentStatus.completed,
                  label: Text('Выполнено'),
                ),
                ButtonSegment(
                  value: AppointmentStatus.missed,
                  label: Text('Не выполнено'),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (set) => setState(() => _status = set.first),
            ),
            if (!isEditing) ...[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Повторить для постоянного клиента'),
                subtitle: const Text('Продублировать по выбранным дням до конца месяца'),
                value: _repeatEnabled,
                onChanged: (val) => setState(() => _repeatEnabled = val),
              ),
              if (_repeatEnabled)
                Wrap(
                  spacing: 6,
                  children: _weekdayLabels.entries.map((entry) {
                    final active = _selectedWeekdays.contains(entry.key);
                    return FilterChip(
                      label: Text(entry.value),
                      selected: active,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekdays.add(entry.key);
                          } else {
                            _selectedWeekdays.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
