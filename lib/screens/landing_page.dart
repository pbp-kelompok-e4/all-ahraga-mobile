import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:all_ahraga/screens/auth_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _introCtrl;

  late final Animation<double> _fade;
  late final Animation<Offset> _heroLeftSlide;
  late final Animation<Offset> _heroRightSlide;

  final _scrollCtrl = ScrollController();

  // ======= SECTION ANCHORS =======
  final _kHero = GlobalKey();
  final _kFeatures = GlobalKey();
  final _kFlow = GlobalKey();
  final _kTestimonials = GlobalKey();

  static const double _topOffset = 86;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);

    _heroLeftSlide = Tween<Offset>(
      begin: const Offset(-0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));

    _heroRightSlide = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));

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
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const AuthPage(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);

    final target = (_scrollCtrl.offset + pos.dy - _topOffset)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);

    await _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: LayoutBuilder(
              builder: (context, c) {
                final isNarrow = c.maxWidth < 860;

                return CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
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

                    // HERO
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kHero,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: isNarrow
                                  ? Column(
                                      children: [
                                        _HeroLeft(
                                          fade: _fade,
                                          slide: _heroLeftSlide,
                                          onPrimary: _goAuth,
                                          onSecondary: _goAuth,
                                        ),
                                        const SizedBox(height: 14),
                                        _HeroRight(
                                          fade: _fade,
                                          slide: _heroRightSlide,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 11,
                                          child: _HeroLeft(
                                            fade: _fade,
                                            slide: _heroLeftSlide,
                                            onPrimary: _goAuth,
                                            onSecondary: _goAuth,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          flex: 10,
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

                    // FEATURES
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kFeatures,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: const _SectionTitle(
                                eyebrow: "FEATURES",
                                title: "KENAPA ALL-AHRAGA?",
                                subtitle: "SOLUSI LENGKAP DALAM SATU PLATFORM.",
                                dark: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: LayoutBuilder(
                              builder: (context, c2) {
                                final is1Col = c2.maxWidth < 720;
                                final children = const [
                                  _FeatureCard(
                                    icon: Icons.place_outlined,
                                    title: "VENUE TERLENGKAP",
                                    desc:
                                        "Akses ratusan venue olahraga dengan sistem booking real-time dan jadwal yang jelas.",
                                  ),
                                  _FeatureCard(
                                    icon: Icons.verified_user_outlined,
                                    title: "COACH BERSERTIFIKAT",
                                    desc:
                                        "Pelatih profesional terverifikasi siap bantu tingkatkan performa olahraga kamu.",
                                  ),
                                  _FeatureCard(
                                    icon: Icons.flash_on_outlined,
                                    title: "INSTANT BOOKING",
                                    desc:
                                        "Pesan cepat, konfirmasi instan, pengalaman booking lebih simpel dan aman.",
                                  ),
                                ];

                                if (is1Col) {
                                  return Column(
                                    children: [
                                      for (final w in children) ...[
                                        w,
                                        const SizedBox(height: 12),
                                      ]
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: children[0]),
                                    const SizedBox(width: 12),
                                    Expanded(child: children[1]),
                                    const SizedBox(width: 12),
                                    Expanded(child: children[2]),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // HOW IT WORKS (dark section)
                    SliverToBoxAdapter(
                      child: _Anchor(
                        key: _kFlow,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: _DarkBand(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      const _SectionTitle(
                                        eyebrow: "FLOW",
                                        title: "ALUR KERJA",
                                        subtitle:
                                            "MULAI PETUALANGAN OLAHRAGA ANDA. MUDAH. CEPAT.",
                                        dark: true,
                                      ),
                                      const SizedBox(height: 18),

                                      LayoutBuilder(
                                        builder: (context, c3) {
                                          final is1Col = c3.maxWidth < 860;
                                          if (is1Col) {
                                            return const Column(
                                              children: [
                                                _StepCard(
                                                  number: "1",
                                                  title: "REGISTRASI AKUN",
                                                  desc:
                                                      "Buat akun. Pilih peran: Customer, Venue Owner, atau Coach.",
                                                ),
                                                SizedBox(height: 12),
                                                _StepCard(
                                                  number: "2",
                                                  title: "SEARCH & SELECT",
                                                  desc:
                                                      "Temukan venue atau coach. Cek jadwal, harga, dan rating.",
                                                ),
                                                SizedBox(height: 12),
                                                _StepCard(
                                                  number: "3",
                                                  title: "PAY & PLAY!",
                                                  desc:
                                                      "Selesaikan pembayaran. Konfirmasi instan. Waktunya berolahraga!",
                                                ),
                                              ],
                                            );
                                          }

                                          return const Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _StepCard(
                                                  number: "1",
                                                  title: "REGISTRASI AKUN",
                                                  desc:
                                                      "Buat akun. Pilih peran: Customer, Venue Owner, atau Coach.",
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: _StepCard(
                                                  number: "2",
                                                  title: "SEARCH & SELECT",
                                                  desc:
                                                      "Temukan venue atau coach. Cek jadwal, harga, dan rating.",
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: _StepCard(
                                                  number: "3",
                                                  title: "PAY & PLAY!",
                                                  desc:
                                                      "Selesaikan pembayaran. Konfirmasi instan. Waktunya berolahraga!",
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 14),
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
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: const _SectionTitle(
                                eyebrow: "TESTIMONIALS",
                                title: "Apa Kata Mereka?",
                                subtitle: "Cerita singkat dari pengguna & partner.",
                                dark: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: LayoutBuilder(
                              builder: (context, c4) {
                                final is1Col = c4.maxWidth < 820;

                                if (is1Col) {
                                  return Column(
                                    children: const [
                                      _TestimonialCard(
                                        name: "Budi Hartono",
                                        role: "Pemain Futsal",
                                        quote:
                                            "Booking lapangan jadi gampang banget. Jadwal real-time, prosesnya sat-set.",
                                      ),
                                      SizedBox(height: 12),
                                      _TestimonialCard(
                                        name: "Siti Aminah",
                                        role: "Pemilik Venue",
                                        quote:
                                            "Manajemen venue jauh lebih efisien. Jadwal rapi dan laporan makin mudah.",
                                      ),
                                      SizedBox(height: 12),
                                      _TestimonialCard(
                                        name: "David Lee",
                                        role: "Coach Certified",
                                        quote:
                                            "Dapat klien baru lebih cepat. Profil coach jadi terlihat banyak orang.",
                                      ),
                                      SizedBox(height: 14),
                                      _BigCtaCard(),
                                    ],
                                  );
                                }

                                return const Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _TestimonialCard(
                                            name: "Budi Hartono",
                                            role: "Pemain Futsal",
                                            quote:
                                                "Booking lapangan jadi gampang banget. Jadwal real-time, prosesnya sat-set.",
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: _TestimonialCard(
                                            name: "Siti Aminah",
                                            role: "Pemilik Venue",
                                            quote:
                                                "Manajemen venue jauh lebih efisien. Jadwal rapi dan laporan makin mudah.",
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: _TestimonialCard(
                                            name: "David Lee",
                                            role: "Coach Certified",
                                            quote:
                                                "Dapat klien baru lebih cepat. Profil coach jadi terlihat banyak orang.",
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 14),
                                    _BigCtaCard(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
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

// ======================= ANCHOR WRAPPER =======================
class _Anchor extends StatelessWidget {
  const _Anchor({required super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

// ======================= TOP BAR =======================

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
    return Row(
      children: [
        InkWell(
          onTap: onHome,
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
          _TopLink(text: "Features", onTap: onFeatures),
          const SizedBox(width: 10),
          _TopLink(text: "Flow", onTap: onHowItWorks),
          const SizedBox(width: 10),
          _TopLink(text: "Testimonials", onTap: onTestimonials),
          const SizedBox(width: 12),
        ],

        _MiniPillButton(
          text: "Masuk / Daftar",
          onTap: onAuth,
        ),
      ],
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
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
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
        ),
      ),
    );
  }
}

// ======================= HERO =======================

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
          fill: Colors.white.withValues(alpha: 0.92),
          borderColor: const Color(0xFF0F172A),
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shadowOffset: const Offset(0, 10),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TagChip(text: "Platform Olahraga Terpadu"),
                const SizedBox(height: 14),

                const Text(
                  "BOOK VENUES.\nHIRE COACHES.\nPLAY SPORTS.",
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  "Satu platform untuk semua kebutuhan olahraga. Sederhana, cepat, dan efisien. [v.2025]",
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _PrimaryCTA(
                        text: "MULAI GRATIS",
                        onTap: onPrimary,
                        inverted: false,
                      ),
                    ),
                    const SizedBox(width: 10),
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
          fill: Colors.white.withValues(alpha: 0.08),
          borderColor: Colors.white.withValues(alpha: 0.18),
          shadowColor: Colors.black.withValues(alpha: 0.22),
          shadowOffset: const Offset(0, 10),
          blur: true,
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SportTile(
                        title: "BASKET",
                        icon: Icons.sports_basketball,
                        filled: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(
                      child: _SportTile(
                        title: "PADEL",
                        icon: Icons.sports_tennis,
                        filled: false,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _SportTile(
                        title: "MINI SOCCER",
                        icon: Icons.sports_soccer_outlined,
                        filled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 18, color: Colors.white24),
                Row(
                  children: const [
                    Expanded(child: _StatMini(number: "500+", label: "Venues")),
                    SizedBox(width: 10),
                    Expanded(child: _StatMini(number: "200+", label: "Coaches")),
                    SizedBox(width: 10),
                    Expanded(child: _StatMini(number: "10K+", label: "Users")),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0F172A), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("•", style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= SECTION TITLE =======================
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
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.white;
    final subColor = const Color(0xFF5EEAD4);
    final eyebrowColor = Colors.white.withValues(alpha: 0.78);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: eyebrowColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            fontSize: 34,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: subColor,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

// ======================= CARDS =======================

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
        border: Border.all(color: borderColor, width: 2.6),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: shadowOffset,
          ),
        ],
      ),
      child: child,
    );

    if (!blur) return card;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: card,
      ),
    );
  }
}

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
      fill: Colors.white.withValues(alpha: 0.92),
      borderColor: const Color(0xFF0F172A),
      shadowColor: Colors.black.withValues(alpha: 0.16),
      shadowOffset: const Offset(6, 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                border: Border.all(color: const Color(0xFF0F172A), width: 2.4),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF0F172A), offset: Offset(4, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
                height: 1.35,
                fontSize: 12.8,
              ),
            ),
          ],
        ),
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
      fill: const Color(0xFF081A28).withValues(alpha: 0.78),
      borderColor: const Color(0xFF0F172A),
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shadowOffset: const Offset(8, 8),
      blur: true,
      child: child,
    );
  }
}

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
      fill: Colors.white.withValues(alpha: 0.08),
      borderColor: Colors.white.withValues(alpha: 0.18),
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shadowOffset: const Offset(6, 6),
      blur: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                border: Border.all(color: const Color(0xFF0F172A), width: 2.4),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF0F172A), offset: Offset(4, 4)),
                ],
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                height: 1.35,
                fontSize: 12.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      fill: Colors.white.withValues(alpha: 0.92),
      borderColor: const Color(0xFF0F172A),
      shadowColor: Colors.black.withValues(alpha: 0.16),
      shadowOffset: const Offset(6, 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "“",
              style: TextStyle(
                color: Color(0xFF0D9488),
                fontWeight: FontWeight.w900,
                fontSize: 42,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              quote,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                height: 1.25,
                fontSize: 14.2,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 18, color: Color(0xFF0F172A)),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.2,
                        ),
                      ),
                    ],
                  ),
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
      fill: const Color(0xFF0D9488),
      borderColor: const Color(0xFF0F172A),
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shadowOffset: const Offset(8, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isNarrow = c.maxWidth < 700;
            final text = const Text(
              "Siap jadi bagian dari panggung utama olahraga?\nMulai sekarang!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1.15,
              ),
            );

            final btn = GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              ),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2.4),
                ),
                child: const Text(
                  "Mulai Sekarang!",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: 12),
                  btn,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 5, child: text),
                const SizedBox(width: 12),
                btn,
              ],
            );
          },
        ),
      ),
    );
  }
}

// ======================= CTA BUTTONS =======================

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
    final bg = inverted ? Colors.white : const Color(0xFF0D9488);
    final fg = inverted ? const Color(0xFF0F172A) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: const Color(0xFF0F172A), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF0F172A), offset: Offset(6, 6)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ======================= HERO WIDGETS =======================

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.title,
    required this.icon,
    required this.filled,
  });

  final String title;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? const Color(0xFF0D9488) : Colors.white.withValues(alpha: 0.08);
    final fg = Colors.white;
    final border = filled ? const Color(0xFF0F172A) : Colors.white.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 2.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 0.6,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= BACKGROUND =======================

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
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.35),
        radius: max(size.width, size.height) * 0.9,
      ));

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
