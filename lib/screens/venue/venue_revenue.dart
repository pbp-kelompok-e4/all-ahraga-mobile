import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';

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
      appBar: AppBar(
        title: const Text("Laporan Pendapatan", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D9488),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder(
          future: _revenueFuture,
          builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text("${snapshot.error}", textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text("Coba Lagi"),
                        )
                      ],
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Tidak ada data."));
            } else {
              final data = snapshot.data!;
              final double totalRevenue = (data['total_revenue'] ?? 0).toDouble();
              final List<dynamic> venuesData = data['venue_revenue_data'] ?? [];

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFF0D9488),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          const Text(
                            "Total Pendapatan Keseluruhan",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(totalRevenue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    "Rincian per Venue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  if (venuesData.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Belum ada venue yang terdaftar."),
                    ))
                  else
                    ...venuesData.map((venue) {
                      final venueName = venue['venue_name'];
                      final venueRevenue = venue['total_revenue'];
                      final bookingCount = venue['booking_count'];
                      final List<dynamic> bookings = venue['bookings'] ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          shape: const Border(),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.stadium, color: Color(0xFF0D9488)),
                          ),
                          title: Text(
                            venueName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Revenue: ${_formatCurrency(venueRevenue)}"),
                              Text("$bookingCount Booking Confirmed"),
                            ],
                          ),
                          children: [
                            Container(
                              color: Colors.grey[50],
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Riwayat Transaksi",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 10),
                                  if (bookings.isEmpty)
                                    const Text("- Belum ada booking terkonfirmasi -", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))
                                  else
                                    ...bookings.map((booking) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    booking['date'],
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                  Text(
                                                    "${booking['start_time']} - ${booking['end_time']}",
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    booking['customer_username'],
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (booking['coach'] != null)
                                                    Text(
                                                      "Coach: ${booking['coach']}",
                                                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                _formatCurrency(booking['revenue']),
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold, 
                                                  color: Color(0xFF0D9488),
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
                      );
                    }),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}