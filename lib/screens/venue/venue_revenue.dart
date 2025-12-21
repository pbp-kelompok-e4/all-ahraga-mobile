

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';

class NeoColors {
  static const Color primary = Color(0xFF0D9488); 
  static const Color text = Color(0xFF0F172A);    
  static const Color muted = Color(0xFF64748B);   
  static const Color danger = Color(0xFFDC2626); 
  static const Color background = Colors.white;
}

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

class NeoButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = NeoColors.primary,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoContainer(
      onTap: onPressed,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
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
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: NeoColors.text, width: 2)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: NeoColors.text, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back, color: NeoColors.text),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "LAPORAN PENDAPATAN",
                      style: TextStyle(
                        color: NeoColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: NeoColors.text,
                backgroundColor: NeoColors.primary,
                child: FutureBuilder(
                  future: _revenueFuture,
                  builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: NeoColors.text),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: NeoColors.text, size: 60),
                            const SizedBox(height: 16),
                            const Text(
                              "GAGAL MEMUAT DATA",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                "${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: NeoColors.muted),
                              ),
                            ),
                            const SizedBox(height: 24),
                            NeoButton(
                              label: "COBA LAGI",
                              onPressed: _refreshData,
                              backgroundColor: NeoColors.text,
                            )
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData) {
                      return const Center(
                        child: Text("TIDAK ADA DATA", style: TextStyle(fontWeight: FontWeight.bold)),
                      );
                    } else {
                      final data = snapshot.data!;
                      final double totalRevenue = (data['total_revenue'] ?? 0).toDouble();
                      final List<dynamic> venuesData = data['venue_revenue_data'] ?? [];

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // TOTAL REVENUE CARD
                          NeoContainer(
                            color: NeoColors.primary,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text(
                                  "TOTAL PENDAPATAN",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCurrency(totalRevenue),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          const Text(
                            "RINCIAN PER VENUE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.text,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (venuesData.isEmpty)
                            NeoContainer(
                              padding: const EdgeInsets.all(20),
                              child: const Center(
                                child: Text(
                                  "Belum ada venue terdaftar.",
                                  style: TextStyle(color: NeoColors.muted),
                                ),
                              ),
                            )
                          else
                            ...venuesData.map((venue) {
                              final venueName = venue['venue_name'];
                              final venueRevenue = venue['total_revenue'];
                              final bookingCount = venue['booking_count'];
                              final List<dynamic> bookings = venue['bookings'] ?? [];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: NeoContainer(
                                  padding: EdgeInsets.zero,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent, 
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      iconColor: NeoColors.text,
                                      collapsedIconColor: NeoColors.text,
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDFA),
                                          border: Border.all(color: NeoColors.text, width: 2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.stadium, color: NeoColors.primary),
                                      ),
                                      title: Text(
                                        venueName.toString().toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: NeoColors.text,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(venueRevenue),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: NeoColors.primary,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            "$bookingCount BOOKING",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: NeoColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              top: BorderSide(color: NeoColors.text, width: 2),
                                            ),
                                            color: Color(0xFFF8FAFC), 
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "RIWAYAT TRANSAKSI",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: NeoColors.muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              if (bookings.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    "- Belum ada booking terkonfirmasi -",
                                                    style: TextStyle(
                                                      fontStyle: FontStyle.italic,
                                                      color: NeoColors.muted,
                                                    ),
                                                  ),
                                                )
                                              else
                                                ...bookings.map((booking) {
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(color: Colors.grey.shade300),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // DATE & TIME
                                                        Expanded(
                                                          flex: 3,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                booking['date'],
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13,
                                                                  color: NeoColors.text,
                                                                ),
                                                              ),
                                                              Text(
                                                                "${booking['start_time']} - ${booking['end_time']}",
                                                                style: const TextStyle(fontSize: 11, color: NeoColors.muted),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        // CUSTOMER INFO
                                                        Expanded(
                                                          flex: 4,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                booking['customer_username'],
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: NeoColors.text,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              if (booking['coach'] != null)
                                                                Text(
                                                                  "Coach: ${booking['coach']}",
                                                                  style: const TextStyle(
                                                                    fontSize: 11,
                                                                    color: NeoColors.primary,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        // PRICE
                                                        Expanded(
                                                          flex: 3,
                                                          child: Text(
                                                            _formatCurrency(booking['revenue']),
                                                            textAlign: TextAlign.end,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w900, 
                                                              color: NeoColors.primary,
                                                              fontSize: 13
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
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