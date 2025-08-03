import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spandan',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mental Health Consultation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.people_outline,
                  label: "Today's Sessions",
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: "Appointments",
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.history_outlined,
                  label: "Completed Sessions",
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  label: "Reports",
                  isSelected: selectedIndex == 3,
                  onTap: () {
                    onItemTapped(3);
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  label: "Transactions",
                  isSelected: selectedIndex == 4,
                  onTap: () {
                    onItemTapped(4);
                    Navigator.pushNamed(context, '/transactions');
                  },
                ),
                const SizedBox(height: 8),

              ],
            ),
          ),
          
          // Footer
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.black, // Changed from blue to black
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onTap: onTap,
    );
  }
}
