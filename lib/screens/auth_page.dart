import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:all_ahraga/screens/menu.dart' as customer;
import 'package:all_ahraga/screens/venue_menu.dart';
import 'package:all_ahraga/screens/coach_menu.dart';
import 'package:all_ahraga/screens/landing_page.dart';
import 'package:all_ahraga/screens/admin/admin_menu.dart';
import 'package:all_ahraga/constants/api.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regUsername = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();

  AuthMode _mode = AuthMode.login;
  String? _loginError;
  bool _loginObscure = true;
  bool _loginLoading = false;
  String? _regError;
  String? _regRole;
  bool _regLoading = false;
  bool _regObscure1 = true;
  bool _regObscure2 = true;

  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _loginUsername.dispose();
    _loginPassword.dispose();
    _regUsername.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _switchTo(AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _loginError = null;
      _regError = null;
    });
  }

  void _goLanding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const LandingPage(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _doLogin(CookieRequest request) async {
    if (_loginLoading) return;
    final username = _loginUsername.text.trim();
    final password = _loginPassword.text;

    setState(() {
      _loginError = null;
      _loginLoading = true;
    });

    try {
      final response = await request.login(ApiConstants.authLogin, {
        'username': username,
        'password': password,
      });

      if (!mounted) return;

      if (request.loggedIn) {
        final message = (response['message'] ?? 'Login successful!').toString();
        final uname = (response['username'] ?? username).toString();
        final roleType = response['role_type']?.toString();
        final dynamic _isSuperRaw = response['is_superuser'];
        final bool isSuperuser =
            _isSuperRaw == true ||
            (_isSuperRaw is String && _isSuperRaw.toLowerCase() == 'true') ||
            _isSuperRaw == 1 ||
            (_isSuperRaw?.toString() == '1');

        final roleTypeNorm = roleType?.toString().toUpperCase();

        Widget target;

        if (roleTypeNorm == 'ADMIN' || isSuperuser) {
          target = const AdminHomePage(); // Masuk ke Dashboard Admin
        } else if (roleType == 'VENUE_OWNER') {
          target = const VenueHomePage();
        } else if (roleType == 'COACH') {
          target = const CoachHomePage();
        } else {
          target = const customer.MyHomePage();
        }

        Navigator.pushReplacement(context, _pageSlide(target, toLeft: true));

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text("$message Welcome, $uname"),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        final msg =
            (response['message'] ??
                    'Login failed, please check your username or password.')
                .toString();
        setState(() => _loginError = msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loginError = "Kesalahan jaringan. Coba lagi. ($e)");
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _doRegister(CookieRequest request) async {
    if (_regLoading) return;

    final u = _regUsername.text.trim();
    final email = _regEmail.text.trim();
    final phone = _regPhone.text.trim();
    final p1 = _regPassword.text;
    final p2 = _regConfirm.text;

    if (_regRole == null) {
      setState(() => _regError = "Please choose a role.");
      return;
    }
    if (email.isEmpty) {
      setState(() => _regError = "Email wajib diisi.");
      return;
    }
    if (phone.isEmpty) {
      setState(() => _regError = "Nomor HP wajib diisi.");
      return;
    }

    setState(() {
      _regError = null;
      _regLoading = true;
    });

    try {
      final response = await request.postJson(
        ApiConstants.authRegister,
        jsonEncode({
          "username": u,
          "email": email,
          "phone": phone,
          "password1": p1,
          "password2": p2,
          "role_type": _regRole,
        }),
      );

      if (!mounted) return;

      if (response['status'] == "success") {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text("Successfully registered!"),
              backgroundColor: Colors.green,
            ),
          );

        _switchTo(AuthMode.login);
      } else {
        setState(
          () => _regError = (response['message'] ?? "Registration failed!")
              .toString(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _regError = "Kesalahan jaringan. Coba lagi. ($e)");
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    // final _ = MediaQuery.of(context).size.height; // Unused variable removed

    return Scaffold(
      backgroundColor: const Color(0xFF061B2B),
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) =>
                  CustomPaint(painter: _SportBgPainter(t: _bgCtrl.value)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _goLanding,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "ALL-AHRAGA",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            _MiniPillButton(text: "Kembali", onTap: _goLanding),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Main Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0F172A),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF0F172A),
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.08),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _mode == AuthMode.login
                                    ? _LoginContent(
                                        key: const ValueKey('login'),
                                        error: _loginError,
                                        loading: _loginLoading,
                                        obscure: _loginObscure,
                                        onToggleObscure: () => setState(
                                          () => _loginObscure = !_loginObscure,
                                        ),
                                        usernameCtrl: _loginUsername,
                                        passwordCtrl: _loginPassword,
                                        onSubmit: () => _doLogin(request),
                                        onSwitchToRegister: () =>
                                            _switchTo(AuthMode.register),
                                      )
                                    : _RegisterContent(
                                        key: const ValueKey('register'),
                                        error: _regError,
                                        loading: _regLoading,
                                        role: _regRole,
                                        onRole: (v) =>
                                            setState(() => _regRole = v),
                                        obscure1: _regObscure1,
                                        obscure2: _regObscure2,
                                        onToggle1: () => setState(
                                          () => _regObscure1 = !_regObscure1,
                                        ),
                                        onToggle2: () => setState(
                                          () => _regObscure2 = !_regObscure2,
                                        ),
                                        usernameCtrl: _regUsername,
                                        emailCtrl: _regEmail,
                                        phoneCtrl: _regPhone,
                                        passwordCtrl: _regPassword,
                                        confirmCtrl: _regConfirm,
                                        onSubmit: () => _doRegister(request),
                                        onSwitchToLogin: () =>
                                            _switchTo(AuthMode.login),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== Login Content ==================

class _LoginContent extends StatelessWidget {
  const _LoginContent({
    super.key,
    required this.error,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.onSubmit,
    required this.onSwitchToRegister,
  });

  final String? error;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchToRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sign In",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Masuk untuk melanjutkan aktivitas olahraga kamu",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 24),
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDC2626), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0F172A),
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _GlassTextField(
          label: "Username",
          controller: usernameCtrl,
          enabled: !loading,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _GlassTextField(
          label: "Password",
          controller: passwordCtrl,
          enabled: !loading,
          icon: Icons.lock_outline,
          obscureText: obscure,
          suffix: IconButton(
            onPressed: loading ? null : onToggleObscure,
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          text: loading ? "Signing In..." : "Sign In",
          enabled: !loading,
          onTap: onSubmit,
        ),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Tidak punya akun? ",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: loading ? null : onSwitchToRegister,
                child: Text(
                  "Register",
                  style: TextStyle(
                    color: loading
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0D9488),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                    decorationColor: loading
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0D9488),
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================== Register Content ==================

class _RegisterContent extends StatelessWidget {
  const _RegisterContent({
    super.key,
    required this.error,
    required this.loading,
    required this.role,
    required this.onRole,
    required this.obscure1,
    required this.obscure2,
    required this.onToggle1,
    required this.onToggle2,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.onSubmit,
    required this.onSwitchToLogin,
  });

  final String? error;
  final bool loading;
  final String? role;
  final ValueChanged<String?> onRole;
  final bool obscure1;
  final bool obscure2;
  final VoidCallback onToggle1;
  final VoidCallback onToggle2;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Create Account",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Daftar untuk mulai booking venue & coach favorit",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 20),
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDC2626), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0F172A),
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _GlassTextField(
                  label: "Username",
                  controller: usernameCtrl,
                  enabled: !loading,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _GlassTextField(
                  label: "Email",
                  controller: emailCtrl,
                  enabled: !loading,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _GlassTextField(
                  label: "Nomor HP",
                  controller: phoneCtrl,
                  enabled: !loading,
                  icon: Icons.phone_iphone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _GlassDropdown(
                  initialValue: role,
                  enabled: !loading,
                  onChanged: onRole,
                ),
                const SizedBox(height: 12),
                _GlassTextField(
                  label: "Password",
                  controller: passwordCtrl,
                  enabled: !loading,
                  icon: Icons.lock_outline,
                  obscureText: obscure1,
                  suffix: IconButton(
                    onPressed: loading ? null : onToggle1,
                    icon: Icon(
                      obscure1 ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _GlassTextField(
                  label: "Confirm Password",
                  controller: confirmCtrl,
                  enabled: !loading,
                  icon: Icons.lock_reset,
                  obscureText: obscure2,
                  suffix: IconButton(
                    onPressed: loading ? null : onToggle2,
                    icon: Icon(
                      obscure2 ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          text: loading ? "Creating..." : "Sign Up",
          enabled: !loading,
          onTap: onSubmit,
        ),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Sudah punya akun? ",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: loading ? null : onSwitchToLogin,
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: loading
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0D9488),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                    decorationColor: loading
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0D9488),
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================== Components ==================

class _MiniPillButton extends StatelessWidget {
  const _MiniPillButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.55,
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF0D9488),
            border: Border.all(color: const Color(0xFF0F172A), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF0F172A),
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF0F172A), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
      ),
    );
  }
}

class _GlassDropdown extends StatelessWidget {
  const _GlassDropdown({
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  final String? initialValue;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      onChanged: enabled ? onChanged : null,
      dropdownColor: Colors.white,
      iconEnabledColor: const Color(0xFF0F172A),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: "Daftar sebagai",
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.badge_outlined,
          color: Color(0xFF0F172A),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
        DropdownMenuItem(value: 'VENUE_OWNER', child: Text('Venue Owner')),
        DropdownMenuItem(value: 'COACH', child: Text('Coach')),
      ],
    );
  }
}

PageRouteBuilder _pageSlide(Widget page, {required bool toLeft}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 480),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final begin = toLeft ? const Offset(-0.10, 0) : const Offset(0.10, 0);
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ================== Background Painter ==================

class _SportBgPainter extends CustomPainter {
  _SportBgPainter({required this.t});
  final double t;

  static const Color _teal = Color(0xFF0D9488);
  static const Color _mint = Color(0xFF22C55E);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF041826), Color(0xFF06314A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bg);

    _blob(
      canvas,
      size,
      Offset(size.width * 0.22, size.height * 0.26),
      size.width * 0.28,
      _teal.withValues(alpha: 0.15),
      0.0,
    );
    _blob(
      canvas,
      size,
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.24,
      _mint.withValues(alpha: 0.12),
      1.2,
    );
    _blob(
      canvas,
      size,
      Offset(size.width * 0.68, size.height * 0.86),
      size.width * 0.30,
      Colors.white.withValues(alpha: 0.05),
      2.4,
    );

    final vignette = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
            stops: const [0.55, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.35),
              radius: max(size.width, size.height) * 0.9,
            ),
          );

    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _blob(
    Canvas canvas,
    Size size,
    Offset c,
    double r,
    Color color,
    double phase,
  ) {
    final paint = Paint()..color = color;
    final k = sin((t * 2 * pi) + phase) * 0.04;

    final path = Path();
    const n = 12;
    for (int i = 0; i <= n; i++) {
      final a = (i / n) * 2 * pi;
      final wob =
          (sin(a * 3 + t * 2 * pi + phase) * 0.10) +
          (cos(a * 2 - t * 2 * pi + phase) * 0.08);
      final rr = r * (0.88 + wob + k);
      final x = c.dx + cos(a) * rr;
      final y = c.dy + sin(a) * rr;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SportBgPainter oldDelegate) => oldDelegate.t != t;
}
