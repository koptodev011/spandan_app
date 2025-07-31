import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sidebar.dart';
import '../widgets/session_card.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Track the selected menu item

  // Sample session data
  final List<Map<String, dynamic>> sessions = [
    {
      'patientName': 'Sarah Johnson',
      'age': 29,
      'gender': 'Female',
      'sessionTime': 'Today: 10:00 AM',
      'sessionType': 'Remote',
      'durationMinutes': 60,
    },
    {
      'patientName': 'Michael Chen',
      'age': 35,
      'gender': 'Male',
      'sessionTime': 'Today: 11:30 AM',
      'sessionType': 'In-Person',
      'durationMinutes': 45,
    },
    {
      'patientName': 'Emma Davis',
      'age': 27,
      'gender': 'Female',
      'sessionTime': 'Today: 2:15 PM',
      'sessionType': 'Remote',
      'durationMinutes': 60,
    },
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      drawer: Sidebar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Close the drawer
          Navigator.pop(context);
          // TODO: Handle navigation to different screens based on index
          switch (index) {
            case 0:
              // Already on Today's Sessions
              break;
            case 1:
              // Navigate to Appointments
              break;
            case 2:
              // Navigate to Completed Sessions
              break;
            case 3:
              // Navigate to Transactions
              break;
            case 4:
              // Navigate to Reports
              break;
          }
        },
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1A237E)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Upcoming Sessions",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            Text(
              "Today's scheduled therapy sessions",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF5C6BC0),
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement add new patient
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
          Padding(
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
                // TODO: Implement search functionality
              },
            ),
          ),
          
          // Session list header
          Padding(
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
                    '${sessions.length} sessions',
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return SessionCard(
                  patientName: session['patientName'],
                  age: session['age'],
                  gender: session['gender'],
                  sessionTime: session['sessionTime'],
                  sessionType: session['sessionType'],
                  durationMinutes: session['durationMinutes'],
                  imageUrl: '',
                  onStartSession: () {
                    // TODO: Implement start session
                  },
                  onViewHistory: () {
                    // TODO: Implement view history
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement start new session
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
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
}
