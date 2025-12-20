import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/screens/venue/venue_manage_schedule.dart';

// --- DESIGN SYSTEM CONSTANTS & WIDGETS ---
class NeoColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Colors.white;
}

class NeoContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool hasShadow;

  const NeoContainer({
    super.key,
    required this.child,
    this.color = NeoColors.background,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NeoColors.text, width: 2),
          boxShadow: hasShadow
              ? const [
                  BoxShadow(
                    color: NeoColors.text,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

class NeoButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = NeoColors.primary,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoContainer(
      onTap: onPressed,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class NeoInputWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const NeoInputWrapper({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: NeoColors.text,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        NeoContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: child,
        ),
      ],
    );
  }
}

// --- MAIN PAGE LOGIC ---

class VenueManagePage extends StatefulWidget {
  final int venueId;
  const VenueManagePage({super.key, required this.venueId});
  @override
  State<VenueManagePage> createState() => _VenueManagePageState();
}

class _VenueManagePageState extends State<VenueManagePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  List<dynamic> _locationsList = [];
  List<dynamic> _categoriesList = [];

  int? _selectedLocationId;
  int? _selectedCategoryId;

  // Payment option dihapus

  List<dynamic> _equipments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueManage(widget.venueId);

    try {
      final response = await request.get(url);

      if (response['success'] == true) {
        final venue = response['venue'];
        setState(() {
          _nameController.text = venue['name'] ?? '';
          _descController.text = venue['description'] ?? '';
          _priceController.text = venue['price_per_hour'].toString();

          _locationsList = response['locations'] ?? [];
          _categoriesList = response['categories'] ?? [];

          _selectedLocationId = venue['location_id'];
          _selectedCategoryId = venue['sport_category_id'];

          _imageController.text = venue['image'] ?? '';

          _equipments = response['equipments'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted)
          _showSnack(response['message'] ?? 'Gagal memuat data', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack("Error: $e", isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? NeoColors.danger : NeoColors.text,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;

    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueManage(widget.venueId);

    try {
      final response = await request.postJson(
        url,
        jsonEncode({
          'action': 'edit_venue',
          'name': _nameController.text,
          'description': _descController.text,
          'price_per_hour': double.tryParse(_priceController.text) ?? 0,
          'location': _selectedLocationId,
          'sport_category': _selectedCategoryId,
          // 'payment_options' dihapus dari payload
          'image': _imageController.text,
        }),
      );

      if (response['success'] == true) {
        if (mounted)
          _showSnack(response['message'] ?? "Data venue berhasil diperbarui!");
        await _fetchData();
      } else {
        if (mounted)
          _showSnack(
            response['message'] ?? "Gagal memperbarui venue",
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
  }

  Future<void> _deleteEquipment(int id) async {
    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueManage(widget.venueId);
    try {
      final response = await request.postJson(
        url,
        jsonEncode({'action': 'delete_equipment', 'equipment_id': id}),
      );
      if (response['success'] == true) {
        setState(() {
          _equipments = response['equipments'] ?? [];
        });
        if (mounted)
          _showSnack(response['message'] ?? "Equipment berhasil dihapus");
      } else {
        if (mounted)
          _showSnack(
            response['message'] ?? "Gagal menghapus equipment",
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
  }

  void _showEquipmentDialog({Map<String, dynamic>? equipment}) {
    final nameController = TextEditingController(
      text: equipment?['name'] ?? '',
    );
    final stockController = TextEditingController(
      text: equipment != null ? equipment['stock'].toString() : '',
    );
    final priceController = TextEditingController(
      text: equipment != null ? equipment['price'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoContainer(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment == null ? "TAMBAH ALAT" : "EDIT ALAT",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.text,
                  ),
                ),
                const SizedBox(height: 20),
                NeoInputWrapper(
                  label: "Nama Alat",
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 12),
                NeoInputWrapper(
                  label: "Stok",
                  child: TextField(
                    controller: stockController,
                    decoration: const InputDecoration(border: InputBorder.none),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 12),
                NeoInputWrapper(
                  label: "Harga Sewa / Jam",
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(border: InputBorder.none),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "BATAL",
                        style: TextStyle(
                          color: NeoColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeoButton(
                      label: "SIMPAN",
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            stockController.text.isEmpty ||
                            priceController.text.isEmpty) {
                          _showSnack("Semua field harus diisi", isError: true);
                          return;
                        }
                        Navigator.pop(context);
                        await _submitEquipment(
                          id: equipment?['id'],
                          name: nameController.text,
                          stock: stockController.text,
                          price: priceController.text,
                          isEdit: equipment != null,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEquipment(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red[50],
                    child: const Icon(Icons.warning, color: NeoColors.danger),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "HAPUS ALAT?",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Yakin ingin menghapus \"$name\"?",
                style: const TextStyle(color: NeoColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "BATAL",
                      style: TextStyle(
                        color: NeoColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeoButton(
                    label: "HAPUS",
                    backgroundColor: NeoColors.danger,
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEquipment(id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitEquipment({
    int? id,
    required String name,
    required String stock,
    required String price,
    required bool isEdit,
  }) async {
    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueManage(widget.venueId);
    Map<String, dynamic> data = {
      'action': isEdit ? 'edit_equipment' : 'add_equipment',
      'name': name,
      'stock_quantity': int.tryParse(stock) ?? 0,
      'rental_price': double.tryParse(price) ?? 0,
    };
    if (isEdit && id != null) {
      data['equipment_id'] = id;
    }
    try {
      final response = await request.postJson(url, jsonEncode(data));
      if (response['success'] == true) {
        setState(() {
          _equipments = response['equipments'] ?? [];
        });
        if (mounted) _showSnack(response['message'] ?? "Berhasil");
      } else {
        if (mounted) _showSnack(response['message'] ?? "Gagal", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: NeoColors.text, width: 2),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: NeoColors.text, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: NeoColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "EDIT VENUE",
                    style: TextStyle(
                      color: NeoColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENT ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: NeoColors.text),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. URL INPUT & PREVIEW
                            NeoInputWrapper(
                              label: "URL Foto Venue",
                              child: TextFormField(
                                controller: _imageController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Tempel link gambar (https://...)",
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_imageController.text.isNotEmpty)
                              NeoContainer(
                                height: 220,
                                width: double.infinity,
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    _imageController.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              NeoContainer(
                                height: 100,
                                width: double.infinity,
                                padding: EdgeInsets.zero,
                                child: Center(
                                  child: Text(
                                    "Masukkan URL untuk preview",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // 2. FORM FIELDS
                            NeoInputWrapper(
                              label: "Nama Venue",
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Masukkan nama venue...",
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            NeoInputWrapper(
                              label: "Deskripsi",
                              child: TextFormField(
                                controller: _descController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Jelaskan fasilitas venue...",
                                ),
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            NeoInputWrapper(
                              label: "Harga / Jam (Rp)",
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "0",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dropdowns
                            NeoInputWrapper(
                              label: "Lokasi",
                              child: DropdownButtonFormField<int>(
                                value: _selectedLocationId,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: NeoColors.text,
                                ),
                                items: _locationsList
                                    .map<DropdownMenuItem<int>>((item) {
                                      return DropdownMenuItem<int>(
                                        value: item['id'],
                                        child: Text(item['name']),
                                      );
                                    })
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedLocationId = val),
                                validator: (val) =>
                                    val == null ? 'Wajib dipilih' : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            NeoInputWrapper(
                              label: "Kategori Olahraga",
                              child: DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: NeoColors.text,
                                ),
                                items: _categoriesList
                                    .map<DropdownMenuItem<int>>((item) {
                                      return DropdownMenuItem<int>(
                                        value: item['id'],
                                        child: Text(item['name']),
                                      );
                                    })
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryId = val),
                                validator: (val) =>
                                    val == null ? 'Wajib dipilih' : null,
                              ),
                            ),

                            // Payment Options dihapus
                            const SizedBox(height: 32),

                            // ACTION BUTTONS
                            SizedBox(
                              width: double.infinity,
                              child: NeoButton(
                                label: "SIMPAN PERUBAHAN",
                                icon: Icons.save,
                                onPressed: _saveVenue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: NeoButton(
                                label: "KELOLA JADWAL",
                                icon: Icons.calendar_month,
                                backgroundColor: const Color(0xFFF59E0B),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VenueManageSchedulePage(
                                            venueId: widget.venueId,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 40),
                            const Divider(color: NeoColors.text, thickness: 2),
                            const SizedBox(height: 24),

                            // EQUIPMENT SECTION (Sama persis)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "PERALATAN",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: NeoColors.text,
                                  ),
                                ),
                                NeoContainer(
                                  onTap: () => _showEquipmentDialog(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  color: NeoColors.text,
                                  hasShadow: false,
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "TAMBAH",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _equipments.isEmpty
                                ? NeoContainer(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(32),
                                    color: Colors.grey[100],
                                    hasShadow: false,
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.sports_tennis,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Belum ada peralatan.",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _equipments.length,
                                    separatorBuilder: (ctx, i) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final equipment = _equipments[index];
                                      return NeoContainer(
                                        padding: const EdgeInsets.all(16),
                                        hasShadow: true,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE0F2FE),
                                                border: Border.all(
                                                  color: NeoColors.text,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.sports_soccer,
                                                color: NeoColors.text,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    equipment['name']
                                                            ?.toString()
                                                            .toUpperCase() ??
                                                        '-',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Stok: ${equipment['stock'] ?? 0}",
                                                    style: const TextStyle(
                                                      color: NeoColors.muted,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Rp ${equipment['price'] ?? 0}/jam",
                                                    style: const TextStyle(
                                                      color: NeoColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showEquipmentDialog(
                                                        equipment: equipment,
                                                      ),
                                                  child: const Icon(
                                                    Icons.edit,
                                                    color: NeoColors.text,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _confirmDeleteEquipment(
                                                        equipment['id'],
                                                        equipment['name'],
                                                      ),
                                                  child: const Icon(
                                                    Icons.delete_outline,
                                                    color: NeoColors.danger,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 40),
                          ],
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
