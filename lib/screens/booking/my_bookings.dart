import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/models/booking_list_entry.dart';
import 'package:all_ahraga/screens/booking/update_booking.dart';
import 'package:all_ahraga/constants/api.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:all_ahraga/screens/booking/customer_payment.dart';
import 'package:all_ahraga/widgets/error_retry_widget.dart';

const Color _kBg = Colors.white;
const Color _kSlate = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626);
const Color _kLightGrey = Color(0xFFF1F5F9);
const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLocaleReady = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await initializeDateFormatting('id_ID', null);
    if (!mounted) return;
    setState(() => _isLocaleReady = true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String formatCurrency(String value) {
    try {
      final double amount = double.parse(value);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (e) {
      return "Rp $value";
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  Future<List<BookingListEntry>> fetchMyBookings(CookieRequest request) async {
    final response = await request.get(ApiConstants.myBookings);
    List<BookingListEntry> bookings = [];
    for (var d in response) {
      if (d != null) {
        bookings.add(BookingListEntry.fromJson(d));
      }
    }
    return bookings;
  }

  Widget _buildBrutalBox({
    required Widget child,
    VoidCallback? onTap,
    Color bgColor = Colors.white,
    Color borderColor = _kSlate,
    double shadowOffset = 4.0,
    EdgeInsets? padding,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: borderColor, width: _kBorderWidth),
          boxShadow: [
            BoxShadow(
              color: _kSlate,
              offset: Offset(shadowOffset, shadowOffset),
              blurRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kSlate, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: _kSlate, width: _kBorderWidth),
                  boxShadow: const [
                    BoxShadow(color: _kSlate, offset: Offset(2, 2), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: _kSlate, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PAYMENT AREA",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "BOOKINGAN SAYA",
                  style: TextStyle(
                    color: _kSlate,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleReady) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final request = context.watch<CookieRequest>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(primaryColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Box
                    _buildBrutalBox(
                      shadowOffset: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                        style: const TextStyle(
                          color: _kSlate,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'CARI BOOKING...',
                          hintStyle: TextStyle(
                            color: _kMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: _kMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Booking List
                    FutureBuilder(
                      future: fetchMyBookings(request),
                      builder: (context, AsyncSnapshot<List<BookingListEntry>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: primaryColor),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return ErrorRetryWidget(
                            message: "Gagal memuat bookingan.",
                            onRetry: () => setState(() {}),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        final filteredBookings = snapshot.data!.where((booking) {
                          if (booking.fields.isPaid) return false;
                          if (_searchQuery.isEmpty) return true;
                          return booking.pk.toString().contains(_searchQuery) ||
                              booking.fields.venueName.toLowerCase().contains(_searchQuery);
                        }).toList();

                        if (filteredBookings.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                "TIDAK ADA HASIL",
                                style: TextStyle(
                                  color: _kMuted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: filteredBookings.map((booking) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildBookingCard(context, booking, request, primaryColor),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kLightGrey,
                borderRadius: BorderRadius.circular(_kRadius),
                border: Border.all(color: _kSlate, width: _kBorderWidth),
              ),
              child: const Icon(Icons.check_circle_outline, size: 48, color: _kMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              "TIDAK ADA BOOKING",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _kSlate,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Semua booking sudah lunas!",
              style: TextStyle(fontSize: 14, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    BookingListEntry booking,
    CookieRequest request,
    Color primaryColor,
  ) {
    return _buildBrutalBox(
      shadowOffset: 6,
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              border: Border(
                left: BorderSide(color: primaryColor, width: 6),
                bottom: const BorderSide(color: _kSlate, width: _kBorderWidth),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BOOKING #${booking.pk}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _kMuted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade700, width: 2),
                      ),
                      child: Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  booking.fields.venueName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today, "TANGGAL", formatDate(booking.fields.date)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, "WAKTU", "${booking.fields.startTime} - ${booking.fields.endTime}"),
                if (booking.fields.coachName != null && booking.fields.coachName != "-") ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, "COACH", booking.fields.coachName!),
                ],
                if (booking.fields.equipments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildEquipmentRow(booking.fields.equipments),
                ],
                const SizedBox(height: 20),
                
                // Payment Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kLightGrey,
                    borderRadius: BorderRadius.circular(_kRadius),
                    border: Border.all(color: _kSlate, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL BIAYA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _kMuted,
                            ),
                          ),
                          Text(
                            formatCurrency(booking.fields.totalPrice),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'METODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kMuted,
                            ),
                          ),
                          Text(
                            booking.fields.paymentMethod.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _kSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kSlate, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Edit Booking',
                    icon: Icons.edit,
                    color: Colors.blue.shade600,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateBookingPage(
                            bookingId: booking.pk,
                            venueScheduleId: booking.fields.venueSchedule,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Bayar Sekarang',
                    icon: Icons.payment,
                    color: Colors.green.shade600,
                    onPressed: () {
                      if (booking.fields.paymentMethod.toUpperCase() == 'CASH') {
                        _confirmCashPayment(booking.pk, request);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerPaymentPage(
                              bookingId: booking.pk,
                              paymentMethod: booking.fields.paymentMethod,
                              totalPrice: booking.fields.totalPrice,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Cancel Booking',
                    icon: Icons.close,
                    color: _kRed,
                    onPressed: () => _showCancelDialog(context, booking, request),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _kMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _kMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kSlate,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentRow(List<EquipmentItem> equipments) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sports_soccer, size: 18, color: _kMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERALATAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _kMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: equipments.map((eq) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kLightGrey,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _kSlate, width: 2),
                    ),
                    child: Text(
                      '${eq.name} ×${eq.quantity}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kSlate,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadius),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, BookingListEntry booking, CookieRequest request) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _kSlate, width: 2),
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        title: const Text(
          'HAPUS BOOKING?',
          style: TextStyle(color: _kSlate, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Booking akan dibatalkan permanen.',
          style: TextStyle(color: _kSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.bold, color: _kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final response = await request.post(ApiConstants.cancelBooking(booking.pk), {});
                if (!context.mounted) return;
                if (response['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking #${booking.pk} dibatalkan'), backgroundColor: Colors.green),
                  );
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message'] ?? 'Gagal'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('HAPUS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCashPayment(int bookingId, CookieRequest request) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );

    try {
      final response = await request.postJson(
        ApiConstants.confirmPayment(bookingId),
        jsonEncode({}),
      );
      if (!mounted) return;
      Navigator.pop(context);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Pembayaran berhasil!'), backgroundColor: Colors.green),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}