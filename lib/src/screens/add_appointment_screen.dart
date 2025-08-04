import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onBack;

  const AddAppointmentScreen({
    Key? key,
    required this.onSave,
    required this.onBack,
  }) : super(key: key);

  @override
  _AddAppointmentScreenState createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedPatientId;
  String? _selectedTime;
  String _appointmentType = 'in-person';
  String _duration = '60';
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Debug: Log authentication status
      // Get token using AuthService
      final token = await AuthService.getToken();
      print('Auth Token: ${token != null ? 'Found' : 'Not found'}');
      
      if (token == null || token.isEmpty) {
        print('Error: No authentication token found or token is empty');
        // Check if user is logged in
        final isLoggedIn = await AuthService.isLoggedIn();
        print('Is user logged in: $isLoggedIn');
        
        if (!isLoggedIn) {
          // If not logged in, try to navigate to login screen
          // This assumes you have a way to access the navigator context
          if (mounted) {
            // Uncomment and modify the following line based on your navigation setup
            // Navigator.of(context).pushReplacementNamed('/login');
          }
        }
        
        throw Exception('Authentication required. Please log in.');
      }

      // Debug: Log before API call
      print('Fetching patients from API...');
      
      final patients = await ApiService.getPatients(token: token);
      
      // Debug: Log API response
      print('Patients API Response:');
      print(patients);
      print('Number of patients: ${patients.length}');
      
      setState(() {
        _patients.clear();
        _patients.addAll(patients);
        _isLoading = false;
      });
      
      // Debug: Log final state
      print('Patients loaded successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load patients. Please try again.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedPatientId == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final token = await AuthService.getToken();
        if (token == null) {
          throw Exception('Authentication required. Please log in.');
        }

        // Format date to YYYY-MM-DD
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        
        // Convert time to 24-hour format (e.g., '2:30 PM' -> '14:30')
        final timeFormat = DateFormat('h:mm a');
        final dateTime = timeFormat.parse(_selectedTime!);
        final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        
        // Call the API to create appointment
        await ApiService.createAppointment(
          patientId: int.parse(_selectedPatientId!),
          date: formattedDate,
          time: formattedTime,
          appointmentType: _appointmentType,
          durationMinutes: int.parse(_duration),
          note: _notesController.text.isNotEmpty ? _notesController.text : null,
          token: token,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment created successfully')),
          );
          Navigator.pop(context, true); // Return success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create appointment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error in _submitForm: $e');
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack,
        ),
        title: Text(
          'New Appointment',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Patient *'),
              _buildPatientDropdown(),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Date *'),
              _buildDatePicker(),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Time *'),
              _buildTimeDropdown(),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Appointment Type'),
              _buildAppointmentTypeToggle(),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Duration (minutes)'),
              _buildDurationDropdown(),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Notes (Optional)'),
              _buildNotesField(),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BBFF2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save Appointment',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredPatients = [];

  Widget _buildPatientDropdown() {
    // Show loading indicator while fetching
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Loading patients...'),
          ],
        ),
      );
    }

    // Show error message with retry button if there's an error
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchPatients,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.red[300]!),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Loading Patients'),
              ),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No patients available'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            value: _selectedPatientId,
            decoration: const InputDecoration(
              hintText: 'Select a patient',
              prefixIcon: Icon(Icons.person_outline, size: 20, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              isDense: true,
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 24),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
              height: 1.2,
            ),
            selectedItemBuilder: (BuildContext context) {
              return _patients.map<Widget>((patient) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    patient['full_name'] ?? 'Unnamed Patient',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            dropdownColor: Colors.white,
            items: _patients.map<DropdownMenuItem<String>>((patient) {
              return DropdownMenuItem(
                value: patient['id']?.toString(),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        patient['full_name'] ?? 'Unnamed Patient',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (patient['phone'] != null)
                        Text(
                          patient['phone'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPatientId = value;
              });
            },
            validator: (value) => value == null ? 'Please select a patient' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(suffixIcon: Icons.calendar_today),
        child: Text(
          _selectedDate != null
              ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
              : 'Select a date',
          style: GoogleFonts.inter(
            color: _selectedDate != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTime,
      decoration: _inputDecoration(suffixIcon: Icons.access_time),
      hint: const Text('Select time'),
      items: _timeSlots.map((time) {
        return DropdownMenuItem(value: time, child: Text(time));
      }).toList(),
      onChanged: (value) => setState(() => _selectedTime = value),
      validator: (value) => value == null ? 'Please select a time' : null,
    );
  }

  Widget _buildAppointmentTypeToggle() {
    return Row(
      children: [
        Expanded(child: _buildTypeButton(
          icon: Icons.location_on,
          label: 'In-Person',
          isSelected: _appointmentType == 'in-person',
          onTap: () => setState(() => _appointmentType = 'in-person'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildTypeButton(
          icon: Icons.videocam,
          label: 'Remote',
          isSelected: _appointmentType == 'remote',
          onTap: () => setState(() => _appointmentType = 'remote'),
        )),
      ],
    );
  }

  Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
        foregroundColor: isSelected ? const Color(0xFF1A73E8) : Colors.black87,
        side: BorderSide(
          color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFFE0E0E0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: _duration,
      decoration: _inputDecoration(),
      items: const [
        DropdownMenuItem(value: '30', child: Text('30 minutes')),
        DropdownMenuItem(value: '45', child: Text('45 minutes')),
        DropdownMenuItem(value: '60', child: Text('60 minutes')),
        DropdownMenuItem(value: '90', child: Text('90 minutes')),
      ],
      onChanged: (value) => setState(() => _duration = value ?? '60'),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: _inputDecoration(hintText: 'Add any notes about the appointment'),
    );
  }

  InputDecoration _inputDecoration({String? hintText, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF5C6BC0)) : null,
    );
  }
}
