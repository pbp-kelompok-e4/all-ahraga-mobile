import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:http/http.dart' as http;

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
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAvailableCoaches(int scheduleId) async {
    setState(() {
      _isLoadingCoaches = true;
    });

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        ApiConstants.scheduledCoaches(scheduleId),
      );

      if (response['success'] == true) {
        final coachesList = (response['coaches'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? [];
        setState(() {
          _coaches = coachesList;
          _isLoadingCoaches = false;
        });
      } else {
        setState(() {
          _coaches = [];
          _isLoadingCoaches = false;
        });
      }
    } catch (e) {
      setState(() {
        _coaches = [];
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
        'schedule_id': _selectedScheduleId,
        'coach_schedule_id': _selectedCoachScheduleId,
        'equipment': _selectedEquipmentIds.toList(),
        'quantities': _equipmentQuantities.map((k, v) => MapEntry(k.toString(), v)),
        'payment_method': _paymentMethod,
      };

      String csrfTokenValue = request.cookies['csrftoken']?.toString() ?? "";
      String cookieHeader = request.cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');

      final response = await http.put(
        Uri.parse(ApiConstants.updateBooking(widget.bookingId)),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': csrfTokenValue,
          'Cookie': cookieHeader,
        },
        body: jsonEncode(data),
      );

      if (!context.mounted) return;

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        throw Exception("Gagal memproses respon server (Status: ${response.statusCode})");
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        _showSuccessDialog();
      } else {
        _showSnackBar(
          responseData['message'] ?? 'Gagal mengupdate booking. Kode: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.blue.shade600, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('Update Berhasil! ✨',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Booking Anda telah diperbarui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Booking #${widget.bookingId}'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _error != null
              ? _buildErrorWidget()
              : _buildUpdateForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchBookingDetail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateForm() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Anda sedang mengedit booking. Perubahan akan disimpan setelah menekan tombol Update.',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentBookingInfo(),
                const SizedBox(height: 24),
                _buildScheduleDropdown(),
                const SizedBox(height: 24),
                _buildCoachDropdown(),
                const SizedBox(height: 24),
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 24),
                _buildEquipmentSelector(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildCurrentBookingInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stadium, color: Color(0xFF2563EB), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_venue?['name'] ?? 'Venue',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${_venue?['sport_category'] ?? ''} • ${_venue?['location'] ?? ''}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Tanggal: ', style: TextStyle(color: Colors.grey.shade600)),
                Text(_formatDate(_currentSchedule?['date']),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Waktu saat ini: ', style: TextStyle(color: Colors.grey.shade600)),
                Text('${_currentSchedule?['start_time'] ?? '-'} - ${_currentSchedule?['end_time'] ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Jadwal Baru:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedScheduleId,
              isExpanded: true,
              hint: const Text('Pilih jadwal'),
              items: _availableSchedules.map<DropdownMenuItem<int>>((schedule) {
                final isCurrent = schedule['id'] == widget.venueScheduleId;
                return DropdownMenuItem<int>(
                  value: schedule['id'] as int,
                  child: Text(
                    '${isCurrent ? "(Saat ini) " : ""}${schedule['start_time']} - ${schedule['end_time']}',
                    style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
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
        const Text('Pilih Coach (opsional):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingCoaches
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedCoachScheduleId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Tanpa Coach')),
                      ..._coaches.map<DropdownMenuItem<int?>>((coach) {
                        return DropdownMenuItem<int?>(
                          value: coach['coach_schedule_id'] as int?,
                          child: Text('${coach['name']} - Rp ${_formatPrice((coach['rate_per_hour'] ?? 0).toDouble())}/jam'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCoachScheduleId = value;
                      });
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
        const Text('Metode Pembayaran:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paymentMethod,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Cash (Bayar di Tempat)')),
                DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paymentMethod = value;
                  });
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
        const Text('Pilih Peralatan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_equipments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Tidak ada peralatan tersedia untuk venue ini.',
                style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: List.generate(_equipments.length, (index) {
                final eq = _equipments[index];
                final eqId = eq['id'] as int;
                final isSelected = _selectedEquipmentIds.contains(eqId);
                final qty = _equipmentQuantities[eqId] ?? 1;

                return Column(
                  children: [
                    CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedEquipmentIds.add(eqId);
                            _equipmentQuantities[eqId] = 1;
                          } else {
                            _selectedEquipmentIds.remove(eqId);
                            _equipmentQuantities.remove(eqId);
                          }
                        });
                      },
                      title: Text(eq['name']?.toString() ?? '-'),
                      subtitle: Text('Rp ${_formatPrice((eq['rental_price'] ?? 0).toDouble())} • Stok: ${eq['stock_quantity'] ?? 0}'),
                      activeColor: const Color(0xFF2563EB),
                      secondary: isSelected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: qty > 1 ? () => setState(() => _equipmentQuantities[eqId] = qty - 1) : null,
                                ),
                                Text('$qty'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: qty < (eq['stock_quantity'] ?? 1) ? () => setState(() => _equipmentQuantities[eqId] = qty + 1) : null,
                                ),
                              ],
                            )
                          : null,
                    ),
                    if (index < _equipments.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2)),
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
                  const Text('Total Biaya', style: TextStyle(color: Colors.grey)),
                  Text('Rp ${_formatPrice(_calculateTotal())}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _updateBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}