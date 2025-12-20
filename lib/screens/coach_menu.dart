import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/widgets/left_drawer.dart';
import 'package:all_ahraga/screens/coach/coach_profile.dart';
import 'package:all_ahraga/screens/coach/coach_list.dart';
import 'package:all_ahraga/screens/coach/coach_revenue.dart';
import 'package:all_ahraga/screens/coach/coach_manage_schedule.dart';

// Design System Constants
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

class CoachHomePage extends StatefulWidget {
  const CoachHomePage({super.key});

  @override
  State<CoachHomePage> createState() => _CoachHomePageState();
}

class _CoachHomePageState extends State<CoachHomePage> {
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    String userName = 'Coach';

    // Logika pengambilan nama user
    if (request.jsonData.isNotEmpty &&
        request.jsonData.containsKey('username')) {
      userName = request.jsonData['username'] ?? 'Coach';
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
          // Menu Icon (Drawer)
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
                "COACH DASHBOARD",
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
                  Icons.emoji_events,
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
                      'Kelola profil dan jadwal pelatihan Anda',
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
        // Profil Pelatih Card
        _buildMenuCard(
          context,
          icon: Icons.person,
          title: 'PROFIL SAYA',
          subtitle: 'Kelola profil pelatih',
          color: NeoBrutalism.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoachProfilePage()),
            );
          },
        ),

        // Daftar Pelatih Card
        _buildMenuCard(
          context,
          icon: Icons.list_alt,
          title: 'DAFTAR PELATIH',
          subtitle: 'Lihat data pelatih',
          color: const Color(0xFF0891B2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoachListPage()),
            );
          },
        ),

        // Pendapatan Card
        _buildMenuCard(
          context,
          icon: Icons.monetization_on,
          title: 'PENDAPATAN',
          subtitle: 'Laporan pendapatan',
          color: const Color(0xFF16a34a),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoachRevenuePage()),
            );
          },
        ),

        // Jadwal Pelatihan Card
        _buildMenuCard(
          context,
          icon: Icons.calendar_month,
          title: 'JADWAL',
          subtitle: 'Kelola jadwal saya',
          color: const Color(0xFF7c3aed),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CoachSchedulePage(),
              ),
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
        padding: const EdgeInsets.all(
          8,
        ), // Kurangi sedikit padding luar (dari 12 ke 8)
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
              padding: const EdgeInsets.all(10), // Kurangi padding icon sedikit
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(
                  color: NeoBrutalism.slate,
                  width: NeoBrutalism.borderWidth,
                ),
              ),
              child: Icon(
                icon,
                size: 24, // Kurangi size icon sedikit (dari 28 ke 24)
                color: NeoBrutalism.white,
              ),
            ),
            const SizedBox(height: 10),
            // Gunakan Flexible agar teks tidak memaksa ruang berlebih
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
