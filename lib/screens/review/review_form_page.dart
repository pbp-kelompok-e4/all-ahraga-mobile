import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/models/booking_list_entry.dart';
import 'package:intl/intl.dart';

// --- Constants untuk Styling (Disamakan dengan Booking History) ---
const Color _kBg = Colors.white;
const Color _kSlate = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626);
const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

class ReviewFormPage extends StatefulWidget {
  final int bookingId;
  final String target;
  final String targetName;
  final BookingListEntry booking;
  final int? reviewId;
  final int initialRating;
  final String initialComment;

  const ReviewFormPage({
    super.key,
    required this.bookingId,
    required this.target,
    required this.targetName,
    required this.booking,
    this.reviewId,
    this.initialRating = 0,
    this.initialComment = '',
  });

  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  late int _rating;
  late TextEditingController _commentController;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- Header Widget (Style Booking History) ---
  Widget _buildHeader(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isEditing = widget.reviewId != null || widget.initialRating > 0;

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
                    BoxShadow(
                      color: _kSlate,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: _kSlate, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'EDIT REVIEW' : 'BERI REVIEW',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    widget.targetName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kSlate,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SUBMIT REVIEW
  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5) {
      setState(() => _error = "Pilih rating 1–5 dulu ya.");
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      setState(() => _error = "Komentar tidak boleh kosong.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final request = context.read<CookieRequest>();

      if (!request.loggedIn) {
        setState(
          () => _error = 'Anda harus login dulu untuk memberikan review',
        );
        return;
      }

      final url = ApiConstants.upsertReview(
        widget.bookingId,
        target: widget.target,
      );

      final body = {
        'rating': _rating.toString(),
        'comment': _commentController.text.trim(),
      };

      try {
        final response = await request.post(url, body);

        if (response is Map<String, dynamic>) {
          final success = response['success'] ?? false;
          final message = response['message'] ?? '';

          if (success) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            Navigator.pop(context, 'saved');
            return;
          } else {
            setState(
              () => _error = message.isNotEmpty
                  ? message
                  : 'Gagal menyimpan review',
            );
            return;
          }
        }
      } on FormatException {
        // Fallback
      }

      final httpResponse = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json',
        },
        body: body,
      );

      try {
        final responseData =
            jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final success = responseData['success'] ?? false;
        final message = responseData['message'] ?? '';

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          Navigator.pop(context, 'saved');
        } else {
          setState(
            () => _error = message.isNotEmpty
                ? message
                : 'Gagal menyimpan review',
          );
        }
      } catch (e) {
        if (httpResponse.body.contains('<!DOCTYPE')) {
          setState(
            () => _error =
                'Django error ${httpResponse.statusCode}: Login ulang?',
          );
        } else {
          setState(() => _error = 'Invalid response: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // DELETE REVIEW
  Future<void> _deleteReview() async {
    final id = widget.reviewId;
    if (id == null) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'BATAL',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _kMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'HAPUS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    if (!mounted) return;

    try {
      final request = context.read<CookieRequest>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (!request.loggedIn) {
        setState(() => _error = 'Anda harus login dulu untuk menghapus review');
        return;
      }

      final url = ApiConstants.deleteReview(id);

      try {
        final response = await request.post(url, {});
        if (response is Map<String, dynamic> &&
            (response['success'] ?? false)) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, 'deleted');
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
      );

      final responseData =
          jsonDecode(httpResponse.body) as Map<String, dynamic>;
      if (responseData['success'] ?? false) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'deleted');
      } else {
        setState(
          () => _error = responseData['message'] ?? 'Gagal menghapus feedback',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: _kBg,
      // Menggunakan Column agar Header Sticky di atas
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Info Card
                  _buildBookingInfoCard(booking),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_kRadius),
                        border: Border.all(color: _kRed, width: _kBorderWidth),
                        boxShadow: const [
                          BoxShadow(
                            color: _kSlate,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Rating Section
                  _buildRatingSection(),
                  const SizedBox(height: 24),

                  // Comment Section
                  _buildCommentSection(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),

                  // Bottom Padding safe area
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard(BookingListEntry booking) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSlate, width: _kBorderWidth),
        boxShadow: const [
          BoxShadow(color: _kSlate, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488), // Teal tetap digunakan untuk aksen
              border: Border(
                bottom: BorderSide(color: _kSlate, width: _kBorderWidth),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: const Text(
              'BOOKING DETAILS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.fields.venueName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _kSlate,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: _kSlate),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'd MMMM yyyy',
                          'id_ID',
                        ).format(booking.fields.date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSlate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: _kSlate),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${booking.fields.startTime} - ${booking.fields.endTime}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSlate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (booking.fields.coachName != null &&
                    booking.fields.coachName != "-" &&
                    booking.fields.coachName != "null") ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: _kSlate),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coach: ${booking.fields.coachName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kSlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSlate, width: _kBorderWidth),
        boxShadow: const [
          BoxShadow(color: _kSlate, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFB923C),
              border: Border(
                bottom: BorderSide(color: _kSlate, width: _kBorderWidth),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: const Text(
              'RATING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final star = index + 1;
                final isFilled = _rating >= star;
                return GestureDetector(
                  onTap: _loading ? null : () => setState(() => _rating = star),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: const Color(0xFFFB923C),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSlate, width: _kBorderWidth),
        boxShadow: const [
          BoxShadow(color: _kSlate, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              border: Border(
                bottom: BorderSide(color: _kSlate, width: _kBorderWidth),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: const Text(
              'KOMENTAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _commentController,
              enabled: !_loading,
              minLines: 5,
              maxLines: 6,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Bagikan pengalaman Anda...',
                hintStyle: TextStyle(color: _kMuted, fontSize: 13),
                contentPadding: EdgeInsets.all(8),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: _kSlate,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.reviewId != null) ...[
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _loading ? null : _deleteReview,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: _kRed, width: _kBorderWidth),
                  boxShadow: const [
                    BoxShadow(
                      color: _kSlate,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: const Center(
                  child: Text(
                    'HAPUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _kRed,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _loading ? null : _submitReview,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(_kRadius),
                border: Border.all(color: _kSlate, width: _kBorderWidth),
                boxShadow: const [
                  BoxShadow(
                    color: _kSlate,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.reviewId != null ? 'PERBARUI' : 'KIRIM',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
