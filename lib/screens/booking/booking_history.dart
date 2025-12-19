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

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
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
      } on FormatException {
      }
      
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Riwayat Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama venue atau ID booking ...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ),

            FutureBuilder<List<BookingListEntry>>(
              future: fetchBookingHistory(request),
              builder: (context, AsyncSnapshot<List<BookingListEntry>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text("Error: ${snapshot.error}"))),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            "Anda belum memiliki riwayat booking",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Text(
                            "Mulai booking venue dan coach favorit Anda sekarang!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredBookings = snapshot.data!.where((booking) {
                  final query = _searchQuery.toLowerCase();
                  return booking.pk.toString().contains(query) ||
                         booking.fields.venueName.toLowerCase().contains(query);
                }).toList();

                if (filteredBookings.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text("Tidak ditemukan."))));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildHistoryCard(context, filteredBookings[index]);
                    },
                    childCount: filteredBookings.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, BookingListEntry booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFF2563EB), width: 5),  
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking #${booking.pk}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.fields.venueName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB), 
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    "Tanggal",
                    formatDate(booking.fields.date),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    "Waktu",
                    "${booking.fields.startTime} - ${booking.fields.endTime}",
                  ),
                  
                  if (booking.fields.coachName != null && booking.fields.coachName != "-" && booking.fields.coachName != "null") ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.person_outline,
                      "Coach",
                      booking.fields.coachName!,
                    ),
                  ],

                  if (booking.fields.equipments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildEquipmentRow(booking.fields.equipments),
                  ],
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            Padding(
              padding: const EdgeInsets.all(12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF), 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "TOTAL BIAYA",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatCurrency(booking.fields.totalPrice),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),

                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50, 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "METODE PEMBAYARAN",
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.fields.paymentMethod.toUpperCase(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      flex: 3, 
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50, 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "STATUS PEMBAYARAN",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7), 
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      "BOOKING TERKONFIRMASI",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534), 
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feedback',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<ReviewEntry>>(
                    future: fetchReviews(context.read<CookieRequest>(), booking.pk),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final reviews = snapshot.data ?? [];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1E7FF), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reviews.isNotEmpty) ...[
                              ...reviews.map((review) => _buildReviewCard(context, review)),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
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
                                    icon: const Icon(Icons.location_on, size: 16),
                                    label: Text(
                                      reviews.any((r) => r.fields.targetType == 'venue') 
                                        ? 'Edit Review Venue' 
                                        : 'Beri Review Venue',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (booking.fields.coachName != null &&
                                    booking.fields.coachName != "-" &&
                                    booking.fields.coachName != "null")
                                  Expanded(
                                    child: ElevatedButton.icon(
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
                                      icon: const Icon(Icons.person, size: 16),
                                      label: Text(
                                        reviews.any((r) => r.fields.targetType == 'coach') 
                                          ? 'Edit Review Coach' 
                                          : 'Beri Review Coach',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.3),
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
        Icon(Icons.inbox_outlined, size: 20, color: Colors.grey.shade500), 
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Peralatan",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: equipments.map((eq) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${eq.name} ×${eq.quantity}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        review.fields.targetName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.fields.targetType == 'venue' ? '📍 Venue' : '👤 Coach',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 24),
                  onPressed: () => _showDeleteConfirmation(context, review.pk),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: 'Hapus review',
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review.fields.rating ? Icons.star : Icons.star_border,
                            size: 20,
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${review.fields.rating}/5',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  _formatDate(review.fields.updatedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (review.fields.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.fields.comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int reviewId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Feedback?'),
        content: const Text('Feedback akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteReview(context, reviewId);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _deleteReview(BuildContext context, int reviewId) async {
    try {
      final request = context.read<CookieRequest>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final url = ApiConstants.deleteReview(reviewId);
      
      String errorMessage = '';
      bool success = false;
      
      try {
        final response = await request.post(url, {});
        
        if (response is Map<String, dynamic>) {
          success = response['success'] ?? false;
          
          if (success) {
            if (mounted) {
              setState(() {});
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Review berhasil dihapus')),
              );
            }
            return;
          }
        }
      } on FormatException {
      }
      
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
      
      if (httpResponse.body.contains('<!DOCTYPE') || httpResponse.body.contains('<html')) {
        errorMessage = 'Server returned HTML instead of JSON';
      } else if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(httpResponse.body);
          
          if (jsonResponse is Map<String, dynamic>) {
            success = jsonResponse['success'] ?? false;
            final message = jsonResponse['message'] ?? '';
            
            if (success) {
              if (mounted) {
                setState(() {});
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Review berhasil dihapus')),
                );
              }
              return;
            } else {
              errorMessage = message.isNotEmpty ? message : 'Delete failed';
            }
          }
        } catch (e) {
          errorMessage = 'Failed to parse delete response';
        }
      } else if (httpResponse.statusCode == 404) {
        errorMessage = 'Review not found';
      } else if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) {
        errorMessage = 'You do not have permission to delete this review';
      } else {
        errorMessage = 'Delete failed with status ${httpResponse.statusCode}';
      }
      
      if (errorMessage.isNotEmpty && mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal menghapus review: $errorMessage')),
        );
      }
    } catch (e) {
      if (mounted) {
        try {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Gagal menghapus review: $e')),
          );
        } catch (_) {
        }
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
    ).then((_) {
      setState(() {});
    });
  }
}
