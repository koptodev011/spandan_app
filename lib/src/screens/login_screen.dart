import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'patients_screen.dart';
import '../services/auth_service.dart';

// Colors
const Color primaryColor = Color(0xFF2196F3);
const Color textPrimary = Color(0xFF212121);
const Color textSecondary = Color(0xFF757575);
const Color borderColor = Color(0xFFE0E0E0);
const Color errorColor = Color(0xFFF44336);
const Color inputBackground = Color(0xFFF5F5F5);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // For web, use localhost, for Android use 10.0.2.2
        final baseUrl = const bool.fromEnvironment('dart.library.js_util')
            ? 'http://localhost:8000'
            : 'http://10.0.2.2:8000';

        final response = await http.post(
          Uri.parse('$baseUrl/api/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          print('Login response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          if (response.statusCode == 200) {
            // Successfully logged in
            final responseData = jsonDecode(response.body);
            print('Decoded response: $responseData'); // Debug print

            // Check the structure of the response - token is in responseData['authorization']['token']
            final token = responseData['authorization']?['token'];
            print('Extracted token: $token'); // Debug print

            if (token != null) {
              print('Saving token: $token');
              await AuthService.saveToken(token);
              final savedToken = await AuthService.getToken();
              print(
                'Token saved successfully: ${savedToken != null && savedToken.isNotEmpty}',
              );
              print('Actual saved token: $savedToken');
            } else {
              print(
                'No token found in response. Available keys: ${responseData.keys}',
              );
            }

            // Navigate to Patients screen and remove all previous routes
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PatientsScreen()),
                (route) => false, // This removes all previous routes
              );
            }
          } else {
            // Handle error
            final error = jsonDecode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error['message'] ?? 'Login failed')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Network error. Please try again.')),
          );
        }
      }
    }
  }

  // Build input field decoration
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(color: textSecondary, fontSize: 14),
      prefixIcon: Icon(prefixIcon, size: 20, color: textSecondary),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: GoogleFonts.roboto(
        color: errorColor,
        fontSize: 12,
        height: 1.2,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // For tablets, we'll use a larger max width
            final maxWidth = constraints.maxWidth > 600 ? 500.0 : 400.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth > 600 ? 48.0 : 24.0,
                vertical: constraints.maxWidth > 600 ? 32.0 : 24.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth > 600 ? 48 : 32,
                      vertical: constraints.maxWidth > 600 ? 48 : 40,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lock Icon in Circle
                          Container(
                            width: constraints.maxWidth > 600 ? 80 : 64,
                            height: constraints.maxWidth > 600 ? 80 : 64,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: constraints.maxWidth > 600 ? 36 : 28,
                              color: primaryColor,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Welcome Text
                          Text(
                            'Spandan',
                            style: GoogleFonts.roboto(
                              fontSize: constraints.maxWidth > 600 ? 28 : 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            'Sign in to continue',
                            style: GoogleFonts.roboto(
                              fontSize: constraints.maxWidth > 600 ? 16 : 14,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.roboto(
                              color: textPrimary,
                              fontSize: 14,
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Email',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^\s]+\.[^\s]+$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.roboto(
                              color: textPrimary,
                              fontSize: 14,
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Password',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                  color: textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                textStyle: GoogleFonts.roboto(
                                  fontSize: constraints.maxWidth > 600
                                      ? 16
                                      : 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
