import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:all_ahraga/screens/menu.dart' as customer;
import 'package:all_ahraga/screens/venue_menu.dart';
import 'package:all_ahraga/screens/coach_menu.dart';
import 'package:all_ahraga/screens/landing_page.dart';

enum AuthMode { login, register }
enum PanelStyle { solidWhite, glass }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  // -------- Controllers (shared) --------
  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();

  final _regUsername = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();

  // -------- State --------
  AuthMode _mode = AuthMode.login;

  // Login
  String? _loginError;
  bool _loginObscure = true;
  bool _loginLoading = false;

  // Register
  String? _regError;
  String? _regRole;
  bool _regLoading = false;
  bool _regObscure1 = true;
  bool _regObscure2 = true;

  // Background animation
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
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

  // ---------------- Actions ----------------

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
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
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
      final response = await request.login(
        "http://localhost:8000/auth/login/",
        {'username': username, 'password': password},
      );

      if (!mounted) return;

      if (request.loggedIn) {
        final message = (response['message'] ?? 'Login successful!').toString();
        final uname = (response['username'] ?? username).toString();
        final roleType = response['role_type']?.toString();

        Widget target;
        if (roleType == 'VENUE_OWNER') {
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
              content: Text(
                "$message Welcome, $uname",
              ),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        final msg = (response['message'] ??
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
        "http://localhost:8000/auth/register/",
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
          ..showSnackBar(const SnackBar(content: Text("Successfully registered!"), backgroundColor: Colors.green));

        _switchTo(AuthMode.login);
      } else {
        setState(() =>
            _regError = (response['message'] ?? "Registration failed!").toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _regError = "Kesalahan jaringan. Coba lagi. ($e)");
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFF061B2B),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(
                painter: _SportBgPainter(t: _bgCtrl.value),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // ===== NAVBAR =====
                      LayoutBuilder(
                        builder: (context, cTop) {
                          final isNarrow = cTop.maxWidth < 860;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
                            child: _AuthTopBar(
                              isNarrow: isNarrow,
                              activeIsLogin: _mode == AuthMode.login,
                              onLogo: _goLanding,
                              onGoLogin: () => _switchTo(AuthMode.login),
                              onGoRegister: () => _switchTo(AuthMode.register),
                              onBack: _goLanding,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // header tengah
                      Column(
                        children: [
                          const Text(
                            "ALL-AHRAGA",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Booking venue • Sewa alat • Coaching dalam satu tempat",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final isNarrow = c.maxWidth < 760;
                            const gap = 10.0;

                            final leftPanel = _Panel(
                              style: PanelStyle.solidWhite,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 22),
                                child: _AnimatedPanelBody(
                                  slideFromLeft: true,
                                  childKey: ValueKey("left-$_mode"),
                                  child: _mode == AuthMode.login
                                      ? _LeftLoginForm(
                                          error: _loginError,
                                          loading: _loginLoading,
                                          obscure: _loginObscure,
                                          onToggleObscure: () => setState(
                                              () => _loginObscure = !_loginObscure),
                                          usernameCtrl: _loginUsername,
                                          passwordCtrl: _loginPassword,
                                          onSubmit: () => _doLogin(request),
                                        )
                                      : _LeftWelcomeSignIn(
                                          enabled: !_regLoading,
                                          onSignIn: () => _switchTo(AuthMode.login),
                                        ),
                                ),
                              ),
                            );

                            final rightPanel = _Panel(
                              style: PanelStyle.glass,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 22),
                                child: _AnimatedPanelBody(
                                  slideFromLeft: false,
                                  childKey: ValueKey("right-$_mode"),
                                  child: _mode == AuthMode.login
                                      ? _RightWelcomeSignUp(
                                          enabled: !_loginLoading,
                                          onSignUp: () =>
                                              _switchTo(AuthMode.register),
                                        )
                                      : _RightRegisterForm(
                                          error: _regError,
                                          loading: _regLoading,
                                          role: _regRole,
                                          onRole: (v) => setState(() => _regRole = v),
                                          obscure1: _regObscure1,
                                          obscure2: _regObscure2,
                                          onToggle1: () => setState(
                                              () => _regObscure1 = !_regObscure1),
                                          onToggle2: () => setState(
                                              () => _regObscure2 = !_regObscure2),
                                          usernameCtrl: _regUsername,
                                          emailCtrl: _regEmail,
                                          phoneCtrl: _regPhone,
                                          passwordCtrl: _regPassword,
                                          confirmCtrl: _regConfirm,
                                          onSubmit: () => _doRegister(request),
                                        ),
                                ),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  Expanded(child: leftPanel),
                                  const SizedBox(height: gap),
                                  Expanded(child: rightPanel),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: leftPanel),
                                const SizedBox(width: gap),
                                Expanded(child: rightPanel),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== Top Bar ==================

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({
    required this.isNarrow,
    required this.activeIsLogin,
    required this.onLogo,
    required this.onGoLogin,
    required this.onGoRegister,
    required this.onBack,
  });

  final bool isNarrow;
  final bool activeIsLogin;
  final VoidCallback onLogo;
  final VoidCallback onGoLogin;
  final VoidCallback onGoRegister;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onLogo,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              "ALL-AHRAGA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                fontSize: 16.5,
              ),
            ),
          ),
        ),
        const Spacer(),
        if (!isNarrow) ...[
          _AuthTopLink(text: "Login", active: activeIsLogin, onTap: onGoLogin),
          const SizedBox(width: 10),
          _AuthTopLink(
              text: "Register", active: !activeIsLogin, onTap: onGoRegister),
          const SizedBox(width: 12),
        ],
        _MiniPillButton(text: "Kembali", onTap: onBack),
      ],
    );
  }
}

