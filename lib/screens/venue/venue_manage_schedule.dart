import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // IMPORT PENTING

// PASTIKAN IMPORT INI SESUAI
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
  String? _selectedMonthKey;

  @override
  void initState() {
    super.initState();
    // FIX LOCALE ERROR: Init dulu data bahasa Indonesia
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        _fetchSchedules();
      }
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
        if (_schedules.isNotEmpty && _selectedMonthKey == null) {
          _selectedMonthKey = _getMonthKey(_schedules.first.date);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    }
  }

  // --- 2. POST DATA ---
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
    // Pastikan locale 'id_ID' dipakai konsisten
    String dateStr = DateFormat('yyyy-MM-dd', 'id_ID').format(_selectedDate!);
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
        setState(() {
          _selectedMonthKey = _getMonthKey(dateStr);
          _selectedDate = null;
          _startTime = null;
          _endTimeGlobal = null;
        });
        _fetchSchedules();
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

  // --- 3. DELETE DATA ---
  Future<void> _deleteSchedules(List<int> ids) async {
    if (ids.isEmpty) return;

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
          _fetchSchedules();
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

  void _deleteBulk() {
    List<VenueSchedule> visibleSchedules = _getVisibleSchedules();
    List<int> selectedIds = visibleSchedules
        .where((s) => s.isSelected)
        .map((s) => s.id)
        .toList();
    _deleteSchedules(selectedIds);
  }

  void _deleteSingle(int id) {
    _deleteSchedules([id]);
  }

  // --- UI HELPERS ---

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showScrollTimePicker(bool isStart) {
    TimeOfDay initialTime = isStart
        ? (_startTime ?? TimeOfDay(hour: 8, minute: 0))
        : (_endTimeGlobal ?? TimeOfDay(hour: 22, minute: 0));

    DateTime tempDate = DateTime(
      2023,
      1,
      1,
      initialTime.hour,
      initialTime.minute,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Batal",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      isStart ? "Jam Mulai" : "Batas Akhir",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isStart) {
                            _startTime = TimeOfDay.fromDateTime(tempDate);
                          } else {
                            _endTimeGlobal = TimeOfDay.fromDateTime(tempDate);
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Pilih",
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: tempDate,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDate = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC GROUPING ---
  String _getMonthKey(String dateIso) {
    if (dateIso.length >= 7) return dateIso.substring(0, 7);
    return dateIso;
  }

  String _formatMonthDisplay(String monthKey) {
    try {
      DateTime dt = DateTime.parse("$monthKey-01");
      return DateFormat('MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return monthKey;
    }
  }

  List<String> _getAvailableMonths() {
    Set<String> months = {};
    for (var s in _schedules) {
      months.add(_getMonthKey(s.date));
    }
    List<String> sortedMonths = months.toList()..sort();
    return sortedMonths;
  }

  List<VenueSchedule> _getVisibleSchedules() {
    if (_selectedMonthKey == null) return [];
    return _schedules
        .where((s) => _getMonthKey(s.date) == _selectedMonthKey)
        .toList();
  }

  Map<String, List<VenueSchedule>> _groupSchedulesByDate() {
    List<VenueSchedule> visibleData = _getVisibleSchedules();
    Map<String, List<VenueSchedule>> grouped = {};
    for (var s in visibleData) {
      String dateKey = s.date;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(s);
    }
    return grouped;
  }

  String _formatDateHeader(String dateIso) {
    try {
      DateTime dt = DateTime.parse(dateIso);
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateIso;
    }
  }

  Widget _buildTimePickerCard({
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    time == null ? "--:--" : time.format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableMonths = _getAvailableMonths();
    if (availableMonths.isNotEmpty &&
        (_selectedMonthKey == null ||
            !availableMonths.contains(_selectedMonthKey))) {
      _selectedMonthKey = availableMonths.first;
    }
    final groupedSchedules = _groupSchedulesByDate();
    final sortedDates = groupedSchedules.keys.toList()..sort();
    int selectedCount = _getVisibleSchedules()
        .where((s) => s.isSelected)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Jadwal"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: selectedCount > 0 ? _deleteBulk : null,
            tooltip: "Hapus item terpilih",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.add_task, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          "Buat Jadwal Baru",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pilih Tanggal",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _selectedDate == null
                                      ? "Belum dipilih"
                                      : DateFormat(
                                          'EEEE, d MMMM yyyy',
                                          'id_ID',
                                        ).format(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDate == null
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildTimePickerCard(
                          title: "Mulai Jam",
                          time: _startTime,
                          icon: Icons.access_time,
                          onTap: () => _showScrollTimePicker(true),
                        ),
                        const SizedBox(width: 12),
                        _buildTimePickerCard(
                          title: "Sampai Jam",
                          time: _endTimeGlobal,
                          icon: Icons.timer_off_outlined,
                          onTap: () => _showScrollTimePicker(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Generate Slot Jadwal",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Daftar Slot",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (availableMonths.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonthKey,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.teal,
                        ),
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMonthKey = newValue;
                          });
                        },
                        items: availableMonths.map<DropdownMenuItem<String>>((
                          String monthKey,
                        ) {
                          return DropdownMenuItem<String>(
                            value: monthKey,
                            child: Text(_formatMonthDisplay(monthKey)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : sortedDates.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Belum ada jadwal bulan ini.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      String dateKey = sortedDates[index];
                      List<VenueSchedule> slots = groupedSchedules[dateKey]!;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded:
                                sortedDates.length == 1 || index == 0,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.teal,
                              ),
                            ),
                            title: Text(
                              _formatDateHeader(dateKey),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              "${slots.length} sesi tersedia",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  children: slots.map((item) {
                                    return ListTile(
                                      visualDensity: VisualDensity.compact,
                                      leading: Checkbox(
                                        activeColor: Colors.teal,
                                        value: item.isSelected,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: item.isBooked
                                            ? null
                                            : (bool? val) {
                                                setState(() {
                                                  item.isSelected =
                                                      val ?? false;
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
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: item.isBooked
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                "Booked",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _deleteSingle(item.id),
                                              tooltip: "Hapus sesi ini",
                                            ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
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
