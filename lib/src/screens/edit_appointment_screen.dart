import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onUpdate;
  final VoidCallback onBack;

  const EditAppointmentScreen({
    Key? key,
    required this.appointment,
    required this.onUpdate,
    required this.onBack,
  }) : super(key: key);

  @override
  _EditAppointmentScreenState createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Form fields
  String? _selectedPatientId;
  DateTime? _selectedDate;
  String? _selectedTime;
  String _appointmentType = 'consultation';
  String _duration = '30';

  // Available time slots
  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
    '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM',
    '05:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _prefillForm();
    _fetchPatients();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _prefillForm() {
    if (widget.appointment.isEmpty) return;
    
    setState(() {
      _selectedPatientId = widget.appointment['patient_id']?.toString();
      
      // Parse and set the date
      if (widget.appointment['date'] != null) {
        _selectedDate = DateTime.parse(widget.appointment['date']);
      }
      
      // Parse and set the time
      if (widget.appointment['time'] != null) {
        final formattedTime = _formatTimeForDisplay(widget.appointment['time']);
        // Ensure the formatted time exists in _timeSlots
        if (_timeSlots.contains(formattedTime)) {
          _selectedTime = formattedTime;
        } else {
          // If not found, use the first available time slot
          _selectedTime = _timeSlots.isNotEmpty ? _timeSlots[0] : null;
        }
      } else {
        // If no time is provided, use the first available time slot
        _selectedTime = _timeSlots.isNotEmpty ? _timeSlots[0] : null;
      }
      
      // Set appointment type
      if (widget.appointment['appointment_type'] != null) {
        _appointmentType = widget.appointment['appointment_type'];
      }
      
      // Set duration
      if (widget.appointment['duration_minutes'] != null) {
        _duration = widget.appointment['duration_minutes'].toString();
      }
      
      // Set notes
      if (widget.appointment['note'] != null) {
        _notesController.text = widget.appointment['note'];
      }
    });
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required. Please log in.');
      }

      final patients = await ApiService.getPatients(token: token);
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load patients: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching patients: $e');
    }
  }

  Future<void> _confirmDeleteAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAppointment();
    }
  }

  Future<void> _deleteAppointment() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required. Please log in.');
      }

      await ApiService.deleteAppointment(
        appointmentId: widget.appointment['id'],
        token: token,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully')),
      );
      
      widget.onUpdate();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error in _deleteAppointment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAppointment() async {
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
        
        // Call the API to update appointment
        await ApiService.updateAppointment(
          appointmentId: widget.appointment['id'],
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
            const SnackBar(content: Text('Appointment updated successfully')),
          );
          widget.onUpdate();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update appointment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error in _updateAppointment: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatTimeForDisplay(String time) {
    try {
      // If time is already in the correct format, return as is
      if (_timeSlots.contains(time)) {
        return time;
      }
      
      // If time is in 12-hour format but with seconds, remove seconds
      if (time.contains('AM') || time.contains('PM')) {
        final timePart = time.split(' ')[0];
        final period = time.contains('AM') ? 'AM' : 'PM';
        final components = timePart.split(':');
        if (components.length >= 2) {
          // Format as 'H:MM AM/PM' to match _timeSlots format
          final hour = int.parse(components[0]);
          final minute = components[1];
          return '${hour > 12 ? hour - 12 : hour}:$minute $period';
        }
      }
      
      // Parse 24-hour time to 12-hour format
      final timeComponents = time.split(':');
      if (timeComponents.length >= 2) {
        int hour = int.parse(timeComponents[0]);
        final minute = timeComponents[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        hour = hour == 0 ? 12 : hour; // Convert 0 to 12 for 12 AM/PM
        
        // Format to match exactly with _timeSlots format
        final formattedTime = '$hour:${minute.padLeft(2, '0')} $period';
        
        // If the formatted time exists in _timeSlots, return it
        if (_timeSlots.contains(formattedTime)) {
          return formattedTime;
        }
        
        // If not found, find the closest match
        for (var slot in _timeSlots) {
          if (slot.startsWith('$hour:') && slot.endsWith(period)) {
            return slot;
          }
        }
      }
      
      // Default to first time slot if no match found
      return _timeSlots.isNotEmpty ? _timeSlots[0] : '09:00 AM';
    } catch (e) {
      print('Error formatting time: $e');
      return _timeSlots.isNotEmpty ? _timeSlots[0] : '09:00 AM';
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
          'Edit Appointment',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _patients.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    
                    // Update Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BBFF2),
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
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Update Appointment',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Delete Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _confirmDeleteAppointment,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox.shrink()
                          : Text(
                              'Delete Appointment',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
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

  Widget _buildPatientDropdown() {
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a patient';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF5BBFF2),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 16),
            Text(
              _selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                  : 'Select a date',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            value: _selectedTime,
            decoration: const InputDecoration(
              hintText: 'Select a time',
              prefixIcon: Icon(Icons.access_time, size: 20, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              isDense: true,
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 24),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
            items: _timeSlots.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTime = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a time';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTypeButton(
            icon: Icons.medical_services,
            label: 'Consultation',
            isSelected: _appointmentType == 'consultation',
            onTap: () => setState(() => _appointmentType = 'consultation'),
          ),
          const SizedBox(width: 8),
          _buildTypeButton(
            icon: Icons.medical_information,
            label: 'Follow-up',
            isSelected: _appointmentType == 'follow_up',
            onTap: () => setState(() => _appointmentType = 'follow_up'),
          ),
          const SizedBox(width: 8),
          _buildTypeButton(
            icon: Icons.medication,
            label: 'Treatment',
            isSelected: _appointmentType == 'treatment',
            onTap: () => setState(() => _appointmentType = 'treatment'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5BBFF2) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF5BBFF2).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            value: _duration,
            decoration: const InputDecoration(
              hintText: 'Select duration',
              prefixIcon: Icon(Icons.timer, size: 20, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              isDense: true,
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 24),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
            items: ['15', '30', '45', '60'].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text('$value minutes'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _duration = newValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Add any notes about the appointment...',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey[500],
        ),
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
          borderSide: const BorderSide(color: Color(0xFF5BBFF2), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }
}
