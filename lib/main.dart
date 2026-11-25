import 'package:flutter/material.dart';
import 'models/appointment.dart';
import 'state/planner_controller.dart';
import 'widgets/appointment_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClientPlannerApp());
}

class ClientPlannerApp extends StatelessWidget {
  const ClientPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Планер записей',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const PlannerHomeScreen(),
    );
  }
}

class PlannerHomeScreen extends StatefulWidget {
  const PlannerHomeScreen({super.key});

  @override
  State<PlannerHomeScreen> createState() => _PlannerHomeScreenState();
}

class _PlannerHomeScreenState extends State<PlannerHomeScreen> {
  final PlannerController _controller = PlannerController();

  static const List<String> _weekDaysHeader = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  static const List<String> _monthsRu = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_controller.viewMode == CalendarViewMode.day) {
      _controller.setViewMode(CalendarViewMode.week);
    } else if (_controller.viewMode == CalendarViewMode.week) {
      _controller.setViewMode(CalendarViewMode.month);
    } else {
      _controller.goToToday();
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<AppointmentFormResult>(
      context: context,
      builder: (_) => AppointmentDialog(initialDate: _controller.selectedDate),
    );
    if (result == null) return;

    await _controller.addAppointmentWithDuplicates(
      clientName: result.clientName,
      serviceNote: result.serviceNote,
      date: result.date,
      startMinutes: result.time.hour * 60 + result.time.minute,
      duplicateDates: result.duplicateDates,
    );
  }

  Future<void> _openEditDialog(Appointment item) async {
    final result = await showDialog<AppointmentFormResult>(
      context: context,
      builder: (_) => AppointmentDialog(
        initialDate: item.normalizedDate,
        existing: item,
      ),
    );
    if (result == null) return;

    await _controller.updateAppointment(
      item.copyWith(
        clientName: result.clientName,
        serviceNote: result.serviceNote,
        date: result.date,
        startMinutes: result.time.hour * 60 + result.time.minute,
        status: result.status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final d = _controller.selectedDate;
        final title = '${_monthsRu[d.month - 1]} ${d.year}';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Назад',
              onPressed: _handleBack,
            ),
            title: Text(title),
            actions: [
              TextButton(
                onPressed: _controller.goToToday,
                child: const Text('Сегодня'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Записать'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SegmentedButton<CalendarViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarViewMode.day,
                      label: Text('День'),
                    ),
                    ButtonSegment(
                      value: CalendarViewMode.week,
                      label: Text('Неделя'),
                    ),
                    ButtonSegment(
                      value: CalendarViewMode.month,
                      label: Text('Месяц'),
                    ),
                  ],
                  selected: {_controller.viewMode},
                  onSelectionChanged: (set) {
                    _controller.setViewMode(set.first);
                  },
                ),
              ),
              const _WeekdaysHeader(labels: _weekDaysHeader),
              const Divider(height: 1),
              Expanded(child: _buildModeBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeBody() {
    switch (_controller.viewMode) {
      case CalendarViewMode.day:
        return _DayScheduleList(
          date: _controller.selectedDate,
          items: _controller.appointmentsForDay(_controller.selectedDate),
          onEdit: _openEditDialog,
          onStatusChange: (id, status) => _controller.setStatus(id, status),
          onDelete: (id) => _controller.deleteAppointment(id),
        );
      case CalendarViewMode.week:
        return _WeekStripAndList(
          controller: _controller,
          onEdit: _openEditDialog,
          onStatusChange: (id, status) => _controller.setStatus(id, status),
          onDelete: (id) => _controller.deleteAppointment(id),
        );
      case CalendarViewMode.month:
        return _MonthGridView(
          controller: _controller,
          onDaySelected: (day) {
            _controller.selectDate(day);
            _controller.setViewMode(CalendarViewMode.day);
          },
        );
    }
  }
}

class _WeekdaysHeader extends StatelessWidget {
  final List<String> labels;
  const _WeekdaysHeader({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (day) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DayScheduleList extends StatelessWidget {
  final DateTime date;
  final List<Appointment> items;
  final void Function(Appointment) onEdit;
  final void Function(String, AppointmentStatus) onStatusChange;
  final void Function(String) onDelete;

  const _DayScheduleList({
    required this.date,
    required this.items,
    required this.onEdit,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Записи за $dateLabel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (items.isEmpty)
          const Expanded(
            child: Center(child: Text('На этот день записей нет')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bg = item.cardColor(context, now);
                final accent = item.accentColor(now);

                return Card(
                  color: bg,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.formattedTime,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: accent,
                            ),
                          ),
                          Text(
                            item.statusLabel(now),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      item.clientName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: item.serviceNote.isEmpty
                        ? null
                        : Text(item.serviceNote),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Отметить как выполнено',
                          icon: Icon(
                            Icons.check_circle,
                            color: item.status == AppointmentStatus.completed
                                ? Colors.green.shade800
                                : Colors.green.shade600,
                          ),
                          onPressed: () => onStatusChange(
                            item.id,
                            item.status == AppointmentStatus.completed
                                ? AppointmentStatus.waiting
                                : AppointmentStatus.completed,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Отметить как не выполнено',
                          icon: Icon(
                            Icons.cancel,
                            color: item.status == AppointmentStatus.missed
                                ? Colors.red.shade800
                                : Colors.red.shade600,
                          ),
                          onPressed: () => onStatusChange(
                            item.id,
                            item.status == AppointmentStatus.missed
                                ? AppointmentStatus.waiting
                                : AppointmentStatus.missed,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Редактировать',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(item),
                        ),
                        IconButton(
                          tooltip: 'Удалить',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDelete(item.id),
                        ),
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

class _WeekStripAndList extends StatelessWidget {
  final PlannerController controller;
  final void Function(Appointment) onEdit;
  final void Function(String, AppointmentStatus) onStatusChange;
  final void Function(String) onDelete;

  const _WeekStripAndList({
    required this.controller,
    required this.onEdit,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sel = controller.selectedDate;
    final monday = sel.subtract(Duration(days: sel.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Column(
      children: [
        Row(
          children: weekDays.map((day) {
            final isSelected = day.year == sel.year &&
                day.month == sel.month &&
                day.day == sel.day;
            final count = controller.appointmentsForDay(day).length;

            return Expanded(
              child: InkWell(
                onTap: () => controller.selectDate(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('${day.day}'),
                      const SizedBox(height: 4),
                      if (count > 0)
                        CircleAvatar(
                          radius: 9,
                          child: Text(
                            '$count',
                            style: const TextStyle(fontSize: 11),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 1),
        Expanded(
          child: _DayScheduleList(
            date: sel,
            items: controller.appointmentsForDay(sel),
            onEdit: onEdit,
            onStatusChange: onStatusChange,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }
}

class _MonthGridView extends StatelessWidget {
  final PlannerController controller;
  final void Function(DateTime) onDaySelected;

  const _MonthGridView({
    required this.controller,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final sel = controller.selectedDate;
    final firstOfMonth = DateTime(sel.year, sel.month, 1);
    final daysInMonth = DateTime(sel.year, sel.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingBlanks) {
          return const SizedBox.shrink();
        }
        final dayNum = index - leadingBlanks + 1;
        final date = DateTime(sel.year, sel.month, dayNum);
        final count = controller.appointmentsForDay(date).length;
        final isSelected = date.year == sel.year &&
            date.month == sel.month &&
            date.day == sel.day;

        return InkWell(
          onTap: () => onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 11),
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
