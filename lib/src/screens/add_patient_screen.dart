import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';

final _storage = FlutterSecureStorage();

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'name': '',
    'age': '',
    'gender': 'male', // Set default value to match one of the dropdown options
    'phone': '',
    'email': '',
    'address': '',
    'emergencyContact': '',
    'medicalHistory': '',
    'currentMedications': '',
    'allergies': '',
    'notes': '',
    'appointmentDate': '',
    'appointmentTime': '',
    'appointmentType': 'in-person',
    'duration': '30',
  };

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final token = await AuthService.getToken();
        print('Retrieved token: $token'); // Debug print
        
        if (token == null || token.isEmpty) {
          print('No token found, redirecting to login'); // Debug print
          if (mounted) {
            // Redirect to login if not authenticated
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        final patientData = {
          'full_name': _formData['name'],
          'age': int.parse(_formData['age']),
          'gender': _formData['gender'],
          'phone': _formData['phone'],
          'email': _formData['email'],
          'address': _formData['address'],
          'emergency_contact': _formData['emergencyContact'],
          'medical_history': _formData['medicalHistory'],
          'current_medication': _formData['currentMedications'],
          'allergies': _formData['allergies'],
          'appointment_date': _formData['appointmentDate'],
          'appointment_time': _formData['appointmentTime'],
          'appointment_type': _formData['appointmentType'],
          'duration_minutes': int.parse(_formData['duration']),
          'appointment_note': _formData['notes'],
        };

        // For web, use localhost, for Android use 10.0.2.2
        final baseUrl = const bool.fromEnvironment('dart.library.js_util')
            ? 'http://localhost:8000'
            : 'http://10.0.2.2:8000';
            
        final response = await http.post(
          Uri.parse('$baseUrl/api/patients'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(patientData),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient added successfully')),
            );
            Navigator.pop(context, true);
          }
        } else {
          final errorData = jsonDecode(response.body);
          if (errorData['errors'] != null) {
            // Handle validation errors
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = errors.entries
                .map((e) => '${e.key}: ${e.value.join(', ')}')
                .join('\n');
            throw Exception('Validation failed:\n$errorMessages');
          }
          throw Exception(errorData['message'] ?? 'Failed to create patient');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving patient: $e');
        }
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Patient',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.person_outline,
                      children: [
                        _buildTextFormField(
                          label: 'Full Name *',
                          onSaved: (value) => _formData['name'] = value,
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        _buildTextFormField(
                          label: 'Age *',
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _formData['age'] = value,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : int.tryParse(value) == null
                                  ? 'Invalid number'
                                  : null,
                        ),
                        DropdownButtonFormField<String>(
                          value: _formData['gender'],
                          decoration: const InputDecoration(labelText: 'Gender *'),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('Male')),
                            DropdownMenuItem(value: 'female', child: Text('Female')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                            DropdownMenuItem(
                              value: 'prefer-not-to-say',
                              child: Text('Prefer not to say'),
                            ),
                          ],
                          onChanged: (value) => setState(() => _formData['gender'] = value),
                          validator: (value) => value == null ? 'Required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Contact Info',
                      icon: Icons.phone,
                      children: [
                        _buildTextFormField(
                          label: 'Phone *',
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _formData['phone'] = value,
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        _buildTextFormField(
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _formData['email'] = value,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          label: 'Address',
                          onSaved: (value) => _formData['address'] = value,
                        ),
                        _buildTextFormField(
                          label: 'Emergency Contact',
                          onSaved: (value) => _formData['emergencyContact'] = value,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Medical Information',
                      icon: Icons.local_hospital,
                      children: [
                        _buildTextFormField(
                          label: 'Medical History',
                          maxLines: 3,
                          onSaved: (value) => _formData['medicalHistory'] = value,
                        ),
                        _buildTextFormField(
                          label: 'Current Medications',
                          maxLines: 3,
                          onSaved: (value) => _formData['currentMedications'] = value,
                        ),
                        _buildTextFormField(
                          label: 'Allergies',
                          maxLines: 2,
                          onSaved: (value) => _formData['allergies'] = value,
                        ),
                        _buildTextFormField(
                          label: 'Notes',
                          maxLines: 2,
                          onSaved: (value) => _formData['notes'] = value,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Appointment Details',
                      icon: Icons.calendar_today,
                      children: [
                        _buildDatePicker(),
                        _buildTimePicker(),
                        _buildDropdownRow(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BBFF2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Save Patient',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF5C6BC0)),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A237E))),
              ],
            ),
            const SizedBox(height: 16),
            ..._addSpacing(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _addSpacing(List<Widget> children) {
    final spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(const SizedBox(height: 16));
      }
    }
    return spaced;
  }

  Widget _buildTextFormField({
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _formData['appointmentDate'] = DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Appointment Date *'),
        child: Text(
          _formData['appointmentDate'].isNotEmpty
              ? DateFormat('MMM dd, yyyy')
                  .format(DateTime.parse(_formData['appointmentDate']))
              : 'Select date',
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: _selectedTime);
        if (picked != null) {
          setState(() {
            _selectedTime = picked;
            _formData['appointmentTime'] =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Appointment Time *'),
        child: Text(
          _formData['appointmentTime'].isNotEmpty
              ? _formData['appointmentTime']
              : 'Select time',
        ),
      ),
    );
  }

  Widget _buildDropdownRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _formData['appointmentType'],
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'in-person', child: Text('In-person')),
              DropdownMenuItem(value: 'remote', child: Text('Remote')),
            ],
            onChanged: (value) => setState(() => _formData['appointmentType'] = value),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _formData['duration'],
            decoration: const InputDecoration(labelText: 'Duration'),
            items: ['15', '30', '45', '60', '90', '120']
                .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                .toList(),
            onChanged: (value) => setState(() => _formData['duration'] = value),
          ),
        ),
      ],
    );
  }
}
