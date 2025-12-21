import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/models/venue_schedule_entry.dart';

const Color _kBg = Colors.white; 
const Color _kTeal = Color(0xFF0D9488); 
const Color _kSlate = Color(
  0xFF0F172A,
); 
const Color _kLightGrey = Color(0xFFF1F5F9); 
const Color _kMuted = Color(0xFF64748B); 
const Color _kRedLight = Color(
  0xFFFEF2F2,
); 
const Color _kRed = Color(0xFFDC2626); 

const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

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
  bool _isLocaleReady = false;
  String? _selectedMonthKey;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await initializeDateFormatting('id_ID', null);
    if (!mounted) return;
    setState(() {
      _isLocaleReady = true;
    });
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    final request = context.read<CookieRequest>();
    setState(() => _isLoading = true);

    try {
      final url =
          "${ApiConstants.venueManageSchedule(widget.venueId)}?format=json";
      final response = await request.get(url);

      if (response is Map && response['success'] == false) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'] ?? "Error")));
        return;
      }

      List<VenueSchedule> listData = [];
      if (response is List) {
        for (var d in response) {
          if (d != null) listData.add(VenueSchedule.fromJson(d));
        }
      }

      if (!mounted) return;

      setState(() {
        _schedules = listData;
        _isLoading = false;
        _isSelectionMode = false;
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

  Future<void> _addSchedule() async {
    if (_selectedDate == null || _startTime == null || _endTimeGlobal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi Tanggal & Waktu.")),
      );
      return;
    }

    final request = context.read<CookieRequest>();
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
            backgroundColor: _kTeal,
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

  Future<void> _deleteSchedules(List<int> ids) async {
    if (ids.isEmpty) return;
    final request = context.read<CookieRequest>();

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _kSlate, width: 2),
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        title: const Text(
          "HAPUS JADWAL?",
          style: TextStyle(color: _kSlate, fontWeight: FontWeight.w900),
        ),
        content: Text(
          "Anda akan menghapus ${ids.length} jadwal permanen.",
          style: const TextStyle(color: _kSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "BATAL",
              style: TextStyle(fontWeight: FontWeight.bold, color: _kMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "HAPUS SEKARANG",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await request.postJson(
        ApiConstants.venueDeleteSchedule(widget.venueId),
        jsonEncode({'selected_schedules': ids}),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Berhasil dihapus")),
        );
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
      ).showSnackBar(SnackBar(content: Text("Error koneksi: $e")));
    }
  }

  void _deleteBulk() {
    List<VenueSchedule> visibleSchedules = _getVisibleSchedules();
    List<int> selectedIds = visibleSchedules
        .where((s) => s.isSelected)
        .map((s) => s.id)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal satu jadwal.")),
      );
      return;
    }
    _deleteSchedules(selectedIds);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      for (var s in _schedules) {
        s.isSelected = false;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kTeal,
            onPrimary: Colors.white,
            onSurface: _kSlate,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showScrollTimePicker(bool isStart) {
    TimeOfDay initialTime = isStart
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTimeGlobal ?? const TimeOfDay(hour: 22, minute: 0));
    DateTime tempDate = DateTime(
      2023,
      1,
      1,
      initialTime.hour,
      initialTime.minute,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: _kMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      isStart ? "JAM MULAI" : "JAM SELESAI",
                      style: const TextStyle(
                        color: _kSlate,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isStart)
                            _startTime = TimeOfDay.fromDateTime(tempDate);
                          else
                            _endTimeGlobal = TimeOfDay.fromDateTime(tempDate);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "PILIH",
                        style: TextStyle(
                          color: _kTeal,
                          fontWeight: FontWeight.w900,
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
                  onDateTimeChanged: (val) => tempDate = val,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthKey(String dateIso) {
    if (dateIso.length >= 7) return dateIso.substring(0, 7);
    return dateIso;
  }

  String _formatMonthDisplay(String monthKey) {
    try {
      DateTime dt = DateTime.parse("$monthKey-01");
      return DateFormat('MMMM yyyy', 'id_ID').format(dt).toUpperCase();
    } catch (e) {
      return monthKey;
    }
  }

  List<String> _getAvailableMonths() {
    Set<String> months = {};
    for (var s in _schedules) months.add(_getMonthKey(s.date));
    return months.toList()..sort();
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
      if (!grouped.containsKey(s.date)) grouped[s.date] = [];
      grouped[s.date]!.add(s);
    }
    return grouped;
  }

  String _formatDateHeader(String dateIso) {
    try {
      DateTime dt = DateTime.parse(dateIso);
      return DateFormat('d MMM yyyy', 'id_ID').format(dt).toUpperCase();
    } catch (e) {
      return dateIso;
    }
  }

  String _getDayName(String dateIso) {
    try {
      DateTime dt = DateTime.parse(dateIso);
      return DateFormat('EEEE', 'id_ID').format(dt).toUpperCase();
    } catch (e) {
      return "HARI INI";
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // TOMBOL BACK
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kSlate, width: 2),
                  boxShadow: const [
                    BoxShadow(color: _kSlate, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: _kSlate, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MANAGER AREA",
                  style: TextStyle(
                    color: _kTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  _isSelectionMode ? "DELETE MODE" : "VENUE SCHEDULE",
                  style: TextStyle(
                    color: _isSelectionMode ? _kRed : _kSlate,
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

  Widget _buildTimeField(
    String label,
    TimeOfDay? time,
    bool isStart,
    IconData icon,
  ) {
    return Expanded(
      child: _buildBrutalBox(
        onTap: () => _showScrollTimePicker(isStart),
        padding: const EdgeInsets.all(16),
        shadowOffset: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: _kTeal),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time == null ? "--:--" : time.format(context),
              style: const TextStyle(
                color: _kSlate,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(VenueSchedule item, double width) {
    bool isBooked = item.isBooked;
    bool isSelected = item.isSelected;

    Color bg = isBooked ? _kLightGrey : Colors.white;
    Color border = _kSlate;
    Color text = isBooked ? _kMuted : _kSlate;
    double shadow = 3.0;

    if (_isSelectionMode && isSelected) {
      bg = const Color(0xFFFFE4E6);
      border = _kRed;
      text = _kRed;
    }

    return GestureDetector(
      onTap: () {
        if (isBooked) return;
        if (_isSelectionMode) {
          setState(() => item.isSelected = !item.isSelected);
        }
      },
      child: Container(
        width: width,
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: _kBorderWidth),
          boxShadow: isBooked
              ? []
              : [
                  BoxShadow(
                    color: _isSelectionMode && isSelected
                        ? _kRed.withOpacity(0.4)
                        : _kSlate,
                    offset: Offset(shadow, shadow),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${item.startTime} - ${item.endTime}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: text,
                      decoration: isBooked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isBooked)
                    const Text(
                      "BOOKED",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _kMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (!isBooked && !_isSelectionMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _kTeal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (_isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: isSelected ? _kRed : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleReady) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kTeal)),
      );
    }
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
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isSelectionMode) ...[
                    _buildBrutalBox(
                      shadowOffset: 6,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.add_circle_outline,
                                color: _kTeal,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "BUAT JADWAL VENUE",
                                style: TextStyle(
                                  color: _kSlate,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Date Input
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(_kRadius),
                                border: Border.all(color: _kSlate, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "TANGGAL",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _kMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedDate == null
                                            ? "Pilih Tanggal..."
                                            : DateFormat(
                                                    'EEEE, d MMM yyyy',
                                                    'id_ID',
                                                  )
                                                  .format(_selectedDate!)
                                                  .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: _selectedDate == null
                                              ? _kMuted
                                              : _kSlate,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: _kSlate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Time Inputs
                          Row(
                            children: [
                              _buildTimeField(
                                "MULAI",
                                _startTime,
                                true,
                                Icons.play_arrow_outlined,
                              ),
                              const SizedBox(width: 12),
                              _buildTimeField(
                                "SELESAI",
                                _endTimeGlobal,
                                false,
                                Icons.stop_circle_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Button 
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_kRadius),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _addSchedule,
                              child: const Text(
                                "PUBLISH JADWAL",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ] else ...[
                    _buildBrutalBox(
                      bgColor: _kRedLight,
                      borderColor: _kRed,
                      shadowOffset: 4,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep,
                            color: _kRed,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SizedBox(height: 4),
                                Text(
                                  "Pilih jadwal yang ingin dihapus",
                                  style: TextStyle(
                                    color: _kSlate,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daftar Jadwal",
                        style: TextStyle(
                          color: _kSlate,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (availableMonths.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kSlate, width: 2),
                            boxShadow: const [
                              BoxShadow(color: _kSlate, offset: Offset(2, 2)),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonthKey,
                              dropdownColor: Colors.white,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: _kSlate,
                              ),
                              style: const TextStyle(
                                color: _kSlate,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                              onChanged: (val) =>
                                  setState(() => _selectedMonthKey = val),
                              items: availableMonths
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(_formatMonthDisplay(m)),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: _kSlate),
                          ),
                        )
                      : sortedDates.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.black12,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Belum ada jadwal",
                                  style: TextStyle(color: _kMuted),
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
                            List<VenueSchedule> slots =
                                groupedSchedules[dateKey]!;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _kSlate, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: _kSlate,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: index == 0,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  iconColor: _kTeal,
                                  collapsedIconColor: _kSlate,
                                  title: Row(
                                    children: [
                                      Text(
                                        _getDayName(dateKey),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: _kTeal,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        width: 2,
                                        height: 14,
                                        color: _kSlate,
                                      ),
                                      Text(
                                        _formatDateHeader(dateKey),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _kSlate,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: _kLightGrey, 
                                        border: Border(
                                          top: BorderSide(
                                            color: _kSlate,
                                            width: 2,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(6),
                                        ),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          double spacing = 12.0;
                                          double itemWidth =
                                              (constraints.maxWidth - spacing) /
                                              2;
                                          return Wrap(
                                            spacing: spacing,
                                            runSpacing: 12,
                                            children: slots.map((item) {
                                              return _buildGridItem(
                                                item,
                                                itemWidth,
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: _isSelectionMode
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 32),
                FloatingActionButton(
                  heroTag: "btn_cancel",
                  onPressed: _toggleSelectionMode,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _kSlate, width: 2),
                  ),
                  child: const Icon(Icons.close, color: _kSlate),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: "btn_delete",
                  onPressed: selectedCount > 0 ? _deleteBulk : null,
                  backgroundColor: selectedCount > 0 ? _kRed : Colors.grey,
                  label: Text(
                    "HAPUS ($selectedCount)",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  icon: const Icon(Icons.delete_forever),
                ),
              ],
            )
          : FloatingActionButton(
              heroTag: "btn_edit",
              onPressed: _toggleSelectionMode,
              backgroundColor: _kTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
    );
  }
}
