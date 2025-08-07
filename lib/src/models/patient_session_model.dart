class PatientSession {
  final String id;
  final String patientId;
  final String sessionType;
  final int expectedDuration;
  final String purpose;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<dynamic> notes;
  final List<dynamic> medicines;

  PatientSession({
    required this.id,
    required this.patientId,
    required this.sessionType,
    required this.expectedDuration,
    required this.purpose,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.notes,
    required this.medicines,
  });

  factory PatientSession.fromJson(Map<String, dynamic> json) {
    return PatientSession(
      id: json['id'].toString(),
      patientId: json['patient_id'].toString(),
      sessionType: json['session_type'],
      expectedDuration: json['expected_duration'],
      purpose: json['purpose'],
      status: json['status'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      notes: json['notes'] ?? [],
      medicines: json['medicines'] ?? [],
    );
  }
}

class PatientSessionResponse {
  final List<PatientSession> sessions;
  final int currentPage;
  final int total;
  final int perPage;
  final int lastPage;

  PatientSessionResponse({
    required this.sessions,
    required this.currentPage,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  factory PatientSessionResponse.fromJson(Map<String, dynamic> json) {
    return PatientSessionResponse(
      sessions: (json['data']['data'] as List)
          .map((session) => PatientSession.fromJson(session))
          .toList(),
      currentPage: int.tryParse(json['data']['current_page'].toString()) ?? 1,
      total: int.tryParse(json['data']['total'].toString()) ?? 0,
      perPage: int.tryParse(json['data']['per_page'].toString()) ?? 10,
      lastPage: int.tryParse(json['data']['last_page'].toString()) ?? 1,
    );
  }
}
