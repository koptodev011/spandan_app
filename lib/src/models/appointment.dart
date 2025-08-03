import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String purpose;
  final String status;
  final String? notes;
  final DateTime? reminderTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.purpose,
    this.status = 'scheduled',
    this.notes,
    this.reminderTime,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? 'Unknown',
      dateTime: DateTime.parse(json['date_time']),
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'scheduled',
      notes: json['notes'],
      reminderTime: json['reminder_time'] != null ? DateTime.parse(json['reminder_time']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'date_time': dateTime.toIso8601String(),
      'purpose': purpose,
      'status': status,
      'notes': notes,
      'reminder_time': reminderTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    DateTime? dateTime,
    String? purpose,
    String? status,
    String? notes,
    DateTime? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      dateTime: dateTime ?? this.dateTime,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
