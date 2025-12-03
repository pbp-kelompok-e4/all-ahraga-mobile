import 'dart:convert';
import 'package:all_ahraga/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _errorMessage;
  String? _selectedRoleType;

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        title: const Text(
          'All-ahraga',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Header
                Text(
                  'Buat Akun Baru',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Daftar untuk mulai booking venue & coach favoritmu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),

                // Card Register Form
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: Column(
                      children: [
                        // Error box
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfee2e2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFfca5a5),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF7f1d1d),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username
                        _buildInput(
                          controller: _usernameController,
                          label: 'Username',
                          hint: 'Enter your username',
                        ),
                        const SizedBox(height: 12),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedRoleType,
                          decoration: _buildDropdownDecoration(),
                          items: const [
                            DropdownMenuItem(
                              value: 'CUSTOMER',
                              child: Text('Customer'),
                            ),
                            DropdownMenuItem(
                              value: 'VENUE_OWNER',
                              child: Text('Venue Owner'),
                            ),
                            DropdownMenuItem(
                              value: 'COACH',
                              child: Text('Coach'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password
                        _buildInput(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          isPassword: true,
                        ),
                        const SizedBox(height: 12),

                        // Confirm Password
                        _buildInput(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          isPassword: true,
                        ),

                        const SizedBox(height: 24),

                        // Register button
                        ElevatedButton(
                          onPressed: () async {
                            final username = _usernameController.text;
                            final password1 = _passwordController.text;
                            final password2 =
                                _confirmPasswordController.text;

                            if (_selectedRoleType == null) {
                              setState(() {
                                _errorMessage = "Please choose a role.";
                              });
                              return;
                            }

                            final response = await request.postJson(
                              "http://localhost:8000/auth/register/",
                              jsonEncode({
                                "username": username,
                                "password1": password1,
                                "password2": password2,
                                "role_type": _selectedRoleType,
                              }),
                            );

                            if (context.mounted) {
                              if (response['status'] == "success") {
                                setState(() => _errorMessage = null);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Successfully registered!"),
                                  ),
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _errorMessage =
                                      response['message'] ??
                                          "Registration failed!";
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Already have account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Sudah punya akun? ",
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Masuk",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UI HELPERS
  InputDecoration _buildDropdownDecoration() {
    return const InputDecoration(
      labelText: 'Daftar sebagai',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: Color(0xFF0d9488),
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}
