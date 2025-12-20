import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/models/booking_list_entry.dart';
import 'package:all_ahraga/models/review_entry.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/screens/review/review_form_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:all_ahraga/widgets/error_retry_widget.dart';

// PALETTE LIGHT NEO-BRUTALISM
const Color _kBg = Colors.white;
const Color _kSlate = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626);
const Color _kLightGrey = Color(0xFFF1F5F9);
const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
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

  Future<List<BookingListEntry>> fetchBookingHistory(CookieRequest request) async {
    final response = await request.get(ApiConstants.bookingHistory);
    List<BookingListEntry> bookings = [];
    for (var d in response) {
      if (d != null) {
        bookings.add(BookingListEntry.fromJson(d));
      }
    }
    return bookings;
  }

  Future<List<ReviewEntry>> fetchReviews(CookieRequest request, int bookingId) async {
    try {
      final url = ApiConstants.reviewsList(bookingId);
      try {
        final response = await request.get(url);
        List<ReviewEntry> reviews = [];
        if (response is List) {
          for (var d in response) {
            if (d != null) {
              reviews.add(ReviewEntry.fromJson(d));
            }
          }
        }
        return reviews;
      } on FormatException catch (_) {}
      
      final httpResponse = await http.get(
        Uri.parse(url),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"error": "timeout"}', 408),
      );
      
      if (httpResponse.body.contains('<!DOCTYPE') || httpResponse.body.contains('<html')) {
        return [];
      }
      
      if (httpResponse.statusCode == 200) {
        try {
          final jsonData = jsonDecode(httpResponse.body);
          List<ReviewEntry> reviews = [];
          if (jsonData is List) {
            for (var d in jsonData) {
              if (d != null) {
                reviews.add(ReviewEntry.fromJson(d));
              }
            }
          }
          return reviews;
        } catch (e) {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
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
                  "HISTORY AREA",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "RIWAYAT BOOKING",
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
                          hintText: 'CARI VENUE...',
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

                    // Booking History List
                    FutureBuilder<List<BookingListEntry>>(
                      future: fetchBookingHistory(request),
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
                            message: "Gagal memuat riwayat booking.",
                            onRetry: () => setState(() {}),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        final filteredBookings = snapshot.data!.where((booking) {
                          final query = _searchQuery.toLowerCase();
                          return booking.pk.toString().contains(query) ||
                              booking.fields.venueName.toLowerCase().contains(query);
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
                              child: _buildHistoryCard(context, booking, primaryColor),
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
              child: const Icon(Icons.assignment, size: 48, color: _kMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              "BELUM ADA RIWAYAT",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _kSlate,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Mulai booking sekarang!",
              style: TextStyle(fontSize: 14, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, BookingListEntry booking, Color primaryColor) {
    return _buildBrutalBox(
      shadowOffset: 6,
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(
                left: BorderSide(color: Colors.green.shade600, width: 6),
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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                      child: Text(
                        'CONFIRMED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade900,
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
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.calendar_today, "TANGGAL", formatDate(booking.fields.date)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, "WAKTU", "${booking.fields.startTime} - ${booking.fields.endTime}"),
                if (booking.fields.coachName != null && booking.fields.coachName != "-" && booking.fields.coachName != "null") ...[
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL BIAYA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _kMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(booking.fields.totalPrice),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'METODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _kMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
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

          // Review Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kSlate, width: 2)),
              color: _kLightGrey,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FEEDBACK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _kSlate,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ReviewEntry>>(
                  future: fetchReviews(context.read<CookieRequest>(), booking.pk),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final reviews = snapshot.data ?? [];
                    return Column(
                      children: [
                        if (reviews.isNotEmpty)
                          ...reviews.map((review) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReviewCard(context, review),
                          )),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReviewButton(
                                label: reviews.any((r) => r.fields.targetType == 'venue')
                                    ? 'EDIT REVIEW'
                                    : 'REVIEW VENUE',
                                icon: Icons.location_on,
                                color: primaryColor,
                                onPressed: () => _navigateToReviewForm(
                                  context,
                                  context.read<CookieRequest>(),
                                  booking,
                                  'venue',
                                  reviews.firstWhere(
                                    (r) => r.fields.targetType == 'venue',
                                    orElse: () => ReviewEntry(
                                      pk: 0,
                                      fields: ReviewFields(
                                        rating: 0,
                                        comment: '',
                                        targetType: '',
                                        targetName: '',
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                    ),
                                  ).pk == 0 ? null : reviews.firstWhere((r) => r.fields.targetType == 'venue'),
                                ),
                              ),
                            ),
                            if (booking.fields.coachName != null &&
                                booking.fields.coachName != "-" &&
                                booking.fields.coachName != "null") ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReviewButton(
                                  label: reviews.any((r) => r.fields.targetType == 'coach')
                                      ? 'EDIT REVIEW'
                                      : 'REVIEW COACH',
                                  icon: Icons.person,
                                  color: Colors.blue.shade600,
                                  onPressed: () => _navigateToReviewForm(
                                    context,
                                    context.read<CookieRequest>(),
                                    booking,
                                    'coach',
                                    reviews.firstWhere(
                                      (r) => r.fields.targetType == 'coach',
                                      orElse: () => ReviewEntry(
                                        pk: 0,
                                        fields: ReviewFields(
                                          rating: 0,
                                          comment: '',
                                          targetType: '',
                                          targetName: '',
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        ),
                                      ),
                                    ).pk == 0 ? null : reviews.firstWhere((r) => r.fields.targetType == 'coach'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
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
                      color: Colors.white,
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

  Widget _buildReviewCard(BuildContext context, ReviewEntry review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSlate, width: 2),
        boxShadow: const [
          BoxShadow(color: _kSlate, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.fields.targetName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _kSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.fields.targetType == 'venue' ? 'VENUE' : 'COACH',
                      style: const TextStyle(
                        fontSize: 9,
                        color: _kMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showDeleteConfirmation(context, review.pk),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _kRed, width: 2),
                  ),
                  child: const Icon(Icons.delete, color: _kRed, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.fields.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${review.fields.rating}/5',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _kSlate,
                ),
              ),
            ],
          ),
          if (review.fields.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.fields.comment,
              style: const TextStyle(
                fontSize: 12,
                color: _kSlate,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewButton({
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
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadius),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int reviewId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _kSlate, width: 2),
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        title: const Text(
          'HAPUS FEEDBACK?',
          style: TextStyle(color: _kSlate, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Feedback akan dihapus permanen.',
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
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteReview(context, reviewId);
            },
            child: const Text('HAPUS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(BuildContext context, int reviewId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final request = context.read<CookieRequest>();
      final url = ApiConstants.deleteReview(reviewId);
      
      try {
        final response = await request.post(url, {});
        if (response is Map<String, dynamic> && (response['success'] ?? false)) {
          if (mounted) {
            setState(() {});
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Review berhasil dihapus'), backgroundColor: Colors.green),
            );
          }
          return;
        }
      } on FormatException catch (_) {}
      
      final httpResponse = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json',
        },
        body: {},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"error": "timeout"}', 408),
      );
      
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(httpResponse.body);
          if (jsonResponse is Map<String, dynamic> && (jsonResponse['success'] ?? false)) {
            if (mounted) {
              setState(() {});
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Review berhasil dihapus'), backgroundColor: Colors.green),
              );
            }
            return;
          }
        } catch (e) {}
      }
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Gagal menghapus review')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _navigateToReviewForm(
    BuildContext context,
    CookieRequest request,
    BookingListEntry booking,
    String target,
    ReviewEntry? existingReview,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewFormPage(
          bookingId: booking.pk,
          target: target,
          targetName: target == 'venue' ? booking.fields.venueName : (booking.fields.coachName ?? ''),
          booking: booking,
          reviewId: existingReview?.pk,
          initialRating: existingReview?.fields.rating ?? 0,
          initialComment: existingReview?.fields.comment ?? '',
        ),
      ),
    ).then((_) => setState(() {}));
  }
}