import 'package:flutter/material.dart';

enum AppointmentType { inPerson, remote }
enum AppointmentStatus { scheduled, completed, cancelled, missed }

class Appointment {
  final String id;
  final String patientName;
  final DateTime date;
  final String time;
  final AppointmentType type;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.patientName,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
  });

  // Helper method to get status color
  static Color getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return const Color(0xFFFEF3C7); // Light yellow
      case AppointmentStatus.completed:
        return const Color(0xFFD1FAE5); // Light green
      case AppointmentStatus.cancelled:
      case AppointmentStatus.missed:
        return const Color(0xFFFEE2E2); // Light red
    }
  }

  // Helper method to get status text color
  static Color getStatusTextColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return const Color(0xFF92400E); // Dark yellow
      case AppointmentStatus.completed:
        return const Color(0xFF065F46); // Dark green
      case AppointmentStatus.cancelled:
      case AppointmentStatus.missed:
        return const Color(0xFFB91C1C); // Dark red
    }
  }

  // Mock data generator
  static List<Appointment> mockAppointments = [
    Appointment(
      id: '1',
      patientName: 'Sarah Johnson',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '10:00 AM',
      type: AppointmentType.remote,
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: '2',
      patientName: 'Michael Chen',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '2:00 PM',
      type: AppointmentType.inPerson,
      status: AppointmentStatus.scheduled,
    ),
    // Add more mock data as needed
  ];
}
