import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/src/models/patient_history_model.dart';
import 'package:flutter_app/src/services/patient_service.dart';
import 'package:flutter_app/src/services/auth_service.dart';

class PatientHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onBack;

  const PatientHistoryScreen({
    Key? key,
    required this.patient,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  PatientHistoryResponse? _patientHistory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPatientHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final patientId = int.tryParse(widget.patient['id']?.toString() ?? '');
      if (patientId == null) {
        throw Exception('Invalid patient ID');
      }

      final response = await PatientService.getPatientHistory(patientId);
      
      if (mounted) {
        setState(() {
          _patientHistory = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load patient history: $e';
        });
      }
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: widget.onBack,
          ),
          title: Text(
            'Patient History',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading patient history',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchPatientHistory,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_patientHistory == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: widget.onBack,
          ),
          title: Text(
            'Patient History',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'No patient data available',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final patient = _patientHistory!.data.patient;
    final stats = _patientHistory!.data.statistics;
    final sessionHistory = _patientHistory!.data.sessionHistory;
    
    // Calculate total minutes from the statistics string (e.g., "2 hours 30 mins")
    final totalMinutes = _calculateTotalMinutes(stats.totalDuration);

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patient['name'] ?? 'Patient History',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              'Session History & Records',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Overview Cards (Always visible at the top)
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isTablet 
                ? Column(
                    children: [
                      // Single row with 3 cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildOverviewCard(
                              icon: Icons.person_outline,
                              title: 'Patient Info',
                              value: '${patient.age} years • ${_capitalizeFirst(patient.gender)}',
                              isTablet: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOverviewCard(
                              icon: Icons.medical_services_outlined,
                              title: 'Total Sessions',
                              value: '${stats.totalSessions}',
                              isNumber: true,
                              isTablet: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOverviewCard(
                              icon: Icons.timer_outlined,
                              title: 'Total Time',
                              value: stats.totalDuration,
                              isNumber: true,
                              isTablet: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildOverviewCard(
                        icon: Icons.person_outline,
                        title: 'Patient Info',
                        value: '${patient.age} years • ${_capitalizeFirst(patient.gender)}',
                        isTablet: false,
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Total Sessions',
                        value: '${stats.totalSessions}',
                        isNumber: true,
                        isTablet: false,
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewCard(
                        icon: Icons.timer_outlined,
                        title: 'Total Time',
                        value: stats.totalDuration,
                        isNumber: true,
                        isTablet: false,
                      ),
                    ],
                  ),
            ),
          ),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF3B82F6),
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Session History'),
                Tab(text: 'Progress Overview'),
              ],
            ),
          ),
          
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Session History Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Session History',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                          if (sessionHistory.isEmpty)
                            Text(
                              'No sessions found',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...sessionHistory.map((session) => _buildSessionCard({
                        'id': session.id,
                        'date': session.date,
                        'time': session.time,
                        'duration': session.duration,
                        'type': session.type,
                        'status': session.status,
                        'notes': session.notes,
                        'sessionNotes': session.sessionNotes,
                        'mood': session.mood,
                      })),
                    ],
                  ),
                ),
                // Progress Overview Tab (Placeholder for now)
                const Center(
                  child: Text('Progress Overview content will be implemented here'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    bool isNumber = false,
    bool isTablet = false,
  }) {
    return Container(
      width: isTablet ? null : 160,
      height: isTablet ? 180 : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isTablet ? 56 : 40,
            height: isTablet ? 56 : 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: isTablet ? 32 : 24, color: const Color(0xFF5BBFF2)),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14 : 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTablet ? (isNumber ? 28 : 18) : (isNumber ? 20 : 14),
              fontWeight: isNumber ? FontWeight.w600 : FontWeight.normal,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format duration string for display
  String _formatDuration(String duration) {
    try {
      // If it's already in the format we want (e.g., "90 mins"), return as is
      if (duration.toLowerCase().contains('min') || duration.toLowerCase().contains('hr')) {
        return duration;
      }
      
      // If it's a number, assume it's minutes
      final minutes = int.tryParse(duration);
      if (minutes != null) {
        if (minutes >= 60) {
          final hours = minutes ~/ 60;
          final remainingMins = minutes % 60;
          return remainingMins > 0 
              ? '$hours hr $remainingMins mins' 
              : '$hours hr';
        }
        return '$minutes mins';
      }
      
      // Fallback to the original string
      return duration;
    } catch (e) {
      return duration;
    }
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final sessionType = session['type']?.toString().toLowerCase() ?? 'remote';
    final duration = _formatDuration(session['duration']?.toString() ?? '0 mins');
    final date = DateTime.parse(session['date']);
    final time = session['time'] ?? '10:00 AM';
    final notes = session['notes'] ?? 'No session notes available.';
    final clinicalNotes = session['clinical_notes'] ?? 'No clinical notes available.';
    final status = session['status']?.toString().toLowerCase() ?? 'completed';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mood indicator row
            Row(
              children: [
                Text(
                  'Mood: ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${_parseMoodValue(session['mood'])}/10',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getMoodColor(_parseMoodValue(session['mood']).toDouble()),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Time and Duration row
            Row(
              children: [
                _buildSessionInfo(Icons.access_time, '$time ($duration)'),
                const SizedBox(width: 16),
                _buildSessionInfo(
                  sessionType == 'remote' ? Icons.videocam_outlined : Icons.location_on_outlined,
                  sessionType == 'remote' ? 'Remote' : 'In-Person',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Session Notes
            Text(
              'Session Notes:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notes,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Clinical Notes in a highlighted box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Notes:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinicalNotes,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Handle View Details
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Handle Export Notes
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Export Notes',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // Helper to safely parse mood value from dynamic type
  int _parseMoodValue(dynamic moodValue) {
    if (moodValue == null) return 5; // Default to neutral mood if null
    if (moodValue is int) return moodValue;
    if (moodValue is double) return moodValue.round();
    if (moodValue is String) {
      return int.tryParse(moodValue) ?? 5; // Default to 5 if parsing fails
    }
    return 5; // Default fallback
  }

  Widget _buildMoodIndicator(dynamic moodValue) {
    final int mood = _parseMoodValue(moodValue);
    return Row(
      children: [
        Icon(
          Icons.mood,
          size: 16,
          color: _getMoodColor(mood.toDouble()),
        ),
        const SizedBox(width: 4),
        Text(
          '$mood/10',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getMoodColor(mood.toDouble()),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
      case 'missed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // Helper method to calculate total minutes from a duration string
  int _calculateTotalMinutes(String duration) {
    try {
      if (duration.toLowerCase().contains('hour')) {
        final hours = int.tryParse(duration.split(' ')[0]) ?? 0;
        if (duration.toLowerCase().contains('min')) {
          final mins = int.tryParse(duration.split(' ')[2]) ?? 0;
          return hours * 60 + mins;
        }
        return hours * 60;
      } else if (duration.toLowerCase().contains('min')) {
        return int.tryParse(duration.split(' ')[0]) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _getMoodColor(double mood) {
    if (mood >= 8) return const Color(0xFF10B981);
    if (mood >= 6) return const Color(0xFFF59E0B);
    if (mood >= 4) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
}
