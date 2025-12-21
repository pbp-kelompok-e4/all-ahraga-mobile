import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/models/booking_list_entry.dart';
import 'package:intl/intl.dart';

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
      
      final isLoggedIn = request.loggedIn;
      
      if (!isLoggedIn) {
        setState(() => _error = 'Anda harus login dulu untuk memberikan review');
        return;
      }

      final url = ApiConstants.upsertReview(widget.bookingId, target: widget.target);

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
            setState(() => _error = message.isNotEmpty ? message : 'Gagal menyimpan review');
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
        body: body,
      );

      try {
        final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final success = responseData['success'] ?? false;
        final message = responseData['message'] ?? '';

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          Navigator.pop(context, 'saved');
        } else {
          setState(() => _error = message.isNotEmpty ? message : 'Gagal menyimpan review');
        }
      } catch (e) {
        if (httpResponse.body.contains('<!DOCTYPE')) {
          setState(() => _error = 'Django error ${httpResponse.statusCode}: Login ulang?');
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

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Feedback?'),
            content: const Text('Feedback akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
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
      
      final isLoggedIn = request.loggedIn;
      
      if (!isLoggedIn) {
        setState(() => _error = 'Anda harus login dulu untuk menghapus review');
        return;
      }

      final url = ApiConstants.deleteReview(id);

      try {
        final response = await request.post(url, {});

        if (response is Map<String, dynamic>) {
          final success = response['success'] ?? false;
          final message = response['message'] ?? '';
          
          if (success) {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            Navigator.pop(context, 'deleted');
            return;
          } else {
            setState(() => _error = message.isNotEmpty ? message : 'Gagal menghapus feedback');
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
      );

      try {
        final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final success = responseData['success'] ?? false;
        final message = responseData['message'] ?? '';

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          Navigator.pop(context, 'deleted');
        } else {
          setState(() => _error = message.isNotEmpty ? message : 'Gagal menghapus feedback');
        }
      } catch (e) {
        if (httpResponse.body.contains('<!DOCTYPE')) {
          setState(() => _error = 'Django error ${httpResponse.statusCode}: Login ulang?');
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reviewId != null || widget.initialRating > 0;
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Review' : 'Beri Review'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Booking Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0D9488),
                            const Color(0xFF0D9488).withValues(alpha: 0.9),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BOOKING DETAILS',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.fields.venueName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Venue Details Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date dan Time
                          Row(
                            children: [
                              // Date Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDFA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF0D9488),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: const Color(0xFF0D9488),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Tanggal',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF0D9488),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('d MMMM', 'id_ID').format(booking.fields.date),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('yyyy', 'id_ID').format(booking.fields.date),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Time Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Waktu',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        booking.fields.startTime,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        'sampai ${booking.fields.endTime}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Coach
                          if (booking.fields.coachName != null &&
                              booking.fields.coachName != "-" &&
                              booking.fields.coachName != "null") ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF7C3AED),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pelatih',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          booking.fields.coachName ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Target info badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.target == 'venue'
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.target == 'venue'
                        ? const Color(0xFFD8B4FE)
                        : const Color(0xFFD8B4FE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.target == 'venue'
                          ? Icons.location_on
                          : Icons.person,
                      size: 14,
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Review ${widget.target.toUpperCase()} - ${widget.targetName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rating Section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                        (i) {
                          final idx = i + 1;
                          return GestureDetector(
                            onTap: _loading ? null : () => setState(() => _rating = idx),
                            child: Icon(
                              idx <= _rating ? Icons.star : Icons.star_border,
                              size: 42,
                              color: const Color(0xFFDEA31B),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '$_rating / 5',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Comment Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    enabled: !_loading,
                    minLines: 5,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ceritakan pengalamanmu...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF0D9488),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ],
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Delete button 
              if (widget.reviewId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _deleteReview,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      'Hapus Feedback',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submitReview,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(widget.reviewId != null ? Icons.update : Icons.check, size: 20),
                  label: Text(
                    _loading
                        ? 'Menyimpan...'
                        : (widget.reviewId != null ? 'Perbarui Feedback' : 'Kirim Feedback'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
