import 'package:flutter/material.dart';

enum AppointmentStatus {
  waiting,   // Ожидание (серый)
  completed, // Выполнено (зеленый)
  missed,    // Не выполнено (красный)
}

class Appointment {
  final String id;
  final String clientName;
  final String serviceNote;
  final DateTime date; // Дата без времени (YYYY-MM-DD)
  final int startMinutes; // Минуты от начала дня, например 9:30 -> 570
  final int durationMinutes;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.serviceNote,
    required this.date,
    required this.startMinutes,
    this.durationMinutes = 60,
    this.status = AppointmentStatus.waiting,
  });

  DateTime get normalizedDate => DateTime(date.year, date.month, date.day);

  DateTime get scheduledDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        startMinutes ~/ 60,
        startMinutes % 60,
      );

  String get formattedTime {
    final h = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (startMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color cardColor(BuildContext context, DateTime now) {
    switch (status) {
      case AppointmentStatus.completed:
        return Colors.green.shade100;
      case AppointmentStatus.missed:
        return Colors.red.shade100;
      case AppointmentStatus.waiting:
        return now.isBefore(scheduledDateTime)
            ? Colors.grey.shade200
            : Colors.grey.shade300;
    }
  }

  Color accentColor(DateTime now) {
    switch (status) {
      case AppointmentStatus.completed:
        return Colors.green.shade700;
      case AppointmentStatus.missed:
        return Colors.red.shade700;
      case AppointmentStatus.waiting:
        return now.isBefore(scheduledDateTime)
            ? Colors.grey.shade600
            : Colors.grey.shade700;
    }
  }

  String statusLabel(DateTime now) {
    switch (status) {
      case AppointmentStatus.completed:
        return 'Выполнено';
      case AppointmentStatus.missed:
        return 'Не выполнено';
      case AppointmentStatus.waiting:
        return now.isBefore(scheduledDateTime) ? 'Ожидание' : 'Время пришло';
    }
  }

  Appointment copyWith({
    String? id,
    String? clientName,
    String? serviceNote,
    DateTime? date,
    int? startMinutes,
    int? durationMinutes,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      serviceNote: serviceNote ?? this.serviceNote,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'serviceNote': serviceNote,
        'date': normalizedDate.toIso8601String(),
        'startMinutes': startMinutes,
        'durationMinutes': durationMinutes,
        'status': status.name,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        serviceNote: json['serviceNote'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        startMinutes: json['startMinutes'] as int,
        durationMinutes: json['durationMinutes'] as int? ?? 60,
        status: AppointmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AppointmentStatus.waiting,
        ),
      );
}
