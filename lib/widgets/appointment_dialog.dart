import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../state/planner_controller.dart';

class AppointmentDialog extends StatefulWidget {
  final PlannerController controller;
  final Appointment? existing;
  final DateTime initialDate;

  const AppointmentDialog({
    super.key,
    required this.controller,
    this.existing,
    required this.initialDate,
  });

  @override
  State<AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clientCtrl;
  late final TextEditingController _serviceCtrl;
  late final FocusNode _clientFocusNode;

  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;
  late int _durationMinutes;
  bool _repeatUntilEndOfMonth = false;
  final Set<int> _repeatWeekdays = {};
  bool? _manualStatus;

  static const List<int> _minuteSteps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
  static const List<int> _durationOptions = [30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _clientCtrl = TextEditingController(text: ex?.clientName ?? '');
    _serviceCtrl = TextEditingController(text: ex?.serviceName ?? '');
    _clientFocusNode = FocusNode();

    _selectedDate = ex?.normalizedDate ??
        DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);

    final startMins = ex?.startMinutes ?? (9 * 60);
    _selectedHour = (startMins ~/ 60).clamp(0, 23);
    final rawMinute = startMins % 60;
    _selectedMinute = _minuteSteps.reduce(
      (a, b) => (a - rawMinute).abs() < (b - rawMinute).abs() ? a : b,
    );

    _durationMinutes = ex?.durationMinutes ?? 60;
    if (!_durationOptions.contains(_durationMinutes)) {
      _durationMinutes = 60;
    }

    _repeatWeekdays.add(_selectedDate.weekday);
    _manualStatus = ex?.isCompleted;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_clientFocusNode.hasFocus) {
          _clientFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _clientFocusNode.dispose();
    _clientCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      locale: widget.controller.locale,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        if (_repeatWeekdays.isEmpty) {
          _repeatWeekdays.add(_selectedDate.weekday);
        }
      });
    }
  }

  void _setQuickTime(int hour, int minute) {
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final startMinutes = _selectedHour * 60 + _selectedMinute;

    if (widget.existing != null) {
      widget.controller.updateAppointment(
        widget.existing!.copyWith(
          clientName: _clientCtrl.text,
          serviceName: _serviceCtrl.text,
          date: _selectedDate,
          startMinutes: startMinutes,
          durationMinutes: _durationMinutes,
          isCompleted: _manualStatus,
          clearManualStatus: _manualStatus == null,
        ),
      );
    } else {
      widget.controller.addAppointment(
        clientName: _clientCtrl.text,
        serviceName: _serviceCtrl.text,
        date: _selectedDate,
        startMinutes: startMinutes,
        durationMinutes: _durationMinutes,
        repeatUntilEndOfMonth: _repeatUntilEndOfMonth,
        repeatWeekdays: _repeatWeekdays,
        isCompleted: _manualStatus,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final dateText = DateFormat('dd.MM.yyyy', c.locale.toString()).format(_selectedDate);
    final weekdayChips = [
      (DateTime.monday, c.tr('mon')),
      (DateTime.tuesday, c.tr('tue')),
      (DateTime.wednesday, c.tr('wed')),
      (DateTime.thursday, c.tr('thu')),
      (DateTime.friday, c.tr('fri')),
      (DateTime.saturday, c.tr('sat')),
      (DateTime.sunday, c.tr('sun')),
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.existing == null ? c.tr('add_title') : c.tr('edit_title'),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _clientCtrl,
                focusNode: _clientFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: c.tr('client_label'),
                  hintText: c.tr('client_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? c.tr('client_error') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serviceCtrl,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: c.tr('service_label'),
                  hintText: c.tr('service_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text('${c.tr('date_label')}: $dateText'),
              ),
              const SizedBox(height: 14),
              Text(
                c.tr('time_label'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedHour,
                      decoration: InputDecoration(
                        labelText: c.tr('hour'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: List.generate(24, (h) => h)
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(h.toString().padLeft(2, '0')),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedHour = val);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMinute,
                      decoration: InputDecoration(
                        labelText: c.tr('minute'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _minuteSteps
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.toString().padLeft(2, '0')),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMinute = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final slot in [(9, 0), (12, 0), (15, 0), (18, 0)])
                    ActionChip(
                      label: Text(
                        '${slot.$1.toString().padLeft(2, '0')}:${slot.$2.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _setQuickTime(slot.$1, slot.$2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                c.tr('duration_label'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _durationOptions.map((mins) {
                  final selected = _durationMinutes == mins;
                  return ChoiceChip(
                    label: Text('$mins ${c.tr('minutes_short')}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _durationMinutes = mins),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                c.tr('status_label'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<bool?>(
                value: _manualStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(c.tr('status_auto'))),
                  DropdownMenuItem(value: true, child: Text(c.tr('status_done'))),
                  DropdownMenuItem(value: false, child: Text(c.tr('status_missed'))),
                ],
                onChanged: (val) => setState(() => _manualStatus = val),
              ),
              if (widget.existing == null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    c.tr('repeat_until_end'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _repeatUntilEndOfMonth,
                  onChanged: (val) => setState(() => _repeatUntilEndOfMonth = val),
                ),
                if (_repeatUntilEndOfMonth) ...[
                  Text(
                    c.tr('repeat_days'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: weekdayChips.map((d) {
                      final selected = _repeatWeekdays.contains(d.$1);
                      return FilterChip(
                        label: Text(d.$2),
                        selected: selected,
                        onSelected: (on) {
                          setState(() {
                            if (on) {
                              _repeatWeekdays.add(d.$1);
                            } else {
                              _repeatWeekdays.remove(d.$1);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () {
              widget.controller.deleteAppointment(widget.existing!.id);
              Navigator.of(context).pop();
            },
            child: Text(
              c.tr('delete'),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(c.tr('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.existing == null ? c.tr('create') : c.tr('save')),
        ),
      ],
    );
  }
}
