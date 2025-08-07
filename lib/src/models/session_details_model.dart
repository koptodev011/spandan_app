class SessionDetailsResponse {
  final bool status;
  final SessionDetailsData data;

  SessionDetailsResponse({
    required this.status,
    required this.data,
  });

  factory SessionDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SessionDetailsResponse(
      status: json['status'] == 'success',
      data: SessionDetailsData.fromJson(json['data']),
    );
  }
}

class SessionDetailsData {
  final int id;
  final Patient patient;
  final SessionDetails sessionDetails;
  final List<Note> notes;
  final List<Medicine> medicines;

  SessionDetailsData({
    required this.id,
    required this.patient,
    required this.sessionDetails,
    required this.notes,
    required this.medicines,
  });

  factory SessionDetailsData.fromJson(Map<String, dynamic> json) {
    return SessionDetailsData(
      id: json['id'],
      patient: Patient.fromJson(json['patient']),
      sessionDetails: SessionDetails.fromJson(json['session_details']),
      notes: (json['notes'] as List)
          .map((noteJson) => Note.fromJson(noteJson))
          .toList(),
      medicines: (json['medicines'] as List)
          .map((medJson) => Medicine.fromJson(medJson))
          .toList(),
    );
  }
}

class Patient {
  final int id;
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
      id: json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
    );
  }
}

class SessionDetails {
  final String type;
  final String status;
  final String startedAt;
  final String endedAt;
  final String expectedDuration;
  final String purpose;
  final String createdAt;
  final String updatedAt;

  SessionDetails({
    required this.type,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.expectedDuration,
    required this.purpose,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionDetails.fromJson(Map<String, dynamic> json) {
    return SessionDetails(
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      startedAt: json['started_at'] ?? '',
      endedAt: json['ended_at'] ?? '',
      expectedDuration: json['expected_duration'] ?? '',
      purpose: json['purpose'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Note {
  final int id;
  final String? generalNotes;
  final String? physicalHealthNotes;
  final String? mentalHealthNotes;
  final String? clinicalNotes;
  final int? moodRating;
  final String? voiceNotesPath;
  final String createdAt;
  final String updatedAt;

  Note({
    required this.id,
    this.generalNotes,
    this.physicalHealthNotes,
    this.mentalHealthNotes,
    this.clinicalNotes,
    this.moodRating,
    this.voiceNotesPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      generalNotes: json['general_notes'],
      physicalHealthNotes: json['physical_health_notes'],
      mentalHealthNotes: json['mental_health_notes'],
      clinicalNotes: json['clinical_notes'],
      moodRating: json['mood_rating'],
      voiceNotesPath: json['voice_notes_path'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Medicine {
  final int id;
  final String medicineNotes;
  final List<dynamic> images;
  final String createdAt;
  final String updatedAt;

  Medicine({
    required this.id,
    required this.medicineNotes,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      medicineNotes: json['medicine_notes'] ?? '',
      images: json['images'] ?? [],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
