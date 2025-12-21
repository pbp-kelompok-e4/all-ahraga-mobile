import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/widgets/left_drawer.dart';
import 'package:all_ahraga/screens/venue/venue_revenue.dart';
import 'package:all_ahraga/screens/venue/venue_dashboard.dart';

class NeoBrutalism {
  static const Color primary = Color(0xFF0D9488);
  static const Color slate = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color white = Colors.white;

  static const double borderWidth = 2.0;
  static const double borderRadius = 8.0;
  static const Offset shadowOffset = Offset(4, 4);
}

class VenueHomePage extends StatefulWidget {
  const VenueHomePage({super.key});

  @override
  State<VenueHomePage> createState() => _VenueHomePageState();
}

class _VenueHomePageState extends State<VenueHomePage> {
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    String userName = 'Venue Owner';

    if (request.jsonData.isNotEmpty &&
        request.jsonData.containsKey('username')) {
      userName = request.jsonData['username'] ?? 'Venue Owner';
    }

    return Scaffold(
      backgroundColor: NeoBrutalism.white,
      drawer: const LeftDrawer(),
      body: Builder(
        builder: (scaffoldContext) {
          return SafeArea(
            child: Column(
              children: [
                _buildCustomHeader(scaffoldContext),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeBanner(userName),
                          const SizedBox(height: 24),
                          const Text(
                            'MENU MANAJEMEN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalism.slate,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMenuGrid(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: NeoBrutalism.primary,
        border: Border(
          bottom: BorderSide(
            color: NeoBrutalism.slate,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu Icon (Drawer Trigger)
          GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(
                  color: NeoBrutalism.slate,
                  width: NeoBrutalism.borderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: NeoBrutalism.slate,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu,
                color: NeoBrutalism.slate,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "VENUE DASHBOARD",
                style: TextStyle(
                  color: NeoBrutalism.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "ALL-AHRAGA",
                style: TextStyle(
                  color: NeoBrutalism.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalism.slate,
            offset: NeoBrutalism.shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeoBrutalism.primary,
                  borderRadius: BorderRadius.circular(
                    NeoBrutalism.borderRadius,
                  ),
                  border: Border.all(
                    color: NeoBrutalism.slate,
                    width: NeoBrutalism.borderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.stadium_outlined, 
                  color: NeoBrutalism.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HALO, ${userName.toUpperCase()}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.slate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kelola fasilitas dan pendapatan venue Anda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: NeoBrutalism.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      primary: false,
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        // DASHBOARD CARD
        _buildMenuCard(
          context,
          icon: Icons.dashboard_outlined,
          title: 'DASHBOARD',
          subtitle: 'Statistik & Booking',
          color: NeoBrutalism.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VenueDashboardPage(),
              ),
            );
          },
        ),

        // REVENUE CARD
        _buildMenuCard(
          context,
          icon: Icons.monetization_on_outlined,
          title: 'REVENUE',
          subtitle: 'Laporan Pendapatan',
          color: const Color(0xFF16a34a), 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VenueRevenuePage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NeoBrutalism.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
          border: Border.all(
            color: NeoBrutalism.slate,
            width: NeoBrutalism.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: NeoBrutalism.slate,
              offset: NeoBrutalism.shadowOffset,
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(
                  color: NeoBrutalism.slate,
                  width: NeoBrutalism.borderWidth,
                ),
              ),
              child: Icon(icon, size: 24, color: NeoBrutalism.white),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.slate,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: NeoBrutalism.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
