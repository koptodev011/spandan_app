import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/src/models/patient_history_model.dart';
import 'package:flutter_app/src/services/patient_service.dart';
import 'package:flutter_app/src/services/auth_service.dart';
import 'package:flutter_app/src/models/session_details_model.dart';

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
    _tabController = TabController(length: 1, vsync: this);
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

      final patientId = widget.patient['id']?.toString();
      if (patientId == null || patientId.isEmpty) {
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

  Future<void> _showSessionDetails(String sessionId) async {
    if (!mounted) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final sessionDetails = await PatientService.getSessionDetails(sessionId);
      
      if (!mounted) return;
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show session details dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Session Details',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionTitle('Session Information'),
                _buildInfoRow('Type', sessionDetails.data.sessionDetails.type),
                _buildInfoRow('Status', sessionDetails.data.sessionDetails.status),
                _buildInfoRow('Started', sessionDetails.data.sessionDetails.startedAt),
                _buildInfoRow('Ended', sessionDetails.data.sessionDetails.endedAt),
                _buildInfoRow('Duration', sessionDetails.data.sessionDetails.expectedDuration),
                _buildInfoRow('Purpose', sessionDetails.data.sessionDetails.purpose),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Patient Information'),
                _buildInfoRow('Name', sessionDetails.data.patient.name),
                _buildInfoRow('Age', '${sessionDetails.data.patient.age} years'),
                _buildInfoRow('Gender', sessionDetails.data.patient.gender),
                _buildInfoRow('Phone', sessionDetails.data.patient.phone),
                _buildInfoRow('Email', sessionDetails.data.patient.email),
                
                if (sessionDetails.data.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Session Notes'),
                  ...sessionDetails.data.notes.map((note) => _buildNoteSection(note)),
                ],
                
                if (sessionDetails.data.medicines.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Medicines'),
                  ...sessionDetails.data.medicines.map((medicine) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        medicine.medicineNotes,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load session details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: const Color(0xFF3B82F6),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoteSection(Note note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.physicalHealthNotes?.isNotEmpty ?? false) ...[
          _buildNoteItem('Physical Health', note.physicalHealthNotes!),
        ],
        if (note.mentalHealthNotes?.isNotEmpty ?? false) ...[
          _buildNoteItem('Mental Health', note.mentalHealthNotes!),
        ],
        if (note.clinicalNotes?.isNotEmpty ?? false) ...[
          _buildNoteItem('Clinical Notes', note.clinicalNotes!),
        ],
        if (note.generalNotes?.isNotEmpty ?? false) ...[
          _buildNoteItem('General Notes', note.generalNotes!),
        ],
        if (note.moodRating != null) ...[
          _buildNoteItem('Mood Rating', '${note.moodRating!}/10'),
        ],
        const SizedBox(height: 8),
        Text(
          'Added on: ${note.createdAt}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
  
  Widget _buildNoteItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
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
                      ...sessionHistory.map((session) => _buildSessionCard(session)),
                    ],
                  ),
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

  Widget _buildSessionCard(SessionHistory session) {
    try {
      final sessionType = session.type?.toLowerCase() ?? 'remote';
      final duration = _formatDuration(session.duration ?? '0 mins');
      final date = session.date != null && session.date!.isNotEmpty 
          ? DateTime.parse(session.date!) 
          : DateTime.now();
      final time = session.time ?? '10:00 AM';
      final status = session.status?.toLowerCase() ?? 'completed';
      final sessionId = session.id.toString(); // Ensure ID is treated as string
      
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
              if (session.mood != null) Row(
                children: [
                  Text(
                    'Mood: ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${_parseMoodValue(session.mood)}/10',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getMoodColor(_parseMoodValue(session.mood).toDouble()),
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
              
              // Notes preview if available
              if (session.notes?.isNotEmpty == true || session.sessionNotes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  session.notes ?? session.sessionNotes ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showSessionDetails(sessionId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building session card: $e');
      return const SizedBox.shrink(); // Return empty widget on error
    }
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
