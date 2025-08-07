import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/patient_service.dart' as patient_service;
import '../models/patient_session_model.dart';
import '../widgets/app_drawer.dart';

class CompletedSessionsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CompletedSessionsScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  _CompletedSessionsScreenState createState() => _CompletedSessionsScreenState();
}

class _CompletedSessionsScreenState extends State<CompletedSessionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Patient dropdown related state
  List<patient_service.Patient> _patients = [];
  patient_service.Patient? _selectedPatient;
  bool _isLoadingPatients = false;
  
  // Sessions state
  List<PatientSession> _sessions = [];
  bool _isLoadingSessions = false;
  String? _errorMessage;
  
  // Filters
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _dateFilter = 'today';
  
  @override
  void initState() {
    super.initState();
    _loadAllPatients();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllPatients() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingPatients = true;
    });
    
    try {
      final response = await PatientService.getAllPatients();
      if (mounted) {
        setState(() {
          _patients = response.patients;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading patients: $e';
        });
        _showErrorSnackBar(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
        });
      }
    }
  }
  
  Future<void> _loadPatientSessions(String patientId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
    });
    
    try {
      final response = await PatientService.getPatientSessions(patientId)
          .timeout(const Duration(seconds: 30));
          
      if (mounted) {
        setState(() {
          _sessions = response.sessions;
          if (_sessions.isEmpty) {
            _errorMessage = 'No sessions found for this patient';
          }
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Request timed out. Please try again.';
          _sessions = [];
        });
        _showErrorSnackBar(_errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading sessions: ${e.toString().replaceAll('Exception: ', '')}';
          _sessions = [];
        });
        _showErrorSnackBar(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  List<PatientSession> get _filteredSessions {
    return _sessions.where((session) {
      // Match status if filter is not 'all'
      final matchesStatus = _statusFilter == 'all' || 
          session.status.toLowerCase() == _statusFilter.toLowerCase();
          
      // Match session type if filter is not 'all'
      final matchesType = _typeFilter == 'all' || 
          session.sessionType.toLowerCase() == _typeFilter.toLowerCase();
      
      // Match date based on _dateFilter
      bool matchesDate = true;
      if (_dateFilter == 'today') {
        final now = DateTime.now();
        matchesDate = session.startedAt.year == now.year &&
                     session.startedAt.month == now.month &&
                     session.startedAt.day == now.day;
      }
      
      return matchesStatus && matchesType && matchesDate;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Completed Sessions',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateFilter == 'today' 
                      ? "Today's Completed Sessions" 
                      : "Completed Sessions",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _dateFilter == 'today'
                      ? "View today's completed therapy sessions"
                      : "View completed therapy sessions",
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filters Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Patient Dropdown
                        DropdownButtonFormField<patient_service.Patient>(
                          value: _selectedPatient,
                          decoration: InputDecoration(
                            labelText: 'Select Patient',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: _isLoadingPatients
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.arrow_drop_down),
                          ),
                          isExpanded: true,
                          hint: const Text('Select a patient...'),
                          items: _patients.map((patient) {
                            return DropdownMenuItem<patient_service.Patient>(
                              value: patient,
                              child: Text(
                                '${patient.fullName} (${patient.phone ?? 'No phone'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (patient_service.Patient? newValue) async {
                            setState(() {
                              _selectedPatient = newValue;
                              _sessions = [];
                            });
                            if (newValue != null) {
                              await _loadPatientSessions(newValue.id);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Filter Dropdowns
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              // Desktop/Tablet layout
                              return Row(
                                children: [
                                  // Date Dropdown
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: _buildDateDropdown(),
                                    ),
                                  ),
                                  // Status Dropdown
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: _buildStatusDropdown(),
                                    ),
                                  ),
                                  // Type Dropdown
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: _buildTypeDropdown(),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Mobile layout - stack dropdowns vertically
                              return Column(
                                children: [
                                  // Date Dropdown
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildDateDropdown(),
                                  ),
                                  // Status Dropdown
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: _buildStatusDropdown(),
                                  ),
                                  // Type Dropdown
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: _buildTypeDropdown(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sessions List and Stats Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSessionList(),
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    if (_isLoadingSessions) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_selectedPatient == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('Please select a patient to view sessions'),
        ),
      );
    }
    
    if (_filteredSessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No sessions match the current filters'),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(PatientSession session) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(session.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session.status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(session.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Session type and purpose
            Text(
              '${session.sessionType.replaceAll('_', ' ').toUpperCase()}: ${session.purpose.replaceAll('_', ' ').toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Date and time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y').format(session.startedAt),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${session.expectedDuration} min',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${session.notes.join(', ')}',
                style: const TextStyle(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateDropdown() {
    return DropdownButtonFormField<String>(
      value: _dateFilter,
      decoration: InputDecoration(
        labelText: 'Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: 'today',
          child: Text('Today'),
        ),
        DropdownMenuItem(
          value: 'all',
          child: Text('All Dates'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _dateFilter = value;
          });
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: 'all',
          child: Text('All Statuses'),
        ),
        DropdownMenuItem(
          value: 'completed',
          child: Text('Completed'),
        ),
        DropdownMenuItem(
          value: 'scheduled',
          child: Text('Scheduled'),
        ),
        DropdownMenuItem(
          value: 'in_progress',
          child: Text('In Progress'),
        ),
        DropdownMenuItem(
          value: 'cancelled',
          child: Text('Cancelled'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _statusFilter = value;
          });
        }
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _typeFilter,
      decoration: InputDecoration(
        labelText: 'Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: 'all',
          child: Text('All Types'),
        ),
        DropdownMenuItem(
          value: 'in_person',
          child: Text('In-Person'),
        ),
        DropdownMenuItem(
          value: 'remote',
          child: Text('Remote'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _typeFilter = value;
          });
        }
      },
    );
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final completedCount = _sessions.where((s) => s.status == 'completed').length;
    final remoteCount = _sessions.where((s) => s.sessionType == 'remote').length;
    final averageDuration = _sessions.isNotEmpty
        ? (_sessions.map((s) => s.expectedDuration).reduce((a, b) => a + b) / _sessions.length).round()
        : 0;
        
    if (_sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.check_circle, 'Completed', completedCount.toString()),
            _buildStatItem(Icons.video_call, 'Remote', '$remoteCount/${_sessions.length}'),
            _buildStatItem(Icons.timer, 'Avg. Duration', '$averageDuration min'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
