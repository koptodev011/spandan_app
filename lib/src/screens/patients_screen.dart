import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'start_session_screen.dart';
import 'session_details_screen.dart';
import 'patient_history_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/session_card.dart';
import 'add_patient_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Track the selected menu item

  List<Map<String, dynamic>> sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  List<Map<String, dynamic>> get _filteredSessions {
    if (_searchQuery.isEmpty) return sessions;
    
    final query = _searchQuery.toLowerCase();
    return sessions.where((session) {
      return (session['patientName']?.toString().toLowerCase().contains(query) ?? false) ||
             (session['sessionType']?.toString().toLowerCase().contains(query) ?? false) ||
             (session['note']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchTodaysSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodaysSessions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      // Fetch today's appointments
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/appointments/today'),
        headers: ApiService.getHeaders(token: token),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> appointments = data['data'] ?? [];
          
          // Convert to list first, then sort
          final tempSessions = appointments.map((appointment) {
            final patient = appointment['patient'] ?? {};
            final dateTime = DateTime.parse(appointment['time']);
            final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
            final formattedTime = DateFormat('h:mm a').format(dateTime);
            
            return {
              'id': appointment['id'],
              'patientId': appointment['patient_id'],
              'patientName': patient['full_name'] ?? 'Unknown',
              'age': patient['age'] != null ? int.tryParse(patient['age'].toString()) ?? 0 : 0,
              'gender': (patient['gender'] ?? 'Other').toString().toLowerCase() == 'male' ? 'Male' : 'Female',
              'sessionDate': formattedDate,
              'sessionTime': formattedTime,
              'sessionType': (appointment['appointment_type'] ?? 'remote').toString().toLowerCase() == 'in_person' 
                  ? 'In-Person' 
                  : 'Remote',
              'durationMinutes': appointment['duration_minutes'] ?? 30,
              'note': appointment['note'] ?? '',
              'dateTime': dateTime,
              'patient': {
                'profile_image': patient['profile_image'],
              },
            };
          }).toList();
          
          // Sort the list by date and time
          tempSessions.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));
          
          // Remove the temporary dateTime field
          final finalSessions = tempSessions.map((appt) {
            final newAppt = Map<String, dynamic>.from(appt);
            newAppt.remove('dateTime');
            return newAppt;
          }).toList();
          
          setState(() {
            sessions = finalSessions;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load today\'s sessions');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load today\'s sessions');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load today\'s sessions: $e';
        });
      }
      debugPrint('Error fetching today\'s sessions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sample patient data - replace with your actual data
    final List<Map<String, dynamic>> patients = [
      {
        'name': 'John Doe',
        'age': 32,
        'gender': 'Male',
        'lastSession': '2 days ago',
        'sessionType': 'in-person',
        'totalSessions': 5,
        'joinDate': '2023-05-15',
      },
      {
        'name': 'Jane Smith',
        'age': 28,
        'gender': 'Female',
        'lastSession': '1 week ago',
        'sessionType': 'remote',
        'totalSessions': 12,
        'joinDate': '2023-03-22',
      },
      // Add more sample patients as needed
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5FAFE),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upcoming Sessions",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              "Scheduled therapy sessions",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              // Navigate to AddPatientScreen and wait for a result
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPatientScreen(),
                ),
              );

              // If we got a true result, refresh the patient list
              if (result == true) {
                if (mounted) {
                  // Refresh the list of sessions
                  await _fetchTodaysSessions();
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New patient added successfully!'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BBFF2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(
              'Add New Patient',
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
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFFF5FAFE),
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sessions and patients...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5C6BC0)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF5C6BC0),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          
          // Session list header
          Container(
            color: const Color(0xFFF5FAFE),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  "Today's Sessions",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredSessions.length} of ${sessions.length} sessions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3949AB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Session list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchTodaysSessions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : sessions.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No sessions found for "$_searchQuery"'
                                  : 'No sessions scheduled for today',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTodaysSessions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredSessions.length,
                              itemBuilder: (context, index) {
                                final session = _filteredSessions[index];
                                // Get the image URL from the patient data or use an empty string if not available
                                final patientImage = session['patient']?['profile_image'] ?? '';
                                final imageUrl = patientImage != null && patientImage.isNotEmpty 
                                    ? 'https://spandan.koptotech.solutions/storage/$patientImage'
                                    : '';
                                    
                                return SessionCard(
                                  patientName: session['patientName'],
                                  age: session['age'],
                                  gender: session['gender'],
                                  sessionTime: session['sessionTime'],
                                  sessionType: session['sessionType'],
                                  durationMinutes: session['durationMinutes'],
                                  imageUrl: imageUrl,
                                  onStartSession: () {
                                    _startNewSession(context, {
                                      'id': session['patientId'],
                                      'name': session['patientName'],
                                      'age': session['age'],
                                      'gender': session['gender'],
                                    });
                                  },
                                  onViewHistory: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PatientHistoryScreen(
                                          patient: {
                                            'id': session['patientId'],
                                            'name': session['patientName'],
                                            'age': session['age'],
                                            'gender': session['gender'],
                                            'joinDate': '2023-01-01', // Add actual join date from your data
                                            'totalSessions': 0, // Update with actual count from your data
                                            'lastSession': 'Today', // Update with actual last session date
                                          },
                                          onBack: () => Navigator.pop(context),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to patient details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Patient avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  patient['gender'] == 'Male' ? Icons.male : Icons.female,
                  size: 32,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              // Patient details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient['age']} years • ${patient['sessionType'] == 'in-person' ? 'In-person' : 'Remote'}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient['totalSessions']} sessions • Last ${patient['lastSession']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
                onPressed: () {
                  // TODO: Navigate to patient details
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNewSession(BuildContext context, Map<String, dynamic> patient) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      // Check if session can be started for this patient
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/appointments/todays-upcoming?patient_id=${patient['id']}'),
        headers: ApiService.getHeaders(token: token),
      );

      if (!mounted) return;
      
      // Dismiss the loading dialog
      Navigator.of(context).pop();

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          // Get the appointment data
          final appointmentData = responseData['data'];
          
          // Navigate to StartSessionScreen with appointment data
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StartSessionScreen(
                patient: patient,
                appointment: appointmentData,
                onBack: () => Navigator.pop(context),
                onStartSession: (sessionData) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session started successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          );

          // Refresh the sessions list when returning
          if (mounted) {
            _fetchTodaysSessions();
          }
        } else if (responseData['status'] == 'pending') {
          // Show message for pending appointments
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${responseData['message']} (Starts in ${responseData['starts_in'] ?? 'a while'})'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (responseData['status'] == 'expired') {
          // Show message for expired appointments
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'This appointment has expired'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Show generic error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Cannot start session'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Show error message from server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to start session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStartSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start New Session'),
          content: const Text('Please select a patient to start a session with.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Navigate to patient selection or show another dialog
                _showPatientSelection(context);
              },
              child: const Text('SELECT PATIENT'),
            ),
          ],
        );
      },
    );
  }

  void _showPatientSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Patient'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final patient = sessions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8EAF6),
                    child: Icon(
                      patient['gender'] == 'Male' ? Icons.male : Icons.female,
                      color: const Color(0xFF5C6BC0),
                    ),
                  ),
                  title: Text(patient['patientName']),
                  subtitle: Text('${patient['age']} years • ${patient['gender']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context); // Close the patient selection dialog
                    _startNewSession(context, {
                      'name': patient['patientName'],
                      'age': patient['age'],
                      'gender': patient['gender'],
                    });
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }
}