class PatientHistoryResponse {
  final String status;
  final PatientHistoryData data;

  PatientHistoryResponse({
    required this.status,
    required this.data,
  });

  factory PatientHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PatientHistoryResponse(
      status: json['status'],
      data: PatientHistoryData.fromJson(json['data']),
    );
  }
}

class PatientHistoryData {
  final Patient patient;
  final Statistics statistics;
  final List<SessionHistory> sessionHistory;

  PatientHistoryData({
    required this.patient,
    required this.statistics,
    required this.sessionHistory,
  });

  factory PatientHistoryData.fromJson(Map<String, dynamic> json) {
    return PatientHistoryData(
      patient: Patient.fromJson(json['patient']),
      statistics: Statistics.fromJson(json['statistics']),
      sessionHistory: (json['session_history'] as List)
          .map((e) => SessionHistory.fromJson(e))
          .toList(),
    );
  }
}

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String email;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'].toString(),
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class Statistics {
  final int totalSessions;
  final String totalDuration;
  final String averageMood;

  Statistics({
    required this.totalSessions,
    required this.totalDuration,
    required this.averageMood,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalSessions: json['total_sessions'] ?? 0,
      totalDuration: json['total_duration'] ?? '0 mins',
      averageMood: json['average_mood'] ?? 'N/A',
    );
  }
}

class SessionHistory {
  final String id;
  final String date;
  final String time;
  final String duration;
  final String type;
  final String status;
  final String? notes;
  final String? sessionNotes;
  final dynamic mood;

  SessionHistory({
    required this.id,
    required this.date,
    required this.time,
    required this.duration,
    required this.type,
    required this.status,
    this.notes,
    this.sessionNotes,
    this.mood,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'].toString(),
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      duration: _parseDuration(json['duration']),
      type: json['type'] ?? '',
      status: json['status'] ?? 'completed',
      notes: json['notes']?.toString(),
      sessionNotes: json['session_notes']?.toString(),
      mood: json['mood'],
    );
  }

  static String _parseDuration(dynamic duration) {
    if (duration == null) return '0 mins';
    if (duration is String) return duration;
    if (duration is int) return '$duration mins';
    if (duration is double) return '${duration.toStringAsFixed(0)} mins';
    return duration.toString();
  }
}
