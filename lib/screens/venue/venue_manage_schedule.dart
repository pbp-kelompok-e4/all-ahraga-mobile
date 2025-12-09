import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/models/venue_schedule_entry.dart';

class VenueManageSchedulePage extends StatefulWidget {
  final int venueId;

  const VenueManageSchedulePage({super.key, required this.venueId});

  @override
  State<VenueManageSchedulePage> createState() =>
      _VenueManageSchedulePageState();
}

class _VenueManageSchedulePageState extends State<VenueManageSchedulePage> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTimeGlobal;

  List<VenueSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSchedules();
    });
  }

  // --- 1. GET DATA ---
  Future<void> _fetchSchedules() async {
    final request = context.read<CookieRequest>();
    setState(() => _isLoading = true);

    try {
      final url =
          "${ApiConstants.venueManageSchedule(widget.venueId)}?format=json";
      final response = await request.get(url);

      List<VenueSchedule> listData = [];
      for (var d in response) {
        if (d != null) {
          listData.add(VenueSchedule.fromJson(d));
        }
      }

      if (!mounted) return;

      setState(() {
        _schedules = listData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    }
  }

  // --- 2. POST DATA (Tambah) ---
  Future<void> _addSchedule() async {
    if (_selectedDate == null || _startTime == null || _endTimeGlobal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon lengkapi Tanggal, Jam Mulai, dan Batas Akhir."),
        ),
      );
      return;
    }

    final request = context.read<CookieRequest>();
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    String startStr =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
    String endGlobalStr =
        '${_endTimeGlobal!.hour.toString().padLeft(2, '0')}:${_endTimeGlobal!.minute.toString().padLeft(2, '0')}';

    Map<String, dynamic> payload = {
      'date': dateStr,
      'start_time': startStr,
      'end_time_global': endGlobalStr,
      'is_available': true,
    };

    try {
      final response = await request.postJson(
        ApiConstants.venueManageSchedule(widget.venueId),
        jsonEncode(payload),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Jadwal berhasil dibuat!"),
          ),
        );
        _fetchSchedules();
        setState(() {
          _selectedDate = null;
          _startTime = null;
          _endTimeGlobal = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${response['message']}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 3. FUNGSI DELETE (Bisa Satu atau Banyak) ---
  Future<void> _deleteSchedules(List<int> ids) async {
    if (ids.isEmpty) return;

    // Konfirmasi Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Jadwal?"),
        content: Text("Anda akan menghapus ${ids.length} jadwal."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final requestProvider = context.read<CookieRequest>();
    final url = Uri.parse(ApiConstants.venueDeleteSchedule(widget.venueId));

    try {
      final client = http.Client();
      final request = http.Request('DELETE', url);

      request.headers.addAll(requestProvider.headers);
      request.headers['Content-Type'] = 'application/json';

      request.body = jsonEncode({'selected_schedules': ids});

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resBody['message'] ?? "Berhasil dihapus")),
          );
          _fetchSchedules(); // Refresh UI
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${resBody['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error ${response.statusCode}: Gagal menghapus."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error koneksi: $e")));
    }
  }

  // Helper untuk Hapus Massal (Tombol di AppBar)
  void _deleteBulk() {
    List<int> selectedIds = _schedules
        .where((s) => s.isSelected)
        .map((s) => s.id)
        .toList();
    _deleteSchedules(selectedIds);
  }

  // Helper untuk Hapus Satuan (Tombol Sampah di Item)
  void _deleteSingle(int id) {
    _deleteSchedules([id]);
  }

  // --- HELPERS UI ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTimeGlobal = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _schedules.where((s) => s.isSelected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Jadwal"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL HAPUS MASSAL (Selalu muncul, tapi disable/grey jika 0 terpilih)
          IconButton(
            icon: const Icon(
              Icons.delete_sweep,
            ), // Icon beda biar jelas ini massal
            onPressed: selectedCount > 0 ? _deleteBulk : null,
            tooltip: selectedCount > 0
                ? "Hapus $selectedCount item terpilih"
                : "Pilih jadwal dulu",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FORM INPUT ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Buat Slot Jadwal Baru",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? "Pilih Tanggal"
                              : DateFormat(
                                  'EEEE, d MMM yyyy',
                                ).format(_selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Jam Mulai',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _startTime == null
                                    ? "--:--"
                                    : _startTime!.format(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Batas Akhir',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _endTimeGlobal == null
                                    ? "--:--"
                                    : _endTimeGlobal!.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addSchedule,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Generate Slot"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Daftar Slot Jadwal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // --- LIST JADWAL ---
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _schedules.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Belum ada jadwal."),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final item = _schedules[index];
                      // Kita pakai ListTile biasa agar lebih fleksibel
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: item.isBooked
                            ? Colors.grey.shade100
                            : Colors.white,
                        child: ListTile(
                          // Checkbox di kiri untuk pilih massal
                          leading: Checkbox(
                            activeColor: Colors.teal,
                            value: item.isSelected,
                            onChanged: item.isBooked
                                ? null
                                : (bool? val) {
                                    setState(() {
                                      item.isSelected = val ?? false;
                                    });
                                  },
                          ),
                          title: Text(
                            "${item.startTime} - ${item.endTime}",
                            style: TextStyle(
                              decoration: item.isBooked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isBooked
                                  ? Colors.grey
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "${item.date} • ${item.isBooked ? 'Sudah Dibooking' : 'Tersedia'}",
                            style: TextStyle(
                              color: item.isBooked ? Colors.red : Colors.green,
                            ),
                          ),
                          // TOMBOL HAPUS SATUAN DI KANAN
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: item.isBooked
                                ? null // Tidak bisa hapus kalau sudah dibooking
                                : () => _deleteSingle(item.id),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
