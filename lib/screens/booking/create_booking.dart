import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/screens/booking/my_bookings.dart';
import 'package:all_ahraga/constants/api.dart';

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
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredSchedules {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    return _schedules.where((s) => s['date'] == dateStr).toList();
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
        'quantities': _equipmentQuantities.map((k, v) => MapEntry(k.toString(), v)),
        'payment_method': _paymentMethod,
      }),
    );

      if (context.mounted) {
        if (response['success'] == true) {
          _showSuccessDialog();
        } else {
          _showSnackBar(
              response['message'] ?? 'Gagal membuat booking', isError: true);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Berhasil! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking Anda telah dibuat.\nSilahkan lakukan pembayaran.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyBookingsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lihat Booking Saya',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Back to home with refresh
                },
                child: const Text('Kembali ke Home'),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateTotal() {
    double total = (_venue?['price_per_hour'] ?? 0).toDouble();

    for (var eqId in _selectedEquipmentIds) {
      final eq =
          _equipments.firstWhere((e) => e['id'] == eqId, orElse: () => null);
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
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_venue?['name'] ?? 'Booking'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : _error != null
              ? _buildErrorWidget()
              : _buildBookingForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchBookingData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVenueInfoCard(),
                const SizedBox(height: 24),
                _buildDateSelector(),
                const SizedBox(height: 24),
                _buildScheduleSelector(),
                const SizedBox(height: 24),
                _buildCoachSelector(),
                const SizedBox(height: 24),
                if (_equipments.isNotEmpty) _buildEquipmentSelector(),
                const SizedBox(height: 24),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildVenueInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _venue?['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiConstants.baseUrl}${_venue!['image']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.stadium,
                          size: 40,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    )
                  : const Icon(Icons.stadium,
                      size: 40, color: Color(0xFF0D9488)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _venue?['name'] ?? '-',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_venue?['sport_category'] ?? '-'} • ${_venue?['location'] ?? '-'}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice((_venue?['price_per_hour'] ?? 0).toDouble())}/jam',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
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

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pilih Tanggal', Icons.calendar_today),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected = date.year == _selectedDate.year &&
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
                    color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                            [date.weekday - 1],
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        [
                          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                        ][date.month - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isSelected ? Colors.white70 : Colors.grey.shade600,
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

  Widget _buildScheduleSelector() {
    final filteredSchedules = _filteredSchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pilih Jadwal', Icons.access_time),
        const SizedBox(height: 12),
        if (filteredSchedules.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada jadwal untuk tanggal ini',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSchedules.map((schedule) {
              final isSelected = _selectedScheduleId == schedule['id'];
              return ChoiceChip(
                label: Text(
                  '${schedule['start_time']} - ${schedule['end_time']}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedScheduleId = selected ? schedule['id'] : null;
                    _selectedCoachScheduleId = null;
                    _coaches = [];
                  });
                  if (selected) {
                    _fetchAvailableCoaches(schedule['id']);
                  }
                },
                selectedColor: const Color(0xFF0D9488),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCoachSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pilih Coach (Opsional)', Icons.person),
        const SizedBox(height: 12),
        if (_selectedScheduleId == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih jadwal terlebih dahulu',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else if (_isLoadingCoaches)
          const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)))
        else if (_coaches.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada coach tersedia',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          Column(
            children: [
              _buildCoachCard(null, isNoCoach: true),
              ..._coaches.map((coach) => _buildCoachCard(coach)),
            ],
          ),
      ],
    );
  }

  Widget _buildCoachCard(Map<String, dynamic>? coach, {bool isNoCoach = false}) {
    final isSelected = isNoCoach
        ? _selectedCoachScheduleId == null
        : _selectedCoachScheduleId == coach?['coach_schedule_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
          child: isNoCoach
              ? const Icon(Icons.not_interested, color: Colors.grey)
              : const Icon(Icons.person, color: Color(0xFF0D9488)),
        ),
        title: Text(isNoCoach ? 'Tanpa Coach' : (coach?['name'] ?? '-')),
        subtitle: Text(
          isNoCoach
              ? 'Booking tanpa pelatih'
              : 'Rp ${_formatPrice((coach?['rate_per_hour'] ?? 0).toDouble())}/jam',
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF0D9488))
            : null,
        onTap: () {
          setState(() {
            _selectedCoachScheduleId =
                isNoCoach ? null : coach?['coach_schedule_id'];
          });
        },
      ),
    );
  }

  Widget _buildEquipmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sewa Alat (Opsional)', Icons.sports_tennis),
        const SizedBox(height: 12),
        ..._equipments.map((eq) {
          final isSelected = _selectedEquipmentIds.contains(eq['id']);
          final qty = _equipmentQuantities[eq['id']] ?? 1;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isSelected ? const Color(0xFF0D9488) : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedEquipmentIds.add(eq['id']);
                          _equipmentQuantities[eq['id']] = 1;
                        } else {
                          _selectedEquipmentIds.remove(eq['id']);
                          _equipmentQuantities.remove(eq['id']);
                        }
                      });
                    },
                    activeColor: const Color(0xFF0D9488),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eq['name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Rp ${_formatPrice((eq['rental_price'] ?? 0).toDouble())} • Stok: ${eq['stock_quantity']}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20),
                          onPressed: qty > 1
                              ? () => setState(
                                  () => _equipmentQuantities[eq['id']] = qty - 1)
                              : null,
                        ),
                        Text('$qty',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: qty < (eq['stock_quantity'] ?? 1)
                              ? () => setState(
                                  () => _equipmentQuantities[eq['id']] = qty + 1)
                              : null,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Metode Pembayaran', Icons.payment),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Bayar di Tempat (Cash)'),
                subtitle: const Text('Bayar saat datang ke venue'),
                value: 'CASH',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
                activeColor: const Color(0xFF0D9488),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('Transfer Bank'),
                subtitle: const Text('Bayar via transfer'),
                value: 'TRANSFER',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
                activeColor: const Color(0xFF0D9488),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0D9488)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.grey)),
                  Text(
                    'Rp ${_formatPrice(_calculateTotal())}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Konfirmasi',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}