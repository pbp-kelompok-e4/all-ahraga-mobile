// lib/screens/venue_menu.dart

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/widgets/left_drawer.dart';
import 'package:all_ahraga/screens/venue/venue_revenue.dart';
import 'package:all_ahraga/screens/venue/venue_dashboard.dart';

// --- DESIGN SYSTEM CONSTANTS & WIDGETS ---

class NeoColors {
  static const Color primary = Color(0xFF0D9488); // Tosca
  static const Color text = Color(0xFF0F172A);    // Slate
  static const Color muted = Color(0xFF64748B);   // Grey
  static const Color danger = Color(0xFFDC2626);  // Red
  static const Color background = Colors.white;
}

// 1. Neo Container (Base Box)
class NeoContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool hasShadow;

  const NeoContainer({
    super.key,
    required this.child,
    this.color = NeoColors.background,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NeoColors.text, width: 2),
          boxShadow: hasShadow
              ? const [
                  BoxShadow(
                    color: NeoColors.text,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

// --- MAIN PAGE ---

class VenueHomePage extends StatelessWidget {
  const VenueHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Context watch tidak digunakan untuk logout disini karena tombol dihapus,
    // tapi tetap disimpan jika dibutuhkan logic lain.
    // final request = context.watch<CookieRequest>(); 

    return Scaffold(
      backgroundColor: NeoColors.background,
      // Menggunakan AppBar bawaan tapi di-style Neo-Brutalism agar Drawer tetap jalan
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: NeoColors.text, width: 2),
        ),
        iconTheme: const IconThemeData(color: NeoColors.text),
        title: const Text(
          'ALL-AHRAGA',
          style: TextStyle(
            color: NeoColors.text,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. WELCOME BANNER
            NeoContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: NeoColors.primary, // Tosca Background
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HALO, VENUE OWNER! 🏟️',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola fasilitas dan pantau pendapatan Anda di sini.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'MENU MANAJEMEN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: NeoColors.text,
              ),
            ),
            const SizedBox(height: 16),

            // 2. MENU GRID
            GridView.count(
              primary: false,
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85, // Mengatur rasio tinggi/lebar kartu
              children: [
                // --- VENUE DASHBOARD CARD ---
                _buildNeoMenuCard(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'DASHBOARD',
                  subtitle: 'Statistik & Booking',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VenueDashboardPage(),
                      ),
                    );
                  },
                ),

                // --- VENUE REVENUE CARD ---
                _buildNeoMenuCard(
                  context,
                  icon: Icons.monetization_on_outlined,
                  title: 'REVENUE',
                  subtitle: 'Laporan Pendapatan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VenueRevenuePage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return NeoContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA), // Light Tosca bg
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.text, width: 2),
            ),
            child: Icon(icon, color: NeoColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: NeoColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: NeoColors.muted,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}