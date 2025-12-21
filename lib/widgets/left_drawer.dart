import 'package:flutter/material.dart';
import 'package:all_ahraga/screens/menu.dart';
import 'package:all_ahraga/screens/booking/my_bookings.dart';
import 'package:all_ahraga/screens/booking/booking_history.dart';
import 'package:all_ahraga/screens/coach/coach_list.dart';
import 'package:all_ahraga/screens/coach/coach_revenue.dart';
import 'package:all_ahraga/screens/coach/coach_manage_schedule.dart';
import 'package:all_ahraga/screens/coach/coach_profile.dart';
import 'package:all_ahraga/screens/venue_menu.dart';
import 'package:all_ahraga/screens/venue/venue_revenue.dart';
import 'package:all_ahraga/screens/auth_page.dart';
import 'package:all_ahraga/constants/api.dart';
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
        padding: EdgeInsets.zero,
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
                const Icon(
                  Icons.sports_soccer,
                  size: 48,
                  color: Colors.white,
                ),
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
          if (userRole == 'CUSTOMER') ...[
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text("Home"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(),
                  ),
                );
              },
            ),
          ],
          
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
          if (isCoach) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
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
          ],

          if (isCoach) ...[
            // Daftar Pelatih
            ListTile(
              leading: const Icon(
                Icons.groups_outlined,
                color: Color(0xFF0D9488),
              ),
              title: const Text("Daftar Pelatih"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CoachListPage()),
                );
              },
            ),

            // Laporan Pendapatan
            ListTile(
              leading: const Icon(
                Icons.monetization_on_outlined,
                color: Color(0xFF0D9488),
              ),
              title: const Text("Laporan Pendapatan"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoachRevenuePage(),
                  ),
                );
              },
            ),

            // Jadwal Saya
            ListTile(
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF0D9488),
              ),
              title: const Text("Jadwal Saya"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoachSchedulePage(),
                  ),
                );
              },
            ),

            // Profil Saya
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF0D9488)),
              title: const Text("Profil Saya"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoachProfilePage(),
                  ),
                );
              },
            ),
          ],
          if (isVenueOwner) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
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
              Navigator.pop(context); 
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VenueHomePage(), 
                ),
              );
            },
          ),

          // Venue Revenue
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined, color: Color(0xFF0D9488)),
            title: const Text("Laporan Pendapatan"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VenueRevenuePage(),
                ),
              );
            },
          ),
          ],
          
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Color(0xFFEA580C)),
            title: const Text("Logout"),
            onTap: () async {
              final response = await request.logout(
                  ApiConstants.authLogout);
              String message = response["message"];
              if (context.mounted) {
                if (response['status']) {
                  String uname = response["username"];
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("$message See you again, $uname."),
                  ));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}