class _AuthTopLink extends StatelessWidget {
  const _AuthTopLink({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withValues(alpha: 0.82);
    final activeColor = Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            color: active ? activeColor : base,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
            decoration: active ? TextDecoration.underline : TextDecoration.none,
            decorationColor: Colors.white,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}

class _MiniPillButton extends StatelessWidget {
  const _MiniPillButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.3),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: const Text(
          "Kembali",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
        ),
      ),
    );
  }
}

// ================== Animated content switch ==================
class _AnimatedPanelBody extends StatelessWidget {
  const _AnimatedPanelBody({
    required this.slideFromLeft,
    required this.childKey,
    required this.child,
  });

  final bool slideFromLeft;
  final Key childKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inFrom = slideFromLeft ? const Offset(-0.12, 0) : const Offset(0.12, 0);
    final outTo = slideFromLeft ? const Offset(-0.12, 0) : const Offset(0.12, 0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1000),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (w, anim) {
        final isOutgoing = anim.status == AnimationStatus.reverse;

        final slide = isOutgoing
            ? Tween<Offset>(begin: Offset.zero, end: outTo).animate(anim)
            : Tween<Offset>(begin: inFrom, end: Offset.zero).animate(anim);

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: w),
        );
      },
      child: KeyedSubtree(
        key: childKey,
        child: child,
      ),
    );
  }
}

// ================== Left/Right contents ==================

class _LeftLoginForm extends StatelessWidget {
  const _LeftLoginForm({
    required this.error,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.onSubmit,
  });

  final String? error;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sign In",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Masuk untuk melanjutkan aktivitas olahraga kamu.",
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 12.8,
            ),
          ),
          const SizedBox(height: 18),
          if (error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFfee2e2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFfca5a5)),
              ),
              child: Text(
                error!,
                style: const TextStyle(
                  color: Color(0xFF7f1d1d),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.8,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _TextFieldSoft(
            label: "Username",
            controller: usernameCtrl,
            enabled: !loading,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _TextFieldSoft(
            label: "Password",
            controller: passwordCtrl,
            enabled: !loading,
            icon: Icons.lock_outline,
            obscureText: obscure,
            suffix: IconButton(
              onPressed: loading ? null : onToggleObscure,
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryPillButton(
            text: loading ? "Signing In..." : "Sign In",
            enabled: !loading,
            onTap: onSubmit,
            inverted: false,
          ),
        ],
      ),
    );
  }
}

class _RightWelcomeSignUp extends StatelessWidget {
  const _RightWelcomeSignUp({
    required this.enabled,
    required this.onSignUp,
  });

