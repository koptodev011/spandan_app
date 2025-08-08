import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'session_details_screen.dart';

class StartSessionScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic>? appointment;
  final VoidCallback onBack;
  final Function(dynamic) onStartSession;

  const StartSessionScreen({
    Key? key,
    required this.patient,
    required this.onBack,
    required this.onStartSession,
    this.appointment,
  }) : super(key: key);

  @override
  State<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends State<StartSessionScreen> {
  String _sessionType = 'in-person';
  String _sessionDuration = '60';
  String _sessionPurpose = '';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _purposeOptions = [
    {'value': 'initial-consultation', 'label': 'Initial Consultation'},
    {'value': 'follow-up', 'label': 'Follow-up Session'},
    {'value': 'therapy', 'label': 'Therapy Session'},
    {'value': 'medication-review', 'label': 'Medication Review'},
    {'value': 'crisis-intervention', 'label': 'Crisis Intervention'},
    {'value': 'assessment', 'label': 'Assessment'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize form fields with appointment data if available
    if (widget.appointment != null) {
      // Set session type (convert from snake_case to kebab-case if needed)
      _sessionType = (widget.appointment!['appointment_type'] ?? 'in-person')
          .toString()
          .replaceAll('_', '-');
          
      // Set session duration
      _sessionDuration = widget.appointment!['duration_minutes']?.toString() ?? '60';
      
      // Set session purpose from appointment data
      if (widget.appointment!['session_purpose'] != null) {
        _sessionPurpose = widget.appointment!['session_purpose'].toString();
      } else {
        // Fallback to note if session_purpose is not available
        final note = widget.appointment!['note']?.toString() ?? '';
        final matchingPurpose = _purposeOptions.firstWhere(
          (option) => option['value'] == note || option['label'] == note,
          orElse: () => {'value': 'other', 'label': 'Other'},
        );
        _sessionPurpose = matchingPurpose['value'] as String;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Patient Info Card
              _buildPatientInfoCard(),
              const SizedBox(height: 24),
              
              // Session Configuration Card
              _buildSessionConfigCard(),
              const SizedBox(height: 24),
              
              // Session Info Card
              _buildSessionInfoCard(),
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          label: Text(
            'Back to Patients',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start New Session',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          'Configure session settings',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 24, color: Color(0xFF58C0F4)),
                const SizedBox(width: 8),
                Text(
                  'Patient Information',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Display patient image if available, otherwise show default avatar
                widget.patient['imageUrl'] != null && widget.patient['imageUrl'].isNotEmpty
                    ? Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(32),
                          image: DecorationImage(
                            image: NetworkImage(widget.patient['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          widget.patient['gender']?.toLowerCase() == 'female' 
                              ? Icons.female 
                              : Icons.male,
                          size: 32,
                          color: const Color(0xFF58C0F4),
                        ),
                      ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient['name'] ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.patient['age'] ?? ''} years • ${widget.patient['gender'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionConfigCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Details Section
            if (widget.appointment != null) ..._buildAppointmentDetails(),
            
            if (widget.appointment != null) const SizedBox(height: 24),
            
            // Session Type
            _buildSectionHeader('Session Type *', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildSessionTypeSelector(),
            const SizedBox(height: 24),
            
            // Session Duration
            _buildSectionHeader('Expected Duration', Icons.timer),
            const SizedBox(height: 12),
            _buildDurationDropdown(),
            const SizedBox(height: 24),
            
            // Session Purpose
            _buildSectionHeader('Session Purpose', Icons.notes),
            const SizedBox(height: 12),
            _buildPurposeDropdown(),
            const SizedBox(height: 16),
            
            // Remote Session Note
            if (_sessionType == 'remote') _buildRemoteSessionNote(),
          ],
        ),
      ),
    );
  }
  
  // Build the appointment details section
  List<Widget> _buildAppointmentDetails() {
    final appointment = widget.appointment!;
    DateTime? appointmentTime;
    
    try {
      if (appointment['time'] != null) {
        appointmentTime = DateTime.parse(appointment['time']);
      }
    } catch (e) {
      debugPrint('Error parsing appointment time: $e');
    }
    
    return [
      // Section Header
      Row(
        children: [
          const Icon(Icons.event_available, size: 24, color: Color(0xFF58C0F4)),
          const SizedBox(width: 8),
          Text(
            'Appointment Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Appointment Date & Time
      if (appointmentTime != null) ...[
        _buildDetailRow(
          'Date', 
          DateFormat('EEEE, MMMM d, y').format(appointmentTime),
          Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          'Time', 
          DateFormat('h:mm a').format(appointmentTime),
          Icons.access_time,
        ),
      ],
      
      // Appointment Type
      if (appointment['appointment_type'] != null) ...[
        const SizedBox(height: 8),
        _buildDetailRow(
          'Type', 
          '${appointment['appointment_type'].toString().split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ')}',
          Icons.category,
        ),
      ],
      
      // Session Purpose
      if (appointment['session_purpose'] != null) ...[
        const SizedBox(height: 8),
        _buildDetailRow(
          'Session Purpose',
          _purposeOptions.firstWhere(
            (option) => option['value'] == appointment['session_purpose'],
            orElse: () => {'label': 'Other'},
          )['label'],
          Icons.assignment,
        ),
      ],
      
      // Duration
      if (appointment['duration_minutes'] != null) ...[
        const SizedBox(height: 8),
        _buildDetailRow(
          'Duration', 
          '${appointment['duration_minutes']} minutes',
          Icons.timer,
        ),
      ],
      
      // Notes
      if (appointment['note'] != null && appointment['note'].toString().isNotEmpty) ...[
        const SizedBox(height: 8),
        _buildDetailRow(
          'Notes', 
          appointment['note'].toString(),
          Icons.notes,
          maxLines: 3,
        ),
      ],
      
      // Status
      if (appointment['status'] != null) ...[
        const SizedBox(height: 8),
        _buildStatusChip(appointment['status']),
      ],
    ];
  }
  
  // Build a detail row with icon and text
  Widget _buildDetailRow(String label, String value, IconData icon, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build a status chip
  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayStatus = status.replaceAll('_', ' ').toLowerCase();
    displayStatus = displayStatus[0].toUpperCase() + displayStatus.substring(1);
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'completed':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case 'pending':
      default:
        backgroundColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF58C0F4)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionTypeSelector() {
    return Column(
      children: [
        // In-Person Option
        _buildSessionTypeOption(
          value: 'in-person',
          title: 'In-Person Session',
          description: 'Face-to-face consultation at clinic',
          icon: Icons.location_on,
          isSelected: _sessionType == 'in-person',
        ),
        const SizedBox(height: 12),
        // Remote Option
        _buildSessionTypeOption(
          value: 'remote',
          title: 'Remote Session',
          description: 'Online video consultation',
          icon: Icons.videocam,
          isSelected: _sessionType == 'remote',
        ),
      ],
    );
  }

  Widget _buildSessionTypeOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _sessionType = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EAF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF58C0F4) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF58C0F4) : const Color(0xFF9E9E9E),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 12, color: Color(0xFF58C0F4))
                  : null,
            ),
            const SizedBox(width: 16),
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF58C0F4) : const Color(0xFF9E9E9E),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    final durationOptions = [
      {'value': '30', 'label': '30 minutes'},
      {'value': '45', 'label': '45 minutes'},
      {'value': '60', 'label': '60 minutes'},
      {'value': '90', 'label': '90 minutes'},
      {'value': '120', 'label': '2 hours'},
    ];

    return DropdownButtonFormField<String>(
      value: _sessionDuration,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
      items: durationOptions.map<DropdownMenuItem<String>>((option) {
        return DropdownMenuItem<String>(
          value: option['value'] as String,
          child: Text(
            option['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _sessionDuration = value;
          });
        }
      },
    );
  }

  Widget _buildPurposeDropdown() {
    return DropdownButtonFormField<String>(
      value: _sessionPurpose.isEmpty ? null : _sessionPurpose,
      decoration: InputDecoration(
        hintText: 'Select session purpose',
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9E9E9E),
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
      items: _purposeOptions.map<DropdownMenuItem<String>>((option) {
        return DropdownMenuItem<String>(
          value: option['value'] as String,
          child: Text(
            option['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _sessionPurpose = value;
          });
        }
      },
    );
  }

  Widget _buildRemoteSessionNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.videocam, size: 20, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remote Session Features',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem('Upload and send prescription images directly to patient'),
                    _buildFeatureItem('Voice notes will be transcribed automatically'),
                    _buildFeatureItem('All session notes will be saved digitally'),
                    _buildFeatureItem('Medicine tracker will be activated for follow-up'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF0D47A1))),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF0D47A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    final now = DateTime.now();
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 24, color: Color(0xFF5C6BC0)),
                const SizedBox(width: 12),
                Text(
                  'Session will start at:',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(now),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  dateFormat.format(now),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to create a new session via API
  Future<void> _createSession() async {
    print('_createSession called');
    
    if (_sessionPurpose.isEmpty) {
      print('Error: Session purpose is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a session purpose'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Getting auth token...');
      // Get the authentication token using AuthService
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('Error: No auth token found');
        throw Exception('Please login again to continue');
      }

      final url = Uri.parse('https://spandan.koptotech.solutions/api/sessions');
      print('API URL: $url');
      
      // Convert session type from kebab-case to snake_case
      final sessionType = _sessionType.replaceAll('-', '_');
      print('Session type: $sessionType');
      
      // Debug print to check patient data
      print('Patient data: ${widget.patient}');
      
      // Prepare the request body with proper types
      final patientId = int.tryParse((widget.patient['id'] ?? widget.patient['patient_id'])?.toString() ?? '0') ?? 0;
      print('Patient ID: $patientId');
      
      if (patientId == 0) {
        print('Error: Invalid patient ID');
        throw Exception('Patient ID is missing or invalid');
      }

      final requestBody = {
        'patient_id': patientId,
        'session_type': sessionType,
        'expected_duration': int.tryParse(_sessionDuration) ?? 60,
        'purpose': _sessionPurpose,
      };
      
      print('Request body: $requestBody');

      print('Sending request to: $url');
      print('Request headers: ${{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }}');
      print('Request body: $requestBody');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Session created successfully
        if (mounted) {
          final responseData = jsonDecode(response.body);
          final sessionData = responseData is Map && responseData.containsKey('data') 
              ? responseData['data'] 
              : responseData;
          
          // Navigate to SessionDetailsScreen with the created session data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailsScreen(
                patient: {
                  ...widget.patient,
                  'session_id': sessionData['id'] ?? sessionData['session_id'],
                  'session_type': _sessionType,
                  'start_time': DateTime.now().toIso8601String(),
                },
                onBack: widget.onBack,
              ),
            ),
          );
          
          // Also notify parent if needed
          if (widget.onStartSession != null) {
            widget.onStartSession(sessionData);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Handle API error
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to create session';
        
        if (errorData is Map) {
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData.containsKey('errors')) {
            // Handle validation errors
            final errors = errorData['errors'] as Map<String, dynamic>;
            errorMessage = errors.entries
                .map((e) => '${e.key}: ${e.value.join(', ')}')
                .join('\n');
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow; // Re-throw to see the full error in the console
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : widget.onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF58C0F4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Color(0xFF58C0F4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Start Session Button
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58C0F4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Start Session',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}