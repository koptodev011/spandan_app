import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionCard extends StatelessWidget {
  final String patientName;
  final int age;
  final String gender;
  final String sessionTime;
  final String sessionType;
  final int durationMinutes;
  final String imageUrl;
  final VoidCallback onStartSession;
  final VoidCallback onViewHistory;

  const SessionCard({
    super.key,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.sessionTime,
    required this.sessionType,
    required this.durationMinutes,
    required this.imageUrl,
    required this.onStartSession,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Avatar - Show image if available, otherwise show initial
                imageUrl.isNotEmpty
                    ? Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE6F7FF),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFE6F7FF),
                        child: Text(
                          patientName.isNotEmpty ? patientName[0] : '?',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5BBFF2),
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Name
                      Text(
                        patientName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Age & Gender
                      Text(
                        '$age years • $gender',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Session Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sessionTime,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Session Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sessionType.toLowerCase() == 'remote'
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sessionType,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sessionType.toLowerCase() == 'remote'
                          ? const Color(0xFF0A7E0A)
                          : const Color(0xFFE67C00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Session Duration & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration
                Text(
                  '$durationMinutes min',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
                // Buttons
                Row(
                  children: [
                    // View History Button
                    OutlinedButton(
                      onPressed: onViewHistory,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5BBFF2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'View History',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Start Session Button
                    ElevatedButton(
                      onPressed: onStartSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BBFF2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Start Session',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
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
}
