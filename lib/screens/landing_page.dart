import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:all_ahraga/screens/auth_page.dart';

// --- CONSTANTS UNTUK WARNA (Supaya Konsisten) ---
const Color _kBgDark = Color(0xFF061B2B);
const Color _kTeal = Color(0xFF0D9488);
const Color _kAmber = Color(0xFFFBBF24); // Aksen Baru (Kuning)
const Color _kSlate = Color(0xFF0F172A);
const Color _kWhite = Colors.white;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _introCtrl;

  late final Animation<double> _fade;
  late final Animation<Offset> _heroLeftSlide;
  late final Animation<Offset> _heroRightSlide;

  final _scrollCtrl = ScrollController();

  final _kHero = GlobalKey();
  final _kFeatures = GlobalKey();
  final _kFlow = GlobalKey();
  final _kTestimonials = GlobalKey();

  static const double _topOffset = 100; // Adjusted for taller header

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 8000,
      ), // Diperlambat biar lebih smooth
    )..repeat();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);

    _heroLeftSlide = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutBack));

    _heroRightSlide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutBack));

    _introCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _introCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _goAuth() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const AuthPage(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final target = (_scrollCtrl.offset + pos.dy - _topOffset).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );

    await _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgDark,
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

          // CONTENT
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final isNarrow = c.maxWidth < 900;
                // Padding konten utama dibuat lebih lega
                final contentPadding = EdgeInsets.symmetric(
                  horizontal: isNarrow ? 20 : 40,
                );

                return CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    // TOP BAR (HEADER)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isNarrow ? 16 : 32,
                          20,
                          isNarrow ? 16 : 32,
                          32,
                        ),
                        child: _TopBar(
                          isNarrow: isNarrow,
                          onAuth: _goAuth,
                          onHome: () => _scrollToKey(_kHero),
                          onFeatures: () => _scrollToKey(_kFeatures),
                          onHowItWorks: () => _scrollToKey(_kFlow),
                          onTestimonials: () => _scrollToKey(_kTestimonials),
                        ),
                      ),
                    ),

                    // HERO SECTION
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kHero,
                        child: Padding(
                          padding: contentPadding,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: isNarrow
                                  ? Column(
                                      children: [
                                        _HeroLeft(
                                          fade: _fade,
                                          slide: _heroLeftSlide,
                                          onPrimary: _goAuth,
                                          onSecondary: _goAuth,
                                        ),
                                        const SizedBox(
                                          height: 24,
                                        ), // Jarak diperbesar
                                        _HeroRight(
                                          fade: _fade,
                                          slide: _heroRightSlide,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6, // Ratio disesuaikan
                                          child: _HeroLeft(
                                            fade: _fade,
                                            slide: _heroLeftSlide,
                                            onPrimary: _goAuth,
                                            onSecondary: _goAuth,
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          flex: 5,
                                          child: _HeroRight(
                                            fade: _fade,
                                            slide: _heroRightSlide,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),

                    // FEATURES SECTION
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kFeatures,
                        child: Padding(
                          padding: contentPadding,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              // FIX 1: Bungkus SizedBox width infinity agar _SectionTitle rata kiri
                              child: const SizedBox(
                                width: double.infinity,
                                child: _SectionTitle(
                                  eyebrow: "POWERFUL FEATURES",
                                  title: "KENAPA ALL-AHRAGA?",
                                  subtitle:
                                      "SOLUSI LENGKAP DALAM SATU PLATFORM.",
                                  dark: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: contentPadding.add(
                          const EdgeInsets.only(top: 32, bottom: 60),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: LayoutBuilder(
                              builder: (context, c2) {
                                final is1Col = c2.maxWidth < 800;
                                final children = const [
                                  _FeatureCard(
                                    icon: Icons.stadium_outlined,
                                    title: "VENUE TERLENGKAP",
                                    desc:
                                        "Akses ratusan venue olahraga dengan sistem booking real-time.",
                                  ),
                                  _FeatureCard(
                                    icon: Icons.verified_user_outlined,
                                    title: "COACH VERIFIED",
                                    desc:
                                        "Pelatih profesional terverifikasi siap bantu tingkatkan performa.",
                                  ),
                                  _FeatureCard(
                                    icon: Icons.flash_on_outlined,
                                    title: "INSTANT BOOKING",
                                    desc:
                                        "Pesan cepat, konfirmasi instan, main tanpa ribet.",
                                  ),
                                ];

                                if (is1Col) {
                                  return Column(
                                    // FIX 2 (REQUESTED): CrossAxisAlignment.stretch agar kotak melebar penuh
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: children
                                        .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            child: e,
                                          ),
                                        )
                                        .toList(),
                                  );
                                }

                                // FIX 3: IntrinsicHeight agar tinggi card sama rata di desktop
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: children[0]),
                                      const SizedBox(width: 24),
                                      Expanded(child: children[1]),
                                      const SizedBox(width: 24),
                                      Expanded(child: children[2]),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // HOW IT WORKS (Dark Band)
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kFlow,
                        child: Padding(
                          padding: contentPadding.add(
                            const EdgeInsets.only(bottom: 60),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: _DarkBand(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 40,
                                  ),
                                  // FIX 4: CrossAxisAlignment.start agar judul Rata Kiri
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _SectionTitle(
                                        eyebrow: "SIMPLE FLOW",
                                        title: "CARA KERJA",
                                        subtitle:
                                            "MULAI OLAHRAGA DALAM 3 LANGKAH.",
                                        dark: true,
                                      ),
                                      const SizedBox(height: 40),

                                      LayoutBuilder(
                                        builder: (context, c3) {
                                          final is1Col = c3.maxWidth < 800;
                                          if (is1Col) {
                                            return const Column(
                                              // Agar step card juga full width di mobile
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _StepCard(
                                                  number: "01",
                                                  title: "BUAT AKUN",
                                                  desc:
                                                      "Registrasi cepat sebagai Customer atau Partner.",
                                                ),
                                                SizedBox(height: 24),
                                                _StepCard(
                                                  number: "02",
                                                  title: "CARI & PILIH",
                                                  desc:
                                                      "Temukan venue atau coach favoritmu.",
                                                ),
                                                SizedBox(height: 24),
                                                _StepCard(
                                                  number: "03",
                                                  title: "MAIN!",
                                                  desc:
                                                      "Bayar mudah & langsung datang ke lokasi.",
                                                ),
                                              ],
                                            );
                                          }

                                          return const Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _StepCard(
                                                  number: "01",
                                                  title: "BUAT AKUN",
                                                  desc:
                                                      "Registrasi cepat sebagai Customer atau Partner.",
                                                ),
                                              ),
                                              SizedBox(width: 24),
                                              Expanded(
                                                child: _StepCard(
                                                  number: "02",
                                                  title: "CARI & PILIH",
                                                  desc:
                                                      "Temukan venue atau coach favoritmu.",
                                                ),
                                              ),
                                              SizedBox(width: 24),
                                              Expanded(
                                                child: _StepCard(
                                                  number: "03",
                                                  title: "MAIN!",
                                                  desc:
                                                      "Bayar mudah & langsung datang ke lokasi.",
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TESTIMONIALS
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kTestimonials,
                        child: Padding(
                          padding: contentPadding,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              // FIX 5: Bungkus SizedBox width infinity agar Rata Kiri
                              child: const SizedBox(
                                width: double.infinity,
                                child: _SectionTitle(
                                  eyebrow: "TESTIMONIALS",
                                  title: "APA KATA MEREKA?",
                                  subtitle: "Cerita nyata dari komunitas.",
                                  dark: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: contentPadding.add(
                          const EdgeInsets.only(top: 32, bottom: 40),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: LayoutBuilder(
                              builder: (context, c4) {
                                final is1Col = c4.maxWidth < 800;
                                final cards = const [
                                  _TestimonialCard(
                                    name: "Budi Hartono",
                                    role: "Pemain Futsal",
                                    quote:
                                        "Booking lapangan jadi gampang banget. Jadwal real-time, prosesnya sat-set.",
                                  ),
                                  _TestimonialCard(
                                    name: "Siti Aminah",
                                    role: "Owner Venue",
                                    quote:
                                        "Manajemen venue jauh lebih efisien. Laporan keuangan jadi makin mudah.",
                                  ),
                                  _TestimonialCard(
                                    name: "Coach David",
                                    role: "Pelatih Basket",
                                    quote:
                                        "Dapat klien baru lebih cepat. Profil coach jadi terlihat banyak orang.",
                                  ),
                                ];

                                if (is1Col) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ...cards.map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          child: e,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const _BigCtaCard(),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: cards[0]),
                                          const SizedBox(width: 24),
                                          Expanded(child: cards[1]),
                                          const SizedBox(width: 24),
                                          Expanded(child: cards[2]),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    const _BigCtaCard(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= WIDGETS =======================

class _Anchor extends StatelessWidget {
  const _Anchor({required super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

// 1. TOP BAR (Dirapikan dengan Glassmorphism)
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isNarrow,
    required this.onAuth,
    required this.onHome,
    required this.onFeatures,
    required this.onHowItWorks,
    required this.onTestimonials,
  });

  final bool isNarrow;
  final VoidCallback onAuth;
  final VoidCallback onHome;
  final VoidCallback onFeatures;
  final VoidCallback onHowItWorks;
  final VoidCallback onTestimonials;

  @override
  Widget build(BuildContext context) {
    // Dibungkus ClipRRect & BackdropFilter agar terlihat seperti "floating glass"
    return ClipRRect(
      borderRadius: BorderRadius.circular(100), // Pill shape
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onHome,
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: _kAmber, size: 20),
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

              if (!isNarrow) ...[
                _TopLink(text: "Features", onTap: onFeatures),
                const SizedBox(width: 24),
                _TopLink(text: "Flow", onTap: onHowItWorks),
                const SizedBox(width: 24),
                _TopLink(text: "Stories", onTap: onTestimonials),
                const SizedBox(width: 32),
              ],

              _MiniPillButton(text: "Masuk / Daftar", onTap: onAuth),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopLink extends StatelessWidget {
  const _TopLink({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _kWhite, // Tombol putih solid biar kontras
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: _kSlate,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// 2. HERO LEFT (Teks Dirapikan)
class _HeroLeft extends StatelessWidget {
  const _HeroLeft({
    required this.fade,
    required this.slide,
    required this.onPrimary,
    required this.onSecondary,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: _NeoCard(
          fill: _kWhite,
          borderColor: _kSlate,
          shadowColor: Colors.black.withOpacity(0.2),
          shadowOffset: const Offset(8, 8), // Shadow lebih tegas
          child: Padding(
            padding: const EdgeInsets.all(32), // Padding lebih besar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TagChip(text: "Platform Olahraga Terpadu"),
                const SizedBox(height: 24),

                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 42,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: _kSlate,
                      fontFamily: 'Roboto',
                    ),
                    children: [
                      TextSpan(text: "BOOK VENUES.\n"),
                      TextSpan(text: "HIRE COACHES.\n"),
                      TextSpan(
                        text: "PLAY ",
                        style: TextStyle(color: _kTeal),
                      ),
                      TextSpan(
                        text: "SPORTS.",
                        style: TextStyle(color: _kTeal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Satu aplikasi untuk semua kebutuhan olahraga. Booking lapangan, cari pelatih, hingga gabung komunitas. Simple & Cepat.",
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: _PrimaryCTA(
                        text: "MULAI GRATIS",
                        onTap: onPrimary,
                        inverted: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PrimaryCTA(
                        text: "MASUK",
                        onTap: onSecondary,
                        inverted: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 3. HERO RIGHT (Grid lebih rapi)
class _HeroRight extends StatelessWidget {
  const _HeroRight({required this.fade, required this.slide});
  final Animation<double> fade;
  final Animation<Offset> slide;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: _NeoCard(
          fill: Colors.white.withOpacity(0.05),
          borderColor: Colors.white.withOpacity(0.2),
          shadowColor: Colors.black.withOpacity(0.3),
          shadowOffset: const Offset(8, 8),
          blur: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SportTile(
                        title: "FUTSAL",
                        icon: Icons.sports_soccer,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SportTile(
                        title: "BASKET",
                        icon: Icons.sports_basketball,
                        filled: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(
                      child: _SportTile(
                        title: "PADEL",
                        icon: Icons.sports_tennis,
                        filled: false,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SportTile(
                        title: "MINI SOCCER",
                        icon: Icons.sports_soccer_outlined,
                        filled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatMini(number: "500+", label: "Venues"),
                    _StatMini(number: "200+", label: "Coaches"),
                    _StatMini(number: "10K+", label: "Users"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kAmber, // Pakai kuning biar mencolok
        border: Border.all(color: _kSlate, width: 2),
        boxShadow: const [BoxShadow(color: _kSlate, offset: Offset(2, 2))],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _kSlate,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.dark,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool dark; // Mempertahankan parameter dark

  @override
  Widget build(BuildContext context) {
    // Logic warna sederhana berdasarkan background section
    final titleColor = dark ? Colors.white : Colors.white;
    final subColor = dark ? Colors.white70 : _kTeal;
    final eyebrowColor = _kAmber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: eyebrowColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            fontSize: 36,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 60, height: 4, color: _kTeal),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            color: subColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// 4. FEATURE CARD (Dirapikan)
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return _NeoCard(
      fill: _kWhite,
      borderColor: _kSlate,
      shadowColor: Colors.black.withOpacity(0.15),
      shadowOffset: const Offset(6, 6),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kTeal,
                border: Border.all(color: _kSlate, width: 2),
                boxShadow: const [
                  BoxShadow(color: _kSlate, offset: Offset(3, 3)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: _kSlate,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. STEP CARD (Dirapikan)
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.desc,
  });

  final String number;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return _NeoCard(
      fill: Colors.white.withOpacity(0.05),
      borderColor: Colors.white.withOpacity(0.2),
      shadowColor: Colors.black.withOpacity(0.3),
      shadowOffset: const Offset(6, 6),
      blur: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: const TextStyle(
                color: _kAmber,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. TESTIMONIAL CARD
class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.name,
    required this.role,
    required this.quote,
  });

  final String name;
  final String role;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return _NeoCard(
      fill: _kWhite,
      borderColor: _kSlate,
      shadowColor: Colors.black.withOpacity(0.15),
      shadowOffset: const Offset(6, 6),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, color: _kTeal, size: 32),
            const SizedBox(height: 12),
            Text(
              quote,
              style: const TextStyle(
                color: _kSlate,
                fontWeight: FontWeight.w600,
                height: 1.5,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _kSlate,
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _kSlate,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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

class _BigCtaCard extends StatelessWidget {
  const _BigCtaCard();

  @override
  Widget build(BuildContext context) {
    return _NeoCard(
      fill: _kTeal,
      borderColor: _kSlate,
      shadowColor: Colors.black.withOpacity(0.2),
      shadowOffset: const Offset(8, 8),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              "SIAP MEMULAI?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Gabung sekarang dan rasakan kemudahan booking venue.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _NeoButton(
              text: "DAFTAR SEKARANG",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              ),
              color: _kAmber,
              textColor: _kSlate,
            ),
          ],
        ),
      ),
    );
  }
}

// HELPERS
class _NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _NeoButton({
    required this.text,
    required this.onTap,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: _kSlate, width: 2.5),
          boxShadow: const [BoxShadow(color: _kSlate, offset: Offset(4, 4))],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PrimaryCTA extends StatelessWidget {
  const _PrimaryCTA({
    required this.text,
    required this.onTap,
    required this.inverted,
  });

  final String text;
  final VoidCallback onTap;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final bg = inverted ? _kWhite : _kTeal;
    final fg = inverted ? _kSlate : _kWhite;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: _kSlate, width: 2.5),
          boxShadow: const [BoxShadow(color: _kSlate, offset: Offset(5, 5))],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.title,
    required this.icon,
    required this.filled,
  });

  final String title;
  final IconData icon;
  final bool filled; // Tetap mempertahankan nama parameter filled

  @override
  Widget build(BuildContext context) {
    final bg = filled ? _kTeal : Colors.white.withOpacity(0.05);
    final border = filled ? _kSlate : Colors.white.withOpacity(0.2);
    final fg = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _kAmber,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _NeoCard extends StatelessWidget {
  const _NeoCard({
    required this.child,
    required this.fill,
    required this.borderColor,
    required this.shadowColor,
    required this.shadowOffset,
    this.blur = false,
  });

  final Widget child;
  final Color fill;
  final Color borderColor;
  final Color shadowColor;
  final Offset shadowOffset;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 0, // Hard shadow (Neo Brutalism)
            offset: shadowOffset,
          ),
        ],
      ),
      child: child,
    );

    if (!blur) return card;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: card,
      ),
    );
  }
}

class _DarkBand extends StatelessWidget {
  const _DarkBand({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _NeoCard(
      fill: Colors.black.withOpacity(0.5),
      borderColor: Colors.white12,
      shadowColor: Colors.black.withOpacity(0.3),
      shadowOffset: const Offset(8, 8),
      blur: true,
      child: child,
    );
  }
}

// PAINTER TETAP SAMA
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
      _teal.withOpacity(0.15),
      0.0,
    );
    _blob(
      canvas,
      size,
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.24,
      _mint.withOpacity(0.12),
      1.2,
    );
    _blob(
      canvas,
      size,
      Offset(size.width * 0.68, size.height * 0.86),
      size.width * 0.30,
      Colors.white.withOpacity(0.05),
      2.4,
    );

    final vignette = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
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
  bool shouldRepaint(covariant _SportBgPainter oldDelegate) =>
      oldDelegate.t != t;
}
