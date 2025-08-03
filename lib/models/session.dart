import 'package:flutter/material.dart';

class Session {
  final String id;
  final String patientName;
  final String type;
  final DateTime dateTime;
  final int duration;
  final String status;
  final String? location;
  final String? notes;
  final List<SessionHistoryEntry>? history;

  Session({
    required this.id,
    required this.patientName,
    required this.type,
    required this.dateTime,
    required this.duration,
    required this.status,
    this.location,
    this.notes,
    this.history,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? 'Unknown',
      type: json['type'] ?? 'Regular',
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      duration: json['duration'] ?? 60,
      status: json['status']?.toLowerCase() ?? 'scheduled',
      location: json['location'],
      notes: json['notes'],
      history: json['history'] != null
          ? List<SessionHistoryEntry>.from(
              json['history'].map((x) => SessionHistoryEntry.fromJson(x)))
          : null,
    );
  }
}

class SessionHistoryEntry {
  final String action;
  final DateTime timestamp;

  SessionHistoryEntry({
    required this.action,
    required this.timestamp,
  });

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SessionHistoryEntry(
      action: json['action'] ?? 'Updated',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
