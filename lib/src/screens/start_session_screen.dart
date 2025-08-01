import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class StartSessionScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onBack;
  final Function(dynamic) onStartSession;

  const StartSessionScreen({
    Key? key,
    required this.patient,
    required this.onBack,
    required this.onStartSession,
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          label: Text(
            'Back to Patients',
            style: GoogleFonts.inter(
              color: const Color(0xFF1A237E),
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
                const Icon(Icons.person_outline, size: 24, color: Color(0xFF5C6BC0)),
                const SizedBox(width: 8),
                Text(
                  'Patient Information',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: Color(0xFF5C6BC0),
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
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.patient['age'] ?? ''} years • ${widget.patient['gender'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF5C6BC0),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5C6BC0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
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
            color: isSelected ? const Color(0xFF5C6BC0) : const Color(0xFFE0E0E0),
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
                  color: isSelected ? const Color(0xFF5C6BC0) : const Color(0xFF9E9E9E),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 12, color: Color(0xFF5C6BC0))
                  : null,
            ),
            const SizedBox(width: 16),
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF5C6BC0) : const Color(0xFF9E9E9E),
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
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF5C6BC0),
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
          borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
        ),
      ),
      items: durationOptions.map<DropdownMenuItem<String>>((option) {
        return DropdownMenuItem<String>(
          value: option['value'] as String,
          child: Text(
            option['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF1A237E),
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
          borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
        ),
      ),
      items: _purposeOptions.map<DropdownMenuItem<String>>((option) {
        return DropdownMenuItem<String>(
          value: option['value'] as String,
          child: Text(
            option['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF1A237E),
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
                    color: const Color(0xFF1A237E),
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
                    color: const Color(0xFF1A237E),
                  ),
                ),
                Text(
                  dateFormat.format(now),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF5C6BC0),
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
    if (_sessionPurpose.isEmpty) {
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
      // Get the authentication token using AuthService
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('Please login again to continue');
      }

      final url = Uri.parse('http://localhost:8000/api/sessions');
      
      // Convert session type from kebab-case to snake_case
      final sessionType = _sessionType.replaceAll('-', '_');
      
      // Debug print to check patient data
      print('Patient data: ${widget.patient}');
      
      // Prepare the request body
      final requestBody = {
        'patient_id': widget.patient['id']?.toString() ?? widget.patient['patient_id']?.toString(),
        'session_type': sessionType,
        'expected_duration': int.tryParse(_sessionDuration) ?? 60,
        'purpose': _sessionPurpose,
      };
      
      if (requestBody['patient_id'] == null) {
        throw Exception('Patient ID is missing');
      }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Pass the created session data to the parent widget
          final responseData = jsonDecode(response.body);
          if (widget.onStartSession != null) {
            if (responseData is Map && responseData.containsKey('data')) {
              widget.onStartSession(responseData['data']);
            } else {
              widget.onStartSession(responseData);
            }
          }
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
              side: const BorderSide(color: Color(0xFF5C6BC0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF5C6BC0),
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
              backgroundColor: const Color(0xFF5C6BC0),
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
