import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/widgets/left_drawer.dart'; // Pastikan path benar
import 'package:all_ahraga/screens/admin/admin_users.dart';
import 'package:all_ahraga/screens/admin/admin_coaches.dart';
import 'package:all_ahraga/screens/admin/admin_venues.dart';
import 'package:all_ahraga/screens/admin/admin_bookings.dart';

class NeoBrutalism {
  static const Color primary = Color(0xFF0D9488);
  static const Color slate = Color(0xFF0F172A);
  static const Color white = Colors.white;
  static const double borderWidth = 2.0;
  static const double borderRadius = 8.0;
  static const Offset shadowOffset = Offset(4, 4);
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  Map<String, dynamic> _stats = {
    'total_users': 0,
    'total_venues': 0,
    'total_coaches': 0,
    'total_bookings': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(ApiConstants.adminDashboard);
      setState(() {
        _stats = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching admin stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: RefreshIndicator(
                    onRefresh: _fetchStats,
                    color: NeoBrutalism.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeBanner(),
                          const SizedBox(height: 24),
                          const Text(
                            'STATISTIK SISTEM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalism.slate,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: NeoBrutalism.primary,
                                  ),
                                )
                              : _buildStatsGrid(),
                          const SizedBox(height: 24),
                          const Text(
                            'MANAJEMEN DATA',
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

  Widget _buildStatsGrid() {
    return GridView.count(
      primary: false,
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCardWithIcon(
          "Total User",
          _stats['total_users'].toString(),
          Colors.blue,
          Icons.people,
        ),
        _buildStatCardWithIcon(
          "Total Venue",
          _stats['total_venues'].toString(),
          Colors.green,
          Icons.stadium,
        ),
        _buildStatCardWithIcon(
          "Total Coach",
          _stats['total_coaches'].toString(),
          Colors.indigo,
          Icons.sports_gymnastics,
        ),
        _buildStatCardWithIcon(
          "Total Booking",
          _stats['total_bookings'].toString(),
          Colors.teal,
          Icons.receipt_long,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(color: NeoBrutalism.slate, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoBrutalism.slate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          "Kelola Pengguna",
          "Lihat semua user terdaftar",
          Icons.people,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminUsersPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context,
          "Kelola Pelatih",
          "Verifikasi dan lihat data pelatih",
          Icons.sports_gymnastics,
          Colors.cyan,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminCoachesPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context,
          "Kelola Venue",
          "Daftar lapangan dan pemilik",
          Icons.stadium,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminVenuesPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context,
          "Kelola Booking",
          "Riwayat transaksi sistem",
          Icons.receipt_long,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminBookingsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardWithIcon(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(color: NeoBrutalism.slate, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            ),
            child: Icon(icon, color: NeoBrutalism.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: NeoBrutalism.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            ),
          ],
        ),
        child: Row(
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
              child: Icon(icon, color: NeoBrutalism.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.slate,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: NeoBrutalism.slate,
            ),
          ],
        ),
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
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(
                  color: NeoBrutalism.slate,
                  width: NeoBrutalism.borderWidth,
                ),
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
                "ADMIN PANEL",
                style: TextStyle(
                  color: Colors.white70,
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

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeoBrutalism.primary,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalism.slate,
            offset: NeoBrutalism.shadowOffset,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HALO, ADMIN!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Selamat datang di panel kontrol administrator.",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
