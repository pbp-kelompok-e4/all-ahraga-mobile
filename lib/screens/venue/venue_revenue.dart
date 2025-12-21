import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:intl/intl.dart';

class NeoColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Colors.white;
  static const Color success = Color(0xFF16a34a);
  static const Color warning = Color(0xFFf59e0b);
}

class VenueRevenuePage extends StatefulWidget {
  const VenueRevenuePage({super.key});

  @override
  State<VenueRevenuePage> createState() => _VenueRevenuePageState();
}

class _VenueRevenuePageState extends State<VenueRevenuePage> {
  late Future<Map<String, dynamic>> _revenueFuture;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _revenueFuture = _fetchRevenue(request);
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<Map<String, dynamic>> _fetchRevenue(CookieRequest request) async {
    final url = ApiConstants.venueRevenue;

    try {
      final response = await request.get(url);
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception("Gagal memuat data pendapatan.");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<void> _refreshData() async {
    final request = context.read<CookieRequest>();
    setState(() {
      _revenueFuture = _fetchRevenue(request);
    });
    await _revenueFuture;
  }

  // --- HEADER (Style Coach Revenue) ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: NeoColors.background,
        border: Border(bottom: BorderSide(color: NeoColors.text, width: 2.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.text, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.text,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: NeoColors.text,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "VENUE REVENUE",
                    style: TextStyle(
                      color: NeoColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "LAPORAN PENDAPATAN",
                    style: TextStyle(
                      color: NeoColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Refresh Button
          GestureDetector(
            onTap: _refreshData,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NeoColors.text, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: NeoColors.text,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.refresh, color: NeoColors.text, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // --- TOTAL REVENUE CARD (Style Coach Revenue) ---
  Widget _buildTotalRevenueCard(double totalRevenue, int totalBookingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeoColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeoColors.text, width: 2),
        boxShadow: const [
          BoxShadow(color: NeoColors.text, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PENDAPATAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(totalRevenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dari $totalBookingCount total booking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.text, width: 2),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 40,
              color: NeoColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // --- VENUE ITEM (Expandable) ---
  Widget _buildVenueItem(BuildContext context, dynamic venue) {
    final venueName = venue['venue_name'];
    final venueRevenue = venue['total_revenue'];
    final bookingCount = venue['booking_count'];
    final List<dynamic> bookings = venue['bookings'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeoColors.text, width: 2),
        boxShadow: const [
          BoxShadow(color: NeoColors.text, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          iconColor: NeoColors.text,
          collapsedIconColor: NeoColors.text,
          // Custom Leading Icon (Stadium)
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.text, width: 2),
            ),
            child: const Icon(
              Icons.stadium,
              color: NeoColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            venueName.toString().toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: NeoColors.text,
              letterSpacing: 0.5,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _formatCurrency(venueRevenue),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$bookingCount BOOKING",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: NeoColors.muted,
                ),
              ),
            ],
          ),
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: NeoColors.text, width: 2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: NeoColors.muted,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "RIWAYAT TRANSAKSI",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: NeoColors.muted,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (bookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: Text(
                          "Belum ada booking terkonfirmasi",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: NeoColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ...bookings.map((booking) => _buildBookingItem(booking)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOOKING ITEM (Inner List) ---
  Widget _buildBookingItem(dynamic booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NeoColors.text, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE2E8F0),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: NeoColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking['date'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: NeoColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: NeoColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${booking['start_time']} - ${booking['end_time']}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: NeoColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Customer Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['customer_username'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (booking['coach'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Coach: ${booking['coach']}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0369A1),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Price
          Expanded(
            flex: 3,
            child: Text(
              _formatCurrency(booking['revenue']),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: NeoColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeoButton({
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: NeoColors.text, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: NeoColors.text, width: 2),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(), // Updated Header

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: NeoColors.text,
                backgroundColor: NeoColors.primary,
                child: FutureBuilder(
                  future: _revenueFuture,
                  builder:
                      (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: NeoColors.text,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: NeoColors.danger,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "GAGAL MEMUAT DATA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: NeoColors.text,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    "${snapshot.error}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: NeoColors.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildNeoButton(
                                  onPressed: _refreshData,
                                  label: "COBA LAGI",
                                ),
                              ],
                            ),
                          );
                        } else if (!snapshot.hasData) {
                          return const Center(
                            child: Text(
                              "TIDAK ADA DATA",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        } else {
                          final data = snapshot.data!;
                          final double totalRevenue =
                              (data['total_revenue'] ?? 0).toDouble();
                          final List<dynamic> venuesData =
                              data['venue_revenue_data'] ?? [];

                          // Calculate total bookings
                          int totalBookings = 0;
                          for (var v in venuesData) {
                            totalBookings += (v['booking_count'] as int? ?? 0);
                          }

                          return ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              _buildTotalRevenueCard(
                                totalRevenue,
                                totalBookings,
                              ),

                              const SizedBox(height: 32),
                              const Text(
                                "RINCIAN PER VENUE",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: NeoColors.text,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (venuesData.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: NeoColors.text,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Belum ada venue terdaftar.",
                                      style: TextStyle(
                                        color: NeoColors.muted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...venuesData.map(
                                  (venue) => _buildVenueItem(context, venue),
                                ),

                              const SizedBox(height: 20),
                            ],
                          );
                        }
                      },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
