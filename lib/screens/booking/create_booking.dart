import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/screens/booking/my_bookings.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/widgets/error_retry_widget.dart';

const Color _kBg = Colors.white;
const Color _kSlate = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626);
const Color _kLightGrey = Color(0xFFF1F5F9);
const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

class CreateBookingPage extends StatefulWidget {
  final int venueId;

  const CreateBookingPage({super.key, required this.venueId});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  Map<String, dynamic>? _venue;
  List<dynamic> _schedules = [];
  List<dynamic> _equipments = [];
  List<dynamic> _coaches = [];

  int? _selectedScheduleId;
  int? _selectedCoachScheduleId;
  Set<int> _selectedEquipmentIds = {};
  Map<int, int> _equipmentQuantities = {};
  String _paymentMethod = 'CASH';

  DateTime _selectedDate = DateTime.now();
  List<DateTime> _availableDates = [];

  bool _isLoading = true;
  bool _isLoadingCoaches = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookingData();
    });
  }

  void _generateDates() {
    _availableDates = List.generate(30, (index) {
      return DateTime.now().add(Duration(days: index));
    });
  }

  Future<void> _fetchBookingData() async {
    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        ApiConstants.bookingForm(widget.venueId),
      );

      if (response['success'] == true) {
        setState(() {
          _venue = response['venue'];
          _schedules = response['schedules'] ?? [];
          _equipments = response['equipments'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Koneksi terputus. Silakan periksa internet Anda.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredSchedules {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final dateNow = DateTime.now();
    final isToday =
        _selectedDate.year == dateNow.year &&
        _selectedDate.month == dateNow.month &&
        _selectedDate.day == dateNow.day;

    return _schedules.where((s) {
      if (s['date'] != dateStr) return false;
      if (s['is_booked'] == true) return false;

      if (isToday) {
        try {
          final timeParts = s['start_time'].toString().split(':');
          final int startHour = int.parse(timeParts[0]);
          final int startMinute = int.parse(timeParts[1]);
          final scheduleTime = DateTime(
            dateNow.year,
            dateNow.month,
            dateNow.day,
            startHour,
            startMinute,
          );
          return scheduleTime.isAfter(dateNow);
        } catch (e) {
          return true;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _fetchAvailableCoaches(int scheduleId) async {
    setState(() {
      _isLoadingCoaches = true;
      _coaches = [];
      _selectedCoachScheduleId = null;
    });

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        ApiConstants.scheduledCoaches(scheduleId),
      );

      if (response['success'] == true) {
        setState(() {
          _coaches = response['coaches'] ?? [];
          _isLoadingCoaches = false;
        });
      } else {
        setState(() {
          _isLoadingCoaches = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCoaches = false;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedScheduleId == null) {
      _showSnackBar('Pilih jadwal terlebih dahulu!', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final request = context.read<CookieRequest>();

    try {
      final response = await request.postJson(
        ApiConstants.createBooking(widget.venueId),
        jsonEncode({
          'schedule_id': _selectedScheduleId,
          'coach_schedule_id': _selectedCoachScheduleId,
          'equipment': _selectedEquipmentIds.toList(),
          'quantities': _equipmentQuantities.map(
            (k, v) => MapEntry(k.toString(), v),
          ),
          'payment_method': _paymentMethod,
        }),
      );

      if (context.mounted) {
        if (response['success'] == true) {
          _showSuccessDialog();
        } else {
          _showSnackBar(
            response['message'] ?? 'Gagal membuat booking',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showSuccessDialog() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _kSlate, width: 2),
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade600, width: 3),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'BOOKING BERHASIL!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _kSlate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Booking telah dibuat.\nSilahkan lakukan pembayaran.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_kRadius),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyBookingsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kRadius),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: const Text(
                      'LIHAT BOOKING',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'KEMBALI KE HOME',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _kMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateTotal() {
    double total = 0;

    if (_selectedScheduleId != null) {
      total += (_venue?['price_per_hour'] ?? 0).toDouble();
    }

    for (var eqId in _selectedEquipmentIds) {
      final eq = _equipments.firstWhere(
        (e) => e['id'] == eqId,
        orElse: () => null,
      );
      if (eq != null) {
        int qty = _equipmentQuantities[eqId] ?? 1;
        total += (eq['rental_price'] ?? 0).toDouble() * qty;
      }
    }

    if (_selectedCoachScheduleId != null) {
      final coach = _coaches.firstWhere(
        (c) => c['coach_schedule_id'] == _selectedCoachScheduleId,
        orElse: () => null,
      );
      if (coach != null) {
        total += (coach['rate_per_hour'] ?? 0).toDouble();
      }
    }

    return total;
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
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
                    "CREATE BOOKING",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    _venue?['name'] ?? 'Loading...',
                    style: const TextStyle(
                      color: _kSlate,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(primaryColor),
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          else if (_error != null)
            Expanded(
              child: ErrorRetryWidget(
                message: _error!,
                onRetry: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchBookingData();
                },
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVenueInfoCard(primaryColor),
                          const SizedBox(height: 24),
                          _buildDateSelector(primaryColor),
                          const SizedBox(height: 24),
                          _buildScheduleSelector(primaryColor),
                          const SizedBox(height: 24),
                          _buildCoachSelector(primaryColor),
                          const SizedBox(height: 24),
                          if (_equipments.isNotEmpty)
                            _buildEquipmentSelector(primaryColor),
                          const SizedBox(height: 24),
                          _buildPaymentMethodSelector(primaryColor),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(primaryColor),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVenueInfoCard(Color primaryColor) {
    String? rawImage = _venue?['image'];
    String? imageUrl;
    if (rawImage != null && rawImage.isNotEmpty) {
      if (rawImage.startsWith('http')) {
        imageUrl = rawImage; 
      } else {
        imageUrl =
            '${ApiConstants.baseUrl}$rawImage'; 
      }
    }

    return _buildBrutalBox(
      shadowOffset: 4,
      padding: const EdgeInsets.all(20),
      bgColor: primaryColor.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: primaryColor, width: 2),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(_kRadius - 2),
                    child: Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.stadium, size: 40, color: primaryColor),
                    ),
                  )
                : Icon(Icons.stadium, size: 40, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _venue?['name'] ?? '-',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_venue?['sport_category'] ?? '-'} • ${_venue?['location'] ?? '-'}',
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_formatPrice((_venue?['price_per_hour'] ?? 0).toDouble())}/jam',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _kSlate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH TANGGAL:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _kSlate,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedScheduleId = null;
                    _coaches = [];
                    _selectedCoachScheduleId = null;
                  });
                },
                child: Container(
                  width: 65,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(_kRadius),
                    border: Border.all(
                      color: isSelected ? primaryColor : _kSlate,
                      width: _kBorderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryColor.withOpacity(0.4)
                            : _kSlate,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        [
                          'SEN',
                          'SEL',
                          'RAB',
                          'KAM',
                          'JUM',
                          'SAB',
                          'MIN',
                        ][date.weekday - 1],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : _kMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : _kSlate,
                        ),
                      ),
                      Text(
                        [
                          'JAN',
                          'FEB',
                          'MAR',
                          'APR',
                          'MEI',
                          'JUN',
                          'JUL',
                          'AGU',
                          'SEP',
                          'OKT',
                          'NOV',
                          'DES',
                        ][date.month - 1],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : _kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSelector(Color primaryColor) {
    final filteredSchedules = _filteredSchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH JADWAL:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _kSlate,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (filteredSchedules.isEmpty)
          _buildBrutalBox(
            shadowOffset: 3,
            padding: const EdgeInsets.all(24),
            bgColor: _kLightGrey,
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.event_busy, size: 48, color: _kMuted),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada jadwal',
                    style: TextStyle(
                      color: _kMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSchedules.map((schedule) {
              final isSelected = _selectedScheduleId == schedule['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedScheduleId = schedule['id'];
                    _selectedCoachScheduleId = null;
                    _coaches = [];
                  });
                  _fetchAvailableCoaches(schedule['id']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(_kRadius),
                    border: Border.all(
                      color: isSelected ? primaryColor : _kSlate,
                      width: _kBorderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryColor.withOpacity(0.4)
                            : _kSlate,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    '${schedule['start_time']} - ${schedule['end_time']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : _kSlate,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCoachSelector(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH COACH (OPSIONAL):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _kSlate,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedScheduleId == null)
          _buildBrutalBox(
            shadowOffset: 3,
            padding: const EdgeInsets.all(16),
            bgColor: _kLightGrey,
            child: const Text(
              'Pilih jadwal terlebih dahulu',
              style: TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
            ),
          )
        else if (_isLoadingCoaches)
          Center(child: CircularProgressIndicator(color: primaryColor))
        else if (_coaches.isEmpty)
          _buildBrutalBox(
            shadowOffset: 3,
            padding: const EdgeInsets.all(16),
            bgColor: _kLightGrey,
            child: const Text(
              'Tidak ada coach tersedia',
              style: TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
            ),
          )
        else
          Column(
            children: [
              _buildCoachCard(null, primaryColor, isNoCoach: true),
              ..._coaches.map((coach) => _buildCoachCard(coach, primaryColor)),
            ],
          ),
      ],
    );
  }

  Widget _buildCoachCard(
    Map<String, dynamic>? coach,
    Color primaryColor, {
    bool isNoCoach = false,
  }) {
    final isSelected = isNoCoach
        ? _selectedCoachScheduleId == null
        : _selectedCoachScheduleId == coach?['coach_schedule_id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCoachScheduleId = isNoCoach
              ? null
              : coach?['coach_schedule_id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(
            color: isSelected ? primaryColor : _kSlate,
            width: _kBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryColor.withOpacity(0.3) : _kSlate,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : _kLightGrey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : _kSlate,
                  width: 2,
                ),
              ),
              child: Icon(
                isNoCoach ? Icons.not_interested : Icons.person,
                color: isSelected ? Colors.white : _kMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNoCoach ? 'TANPA COACH' : (coach?['name'] ?? '-'),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isSelected ? primaryColor : _kSlate,
                    ),
                  ),
                  Text(
                    isNoCoach
                        ? 'Booking tanpa pelatih'
                        : 'Rp ${_formatPrice((coach?['rate_per_hour'] ?? 0).toDouble())}/jam',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSelector(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEWA ALAT (OPSIONAL):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _kSlate,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ..._equipments.map((eq) {
          final isSelected = _selectedEquipmentIds.contains(eq['id']);
          final qty = _equipmentQuantities[eq['id']] ?? 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: isSelected ? primaryColor : _kSlate,
                width: _kBorderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? primaryColor.withOpacity(0.3) : _kSlate,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedEquipmentIds.remove(eq['id']);
                        _equipmentQuantities.remove(eq['id']);
                      } else {
                        _selectedEquipmentIds.add(eq['id']);
                        _equipmentQuantities[eq['id']] = 1;
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _kSlate, width: 2),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eq['name'] ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: isSelected ? primaryColor : _kSlate,
                        ),
                      ),
                      Text(
                        'Rp ${_formatPrice((eq['rental_price'] ?? 0).toDouble())} • Stok: ${eq['stock_quantity']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: qty > 1
                            ? () => setState(
                                () => _equipmentQuantities[eq['id']] = qty - 1,
                              )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: qty > 1 ? _kLightGrey : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _kSlate, width: 2),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: qty > 1 ? _kSlate : _kMuted,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _kSlate,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: qty < (eq['stock_quantity'] ?? 1)
                            ? () => setState(
                                () => _equipmentQuantities[eq['id']] = qty + 1,
                              )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: qty < (eq['stock_quantity'] ?? 1)
                                ? _kLightGrey
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _kSlate, width: 2),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: qty < (eq['stock_quantity'] ?? 1)
                                ? _kSlate
                                : _kMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'METODE PEMBAYARAN:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _kSlate,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _paymentMethod = 'CASH'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _paymentMethod == 'CASH'
                      ? primaryColor.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(
                    color: _paymentMethod == 'CASH' ? primaryColor : _kSlate,
                    width: _kBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _paymentMethod == 'CASH'
                          ? primaryColor.withOpacity(0.3)
                          : _kSlate,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'CASH'
                            ? primaryColor
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kSlate, width: 2),
                      ),
                      child: _paymentMethod == 'CASH'
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BAYAR DI TEMPAT',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: _paymentMethod == 'CASH'
                                  ? primaryColor
                                  : _kSlate,
                            ),
                          ),
                          const Text(
                            'Bayar saat datang ke venue',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _paymentMethod = 'TRANSFER'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _paymentMethod == 'TRANSFER'
                      ? primaryColor.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(
                    color: _paymentMethod == 'TRANSFER'
                        ? primaryColor
                        : _kSlate,
                    width: _kBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _paymentMethod == 'TRANSFER'
                          ? primaryColor.withOpacity(0.3)
                          : _kSlate,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'TRANSFER'
                            ? primaryColor
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kSlate, width: 2),
                      ),
                      child: _paymentMethod == 'TRANSFER'
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRANSFER BANK',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: _paymentMethod == 'TRANSFER'
                                  ? primaryColor
                                  : _kSlate,
                            ),
                          ),
                          const Text(
                            'Bayar via transfer',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                              fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildBottomBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kSlate, width: 2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: _kMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice(_calculateTotal())}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kRadius),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitting ? _kMuted : primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_kRadius),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'KONFIRMASI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
