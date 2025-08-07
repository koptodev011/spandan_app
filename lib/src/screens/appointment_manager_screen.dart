import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../widgets/appointment_card.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'add_appointment_screen.dart';
import 'edit_appointment_screen.dart';

class AppointmentManagerScreen extends StatefulWidget {
  const AppointmentManagerScreen({Key? key}) : super(key: key);

  @override
  _AppointmentManagerScreenState createState() => _AppointmentManagerScreenState();
}

class _AppointmentManagerScreenState extends State<AppointmentManagerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; // 1 represents the Appointments tab index
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAppointments();
  }
  
  Future<void> _fetchAppointments([DateTime? date]) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');
      
      // Format the date as YYYY-MM-DD
      final selectedDate = date ?? _selectedDay ?? DateTime.now();
      final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      
      // Make API call to fetch appointments for the selected date
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/appointments/by-date?date=$formattedDate'),
        headers: ApiService.getHeaders(token: token),
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _appointments = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load today\'s appointments');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load today\'s appointments');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load today\'s appointments: $e';
        });
      }
      print('Error fetching today\'s appointments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_searchQuery.isEmpty) return _appointments;
    
    final query = _searchQuery.toLowerCase();
    return _appointments.where((appointment) {
      final patientName = appointment['patient']?['full_name']?.toString().toLowerCase() ?? '';
      final note = appointment['note']?.toString().toLowerCase() ?? '';
      
      return patientName.contains(query) || note.contains(query);
    }).toList();
  }

  Future<void> _handleAddAppointment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAppointmentScreen(
          onSave: (appointment) {
            // This will be called when the appointment is successfully created
            // The appointment data is already saved to the backend at this point
            // We'll refresh the appointments list to show the new appointment
            _fetchAppointments(_selectedDay);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment created successfully')),
              );
            }
          },
          onBack: () => Navigator.pop(context),
        ),
      ),
    );

    // Refresh the appointments list when returning from the add appointment screen
    // This handles the case where the user pressed back without saving
    if (mounted) {
      await _fetchAppointments(_selectedDay);
    }
  }

  void _handleEditAppointment(Map<String, dynamic> appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(
          appointment: appointment,
          onUpdate: () {
            // Refresh the appointments list after update
            _fetchAppointments(_selectedDay);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment updated successfully')),
            );
          },
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAppointment(int? appointmentId) async {
    if (appointmentId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await AuthService.getToken();
        if (token == null) throw Exception('Authentication required');

        final response = await http.delete(
          Uri.parse('${ApiService.baseUrl}/appointments/$appointmentId'),
          headers: ApiService.getHeaders(token: token),
        );

        if (response.statusCode == 200) {
          // Refresh the appointments list
          _fetchAppointments();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment deleted successfully')),
            );
          }
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to delete appointment');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _onItemTapped(int index) {
    // Close the drawer first
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Handle navigation to different screens based on index
    switch (index) {
      case 0: // Today's Sessions
        if (!mounted) return;
        if (ModalRoute.of(context)?.settings.name != '/patients') {
          Navigator.pushReplacementNamed(context, '/patients');
        }
        break;
      case 1: // Appointments
        if (!mounted) return;
        if (ModalRoute.of(context)?.settings.name != '/appointments') {
          Navigator.pushReplacementNamed(context, '/appointments');
        }
        break;
      case 2: // Completed Sessions
        // TODO: Implement CompletedSessionsScreen
        break;
      case 3: // Reports
        // TODO: Implement ReportsScreen
        break;
    }
    
    // Update the selected index after navigation
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1A237E)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Appointment Manager',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _handleAddAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BBFF2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(
              'Add Appointment',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Calendar Card
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _fetchAppointments(selectedDay);
                        }
                      },
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: _fetchAppointments,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_filteredAppointments.isEmpty)
              const Center(child: Text('No appointments for selected date'))
            else
              _buildAppointmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _filteredAppointments[index];
        final patientName = appointment['patient']?['full_name'] ?? 'Unknown Patient';
        final date = DateTime.parse(appointment['date']);
        final formattedDate = DateFormat('MMM d, yyyy').format(date);
        
        // Parse the time string to a DateTime object
        final timeStr = appointment['time']?.toString() ?? '';
        DateTime? time;
        String formattedTime = '';
        
        try {
          if (timeStr.isNotEmpty) {
            // Try to parse the time string as a DateTime
            time = DateTime.parse(timeStr);
            formattedTime = DateFormat('h:mm a').format(time);
          }
        } catch (e) {
          debugPrint('Error parsing time: $e');
          formattedTime = timeStr; // Fallback to the original string if parsing fails
        }
        
        final type = appointment['appointment_type']?.toString() ?? '';
        
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              patientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$formattedDate at $formattedTime'),
                if (type.isNotEmpty) 
                  Text('Type: ${type[0].toUpperCase()}${type.substring(1)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  onPressed: () => _handleEditAppointment(appointment),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _handleDeleteAppointment(appointment['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              // Handle appointment tap
              // You can navigate to appointment details screen here
            },
          ),
        );
      },
    );
  }
}
