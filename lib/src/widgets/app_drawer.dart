import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
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
                  isSelected:
                      currentRoute == '/patients' || currentRoute.isEmpty,
                  onTap: () {
                    if (currentRoute != '/patients') {
                      Navigator.pushReplacementNamed(context, '/patients');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: "Appointments",
                  isSelected: currentRoute == '/appointments',
                  onTap: () {
                    if (currentRoute != '/appointments') {
                      Navigator.pushReplacementNamed(context, '/appointments');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.history_outlined,
                  label: "Completed Sessions",
                  isSelected: currentRoute == '/completed-sessions',
                  onTap: () {
                    if (currentRoute != '/completed-sessions') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/completed-sessions',
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  label: "Reports",
                  isSelected: currentRoute == '/reports',
                  onTap: () {
                    if (currentRoute != '/reports') {
                      Navigator.pushReplacementNamed(context, '/reports');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  label: "Transactions",
                  isSelected: currentRoute == '/transactions',
                  onTap: () {
                    if (currentRoute != '/transactions') {
                      Navigator.pushReplacementNamed(context, '/transactions');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  label: "Logout",
                  isSelected: false,
                  onTap: () async {
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Confirm Logout',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: GoogleFonts.inter(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: GoogleFonts.inter()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.inter(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      // Clear the auth token
                      await AuthService.clearToken();

                      // Navigate to login screen and remove all previous routes
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // Footer
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
          color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF4B5563),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onTap: onTap,
    );
  }
}