  final bool enabled;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Welcome!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Buat akun untuk mulai booking venue, sewa alat, dan pesan coach dengan cepat.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _PrimaryPillButton(
              text: "Sign Up",
              enabled: enabled,
              onTap: onSignUp,
              inverted: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftWelcomeSignIn extends StatelessWidget {
  const _LeftWelcomeSignIn({
    required this.enabled,
    required this.onSignIn,
  });

  final bool enabled;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Welcome!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sudah punya akun? Masuk untuk lanjut booking & coaching.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _PrimaryPillButton(
              text: "Sign In",
              enabled: enabled,
              onTap: onSignIn,
              inverted: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _RightRegisterForm extends StatelessWidget {
  const _RightRegisterForm({
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Create Account",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Daftar untuk mulai booking venue & coach favoritmu.",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
            fontSize: 12.8,
          ),
        ),
        const SizedBox(height: 14),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7f1d1d).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFfca5a5).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFFFEE2E2),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _TextFieldGlass(
                  label: "Username",
                  controller: usernameCtrl,
                  enabled: !loading,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                _TextFieldGlass(
                  label: "Email",
                  controller: emailCtrl,
                  enabled: !loading,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                _TextFieldGlass(
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

                _TextFieldGlass(
                  label: "Password",
                  controller: passwordCtrl,
                  enabled: !loading,
                  icon: Icons.lock_outline,
                  obscureText: obscure1,
                  suffix: IconButton(
                    onPressed: loading ? null : onToggle1,
                    icon: Icon(
                      obscure1 ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _TextFieldGlass(
                  label: "Confirm Password",
                  controller: confirmCtrl,
                  enabled: !loading,
                  icon: Icons.lock_reset,
                  obscureText: obscure2,
                  suffix: IconButton(
                    onPressed: loading ? null : onToggle2,
                    icon: Icon(
                      obscure2 ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        _PrimaryPillButton(
          text: loading ? "Creating..." : "Sign Up",
          enabled: !loading,
          onTap: onSubmit,
          inverted: true,
        ),
      ],
    );
  }
}

// ================== Route transition ==================
PageRouteBuilder _pageSlide(Widget page, {required bool toLeft}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 480),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
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

// ================== Panels ==================
class _Panel extends StatelessWidget {
  const _Panel({required this.style, required this.child});
  final PanelStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (style == PanelStyle.solidWhite) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ================== Buttons ==================
class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.text,
    required this.enabled,
    required this.onTap,
    required this.inverted,
  });

  final String text;
  final bool enabled;
  final VoidCallback onTap;
  final bool inverted;

  static const Color _teal = Color(0xFF0D9488);
  static const Color _mint = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final Gradient? gradient = inverted
        ? null
        : const LinearGradient(
            colors: [_mint, _teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.55,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: gradient,
            color: inverted ? Colors.transparent : null,
            border: Border.all(
              color: inverted ? Colors.white.withValues(alpha: 0.85) : Colors.transparent,
              width: 1.4,
            ),
            boxShadow: inverted
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
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
                  fontSize: 15.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== Fields ==================
class _TextFieldSoft extends StatelessWidget {
  const _TextFieldSoft({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF0D9488), width: 1.6),
        ),
      ),
    );
  }
}

class _TextFieldGlass extends StatelessWidget {
  const _TextFieldGlass({
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
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.42), width: 1.2),
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
      dropdownColor: const Color.fromARGB(255, 18, 55, 71),
      iconEnabledColor: Colors.white, // panah putih
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: "Daftar sebagai",
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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

// ================== Background painter ==================
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
      _teal.withValues(alpha: 0.20),
      0.0,
    );
    _blob(
      canvas,
      size,
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.24,
      _mint.withValues(alpha: 0.16),
      1.2,
    );
    _blob(
      canvas,
      size,
      Offset(size.width * 0.68, size.height * 0.86),
      size.width * 0.30,
      Colors.white.withValues(alpha: 0.08),
      2.4,
    );

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
        stops: const [0.55, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.35),
          radius: max(size.width, size.height) * 0.9,
        ),
      );

    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _blob(Canvas canvas, Size size, Offset c, double r, Color color, double phase) {
    final paint = Paint()..color = color;
    final k = sin((t * 2 * pi) + phase) * 0.04;

    final path = Path();
    const n = 12;
    for (int i = 0; i <= n; i++) {
      final a = (i / n) * 2 * pi;
      final wob = (sin(a * 3 + t * 2 * pi + phase) * 0.10) +
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
  bool shouldRepaint(covariant _SportBgPainter oldDelegate) => oldDelegate.t != t;
}
