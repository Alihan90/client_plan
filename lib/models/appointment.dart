class Appointment {
  final String id;
  final String clientName;
  final String serviceName;
  final DateTime date;
  final int startMinutes;
  final int durationMinutes;
  final bool? isCompleted;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.date,
    required this.startMinutes,
    this.durationMinutes = 60,
    this.isCompleted,
  });

  DateTime get normalizedDate => DateTime(date.year, date.month, date.day);

  int get endMinutes => startMinutes + durationMinutes;

  String get formattedTime {
    final h = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (startMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'serviceName': serviceName,
      'year': normalizedDate.year,
      'month': normalizedDate.month,
      'day': normalizedDate.day,
      'startMinutes': startMinutes,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      clientName: json['clientName'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      date: DateTime(
        json['year'] as int,
        json['month'] as int,
        json['day'] as int,
      ),
      startMinutes: json['startMinutes'] as int? ?? 540,
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      isCompleted: json['isCompleted'] as bool?,
    );
  }

  String statusLabel(DateTime now, {String lang = 'ru'}) {
    if (isCompleted == true) {
      switch (lang) {
        case 'uk':
          return 'Виконано';
        case 'en':
          return 'Completed';
        default:
          return 'Выполнено';
      }
    }
    if (isCompleted == false) {
      switch (lang) {
        case 'uk':
          return 'Не виконано';
        case 'en':
          return 'Missed';
        default:
          return 'Не выполнено';
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final nowMinutes = now.hour * 60 + now.minute;

    if (normalizedDate.isBefore(today) ||
        (normalizedDate == today && endMinutes < nowMinutes)) {
      switch (lang) {
        case 'uk':
          return 'Не виконано';
        case 'en':
          return 'Missed';
        default:
          return 'Не выполнено';
      }
    }

    switch (lang) {
      case 'uk':
        return 'Очікування';
      case 'en':
        return 'Pending';
      default:
        return 'Ожидание';
    }
  }

  Appointment copyWith({
    String? id,
    String? clientName,
    String? serviceName,
    DateTime? date,
    int? startMinutes,
    int? durationMinutes,
    bool? isCompleted,
    bool clearManualStatus = false,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      serviceName: serviceName ?? this.serviceName,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: clearManualStatus ? null : (isCompleted ?? this.isCompleted),
    );
  }
}
