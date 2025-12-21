import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:all_ahraga/widgets/error_retry_widget.dart';

const Color _kBg = Colors.white;
const Color _kSlate = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626);
const Color _kLightGrey = Color(0xFFF1F5F9);
const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

class UpdateBookingPage extends StatefulWidget {
  final int bookingId;
  final int venueScheduleId;

  const UpdateBookingPage({
    super.key,
    required this.bookingId,
    required this.venueScheduleId,
  });

  @override
  State<UpdateBookingPage> createState() => _UpdateBookingPageState();
}

class _UpdateBookingPageState extends State<UpdateBookingPage> {
  Map<String, dynamic>? _bookingDetail;
  Map<String, dynamic>? _venue;
  Map<String, dynamic>? _currentSchedule;
  List<Map<String, dynamic>> _availableSchedules = [];
  List<Map<String, dynamic>> _equipments = [];
  List<Map<String, dynamic>> _coaches = [];

  int? _selectedScheduleId;
  int? _selectedCoachScheduleId;
  Set<int> _selectedEquipmentIds = {};
  Map<int, int> _equipmentQuantities = {};
  String _paymentMethod = 'CASH';

  bool _isLoading = true;
  bool _isLoadingCoaches = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookingDetail();
    });
  }

  Future<void> _fetchBookingDetail() async {
    final request = context.read<CookieRequest>();

    try {
      final detailResponse = await request.get(
        ApiConstants.bookingDetail(widget.bookingId),
      );

      if (detailResponse['success'] == true) {
        _bookingDetail = detailResponse['booking'] as Map<String, dynamic>?;
        final venueId = _bookingDetail?['venue_id'];

        if (venueId == null) {
          setState(() {
            _error = 'venue_id tidak ditemukan';
            _isLoading = false;
          });
          return;
        }

        final formResponse = await request.get(
          ApiConstants.bookingForm(venueId),
        );

        if (formResponse['success'] == true) {
          final allSchedules = (formResponse['schedules'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];
          
          final equipmentsList = (formResponse['equipments'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];

          final currentScheduleId = _bookingDetail?['schedule_id'];
          Map<String, dynamic>? foundSchedule;
          for (var s in allSchedules) {
            if (s['id'] == currentScheduleId) {
              foundSchedule = s;
              break;
            }
          }
          _currentSchedule = foundSchedule;

          List<Map<String, dynamic>> filteredSchedules = [];
          if (_currentSchedule != null) {
            final bookingDate = _currentSchedule!['date'];
            for (var s in allSchedules) {
              if (s['date'] == bookingDate) {
                bool isAvailable = s['is_booked'] == false;
                bool isMySchedule = s['id'] == currentScheduleId;
                if (isAvailable || isMySchedule) {
                  filteredSchedules.add(s);
                }
              }
            }
          }

          setState(() {
            _venue = formResponse['venue'] as Map<String, dynamic>?;
            _equipments = equipmentsList;
            _availableSchedules = filteredSchedules;
            
            _selectedScheduleId = currentScheduleId;
            _selectedCoachScheduleId = _bookingDetail?['coach_schedule_id'];
            _paymentMethod = _bookingDetail?['payment_method'] ?? 'CASH';
            
            final existingEquipments = _bookingDetail?['equipments'] as List? ?? [];
            for (var eq in existingEquipments) {
              if (eq is Map) {
                final eqId = eq['id'];
                if (eqId != null) {
                  _selectedEquipmentIds.add(eqId);
                  _equipmentQuantities[eqId] = eq['quantity'] ?? 1;
                }
              }
            }
            
            _isLoading = false;
          });

          if (_selectedScheduleId != null) {
            _fetchAvailableCoaches(_selectedScheduleId!);
          }
        } else {
          setState(() {
            _error = formResponse['message'] ?? 'Gagal memuat data venue';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = detailResponse['message'] ?? 'Gagal memuat detail booking';
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

  Future<void> _fetchAvailableCoaches(int scheduleId) async {
    setState(() => _isLoadingCoaches = true);

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        ApiConstants.scheduledCoaches(
          scheduleId,
          editingBookingId: widget.bookingId,
        ),
      );

      if (response['success'] == true) {
        final coachesList = (response['coaches'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? [];
        
        if (_selectedCoachScheduleId != null) {
          bool coachStillAvailable = coachesList.any(
            (coach) => coach['coach_schedule_id'] == _selectedCoachScheduleId
          );
          if (!coachStillAvailable) {
            _selectedCoachScheduleId = null;
          }
        }
        
        setState(() {
          _coaches = coachesList;
          _isLoadingCoaches = false;
        });
      } else {
        setState(() {
          _coaches = [];
          _selectedCoachScheduleId = null;
          _isLoadingCoaches = false;
        });
      }
    } catch (e) {
      setState(() {
        _coaches = [];
        _selectedCoachScheduleId = null;
        _isLoadingCoaches = false;
      });
    }
  }

  Future<void> _updateBooking() async {
    if (_selectedScheduleId == null) {
      _showSnackBar('Pilih jadwal terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = context.read<CookieRequest>();
      
      final data = {
        'schedule_id': _selectedScheduleId.toString(),
        'coach_schedule_id': _selectedCoachScheduleId?.toString() ?? '',
        'equipment': _selectedEquipmentIds.map((id) => id.toString()).toList(),
        'quantities': _equipmentQuantities.map((k, v) => MapEntry(k.toString(), v.toString())),
        'payment_method': _paymentMethod,
      };

      final response = await request.post(
        ApiConstants.updateBooking(widget.bookingId),
        jsonEncode(data),
      );

      if (!context.mounted) return;

      if (response['success'] == true) {
        _showSuccessDialog();
      } else {
        _showSnackBar(
          response['message'] ?? 'Gagal mengupdate booking.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      builder: (BuildContext ctx) {
        final primaryColor = Theme.of(context).colorScheme.primary;
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
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade600, width: 3),
                ),
                child: Icon(Icons.check_circle, color: Colors.blue.shade600, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'UPDATE BERHASIL!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kSlate),
              ),
              const SizedBox(height: 8),
              const Text(
                'Booking telah diperbarui.',
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
                      Navigator.pop(context, true);
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
                    child: const Text('KEMBALI', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
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
      Map<String, dynamic>? eq;
      for (var e in _equipments) {
        if (e['id'] == eqId) {
          eq = e;
          break;
        }
      }
      if (eq != null) {
        int qty = _equipmentQuantities[eqId] ?? 1;
        total += (eq['rental_price'] ?? 0).toDouble() * qty;
      }
    }

    if (_selectedCoachScheduleId != null) {
      Map<String, dynamic>? coach;
      for (var c in _coaches) {
        if (c['coach_schedule_id'] == _selectedCoachScheduleId) {
          coach = c;
          break;
        }
      }
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

  Widget _buildBrutalBox({
    required Widget child,
    Color bgColor = Colors.white,
    Color borderColor = _kSlate,
    double shadowOffset = 4.0,
    EdgeInsets? padding,
  }) {
    return Container(
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
                  "EDIT MODE",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'BOOKING #${widget.bookingId}',
                  style: const TextStyle(
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(primaryColor),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: _kSlate)),
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
                  _fetchBookingDetail();
                },
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Info Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: primaryColor.withOpacity(0.05),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit booking Anda. Perubahan disimpan setelah tekan UPDATE.',
                            style: TextStyle(
                              color: _kSlate,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentBookingInfo(primaryColor),
                          const SizedBox(height: 24),
                          _buildScheduleDropdown(),
                          const SizedBox(height: 20),
                          _buildCoachDropdown(),
                          const SizedBox(height: 20),
                          _buildPaymentMethodDropdown(),
                          const SizedBox(height: 20),
                          _buildEquipmentSelector(),
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

  Widget _buildCurrentBookingInfo(Color primaryColor) {
    return _buildBrutalBox(
      shadowOffset: 4,
      padding: const EdgeInsets.all(20),
      bgColor: primaryColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKING SAAT INI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _kMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _venue?['name'] ?? 'Venue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_venue?['sport_category'] ?? ''} • ${_venue?['location'] ?? ''}',
            style: const TextStyle(
              color: _kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 24, thickness: 2, color: _kSlate),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _kMuted),
              const SizedBox(width: 8),
              Text(
                'Waktu: ${_currentSchedule?['start_time'] ?? '-'} - ${_currentSchedule?['end_time'] ?? '-'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _kSlate,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH JADWAL BARU:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _kSlate, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        _buildBrutalBox(
          shadowOffset: 3,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<int>(
              value: _selectedScheduleId,
              isExpanded: true,
              hint: const Text('Pilih jadwal', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w700)),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: _kSlate, width: _kBorderWidth),
                ),
              ),
              style: const TextStyle(color: _kSlate, fontWeight: FontWeight.w700),
              items: _availableSchedules.map<DropdownMenuItem<int>>((schedule) {
                final scheduleId = schedule['id'] as int;
                final isCurrent = scheduleId == widget.venueScheduleId;
                return DropdownMenuItem<int>(
                  value: scheduleId,
                  child: Text(
                    '${isCurrent ? "(NOW) " : ""}${schedule['start_time']} - ${schedule['end_time']}',
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                      color: _kSlate,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedScheduleId = value;
                  _selectedCoachScheduleId = null;
                  _coaches = [];
                });
                if (value != null) {
                  _fetchAvailableCoaches(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH COACH (OPSIONAL):',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _kSlate, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        _buildBrutalBox(
          shadowOffset: 3,
          padding: _isLoadingCoaches ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _isLoadingCoaches
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kSlate),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedCoachScheduleId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: _kSlate, fontWeight: FontWeight.w700),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tanpa Coach', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      ..._coaches.map<DropdownMenuItem<int?>>((coach) {
                        return DropdownMenuItem<int?>(
                          value: coach['coach_schedule_id'] as int?,
                          child: Text(
                            '${coach['name']} - Rp ${_formatPrice((coach['rate_per_hour'] ?? 0).toDouble())}/jam',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCoachScheduleId = value);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'METODE PEMBAYARAN:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _kSlate, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        _buildBrutalBox(
          shadowOffset: 3,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paymentMethod,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: _kSlate, fontWeight: FontWeight.w700),
              items: const [
                DropdownMenuItem(
                  value: 'CASH',
                  child: Text('Cash (Bayar di Tempat)', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                DropdownMenuItem(
                  value: 'TRANSFER',
                  child: Text('Transfer Bank', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH PERALATAN:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _kSlate, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        if (_equipments.isEmpty)
          _buildBrutalBox(
            shadowOffset: 3,
            padding: const EdgeInsets.all(20),
            bgColor: _kLightGrey,
            child: const Text(
              'Tidak ada peralatan tersedia.',
              style: TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
            ),
          )
        else
          _buildBrutalBox(
            shadowOffset: 3,
            child: Column(
              children: List.generate(_equipments.length, (index) {
                final eq = _equipments[index];
                final eqId = eq['id'] as int;
                final isSelected = _selectedEquipmentIds.contains(eqId);
                final qty = _equipmentQuantities[eqId] ?? 1;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedEquipmentIds.remove(eqId);
                                  _equipmentQuantities.remove(eqId);
                                } else {
                                  _selectedEquipmentIds.add(eqId);
                                  _equipmentQuantities[eqId] = 1;
                                }
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
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
                                  eq['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _kSlate,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatPrice((eq['rental_price'] ?? 0).toDouble())} • Stok: ${eq['stock_quantity'] ?? 0}',
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
                                  onTap: qty > 1 ? () => setState(() => _equipmentQuantities[eqId] = qty - 1) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: qty > 1 ? _kLightGrey : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _kSlate, width: 2),
                                    ),
                                    child: Icon(Icons.remove, size: 16, color: qty > 1 ? _kSlate : _kMuted),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: _kSlate),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: qty < (eq['stock_quantity'] ?? 1)
                                      ? () => setState(() => _equipmentQuantities[eqId] = qty + 1)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: qty < (eq['stock_quantity'] ?? 1) ? _kLightGrey : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _kSlate, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: qty < (eq['stock_quantity'] ?? 1) ? _kSlate : _kMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (index < _equipments.length - 1)
                      const Divider(height: 1, thickness: 2, color: _kSlate),
                  ],
                );
              }),
            ),
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
                    'TOTAL BIAYA',
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
                  onPressed: _isSubmitting ? null : _updateBooking,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'UPDATE',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
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