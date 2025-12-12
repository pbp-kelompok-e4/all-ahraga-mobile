import 'package:flutter/material.dart';
import 'package:all_ahraga/screens/menu.dart';
import 'package:all_ahraga/screens/booking/my_bookings.dart';
import 'package:all_ahraga/screens/booking/booking_history.dart';
import 'package:all_ahraga/screens/coach/coach_list.dart';
import 'package:all_ahraga/screens/coach/coach_revenue.dart';
import 'package:all_ahraga/screens/coach/coach_manage_schedule.dart';
import 'package:all_ahraga/screens/coach/coach_profile.dart';
import 'package:all_ahraga/screens/venue_menu.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    String userRole = 'CUSTOMER';
    if (request.jsonData.isNotEmpty && request.jsonData.containsKey('role_type')) {
      userRole = request.jsonData['role_type']; 
    }

    bool isVenueOwner = userRole == 'VENUE_OWNER';
    bool isCoach = userRole == 'COACH';
    bool showBookingMenu = !isCoach && !isVenueOwner;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  "ALL-AHRAGA",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Booking Venue Olahraga",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Home
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text("Home"),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            },
          ),

          const Divider(),
          if (showBookingMenu) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'BOOKING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
            ),

            // My Bookings
            ListTile(
              leading: const Icon(Icons.assignment, color: Color(0xFFEA580C)),
              title: const Text("Bookingan Saya"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyBookingsPage()),
                );
              },
            ),

            // Booking History
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF0D9488)),
              title: const Text("Riwayat Booking"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryPage(),
                  ),
                );
              },
            ),
          ],

          // Coach
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'COACH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
          ),

          // // Daftar Pelatih
          // ListTile(
          //   leading: const Icon(
          //     Icons.groups_outlined,
          //     color: Color(0xFF0D9488),
          //   ),
          //   title: const Text("Daftar Pelatih"),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const CoachListPage()),
          //     );
          //   },
          // ),

          // // Laporan Pendapatan
          // ListTile(
          //   leading: const Icon(
          //     Icons.monetization_on_outlined,
          //     color: Color(0xFF0D9488),
          //   ),
          //   title: const Text("Laporan"),
          //   subtitle: const Text("Pendapatan Pelatih"),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const CoachRevenuePage(),
          //       ),
          //     );
          //   },
          // ),

          // // Jadwal Kamu
          // ListTile(
          //   leading: const Icon(
          //     Icons.calendar_month_outlined,
          //     color: Color(0xFF0D9488),
          //   ),
          //   title: const Text("Jadwal Kamu"),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const CoachSchedulePage(),
          //       ),
          //     );
          //   },
          // ),

          // // Profile Kamu
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF0D9488)),
            title: const Text("Profile Kamu"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachProfilePage(),
                ),
              );
            },
          ),

          // const Divider(),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   child: Text(
          //     'LAINNYA',
          //     style: TextStyle(
          //       fontSize: 12,
          //       fontWeight: FontWeight.bold,
          //       color: Colors.grey.shade600,
          //       letterSpacing: 1,
          //     ),
          //   ),
          // ),
          if (isVenueOwner) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'VENUE OWNER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF0D9488)),
            title: const Text("Venue Dashboard"),
            onTap: () {
              // Tutup drawer dulu
              Navigator.pop(context); 
              // Arahkan ke dashboard venue
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VenueHomePage(), // Atau langsung ke VenueDashboardPage()
                ),
              );
            },
          ), 
          ]     
        ],
      ),
    );
  }
}
