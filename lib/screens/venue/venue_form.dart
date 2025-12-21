import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';

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

class VenueFormPage extends StatefulWidget {
  const VenueFormPage({super.key});

  @override
  State<VenueFormPage> createState() => _VenueFormPageState();
}

class _VenueFormPageState extends State<VenueFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  List<dynamic> _locations = [];
  List<dynamic> _categories = [];

  int? _selectedLocation;
  int? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDropdownData();
    });
  }

  Future<void> _fetchDropdownData() async {
    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueAdd;
    try {
      final response = await request.get(url);
      if (response['success'] == true) {
        setState(() {
          _locations = response['locations'] ?? [];
          _categories = response['sports'] ?? [];
          _isLoading = false;
        });
      } else {
        _handleError("Gagal memuat data referensi.");
      }
    } catch (e) {
      _handleError("Error: $e");
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showSnack(message, isError: true);
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

  Future<void> _submitVenue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null || _selectedCategory == null) {
      _showSnack("Mohon lengkapi semua pilihan dropdown", isError: true);
      return;
    }

    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueAdd;

    try {
      final response = await request.postJson(
        url,
        jsonEncode({
          'name': _nameController.text,
          'description': _descController.text,
          'price_per_hour': int.tryParse(_priceController.text) ?? 0,
          'location': _selectedLocation,
          'sport_category': _selectedCategory,
          'image': _imageController.text,
        }),
      );

      if (response['success'] == true) {
        if (mounted) {
          _showSnack("Venue berhasil dibuat!");
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          _showSnack("Gagal: ${response['message']}", isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack("Error: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                    "TAMBAH VENUE",
                    style: TextStyle(
                      color: NeoColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

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
                            // INPUT URL GAMBAR
                            NeoInputWrapper(
                              label: "URL Foto Venue",
                              child: TextFormField(
                                controller: _imageController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Tempel link gambar (https://...)",
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // IMAGE PREVIEW
                            if (_imageController.text.isNotEmpty)
                              Center(
                                child: NeoContainer(
                                  width: double.infinity,
                                  height: 200,
                                  padding: EdgeInsets.zero,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      _imageController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "URL Gambar Tidak Valid",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: NeoContainer(
                                  width: double.infinity,
                                  height: 100,
                                  padding: EdgeInsets.zero,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_search,
                                          size: 32,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Masukkan URL untuk melihat preview",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // INPUT FIELDS
                            NeoInputWrapper(
                              label: "Nama Venue",
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Contoh: GOR Sudirman",
                                ),
                                validator: (value) =>
                                    value!.isEmpty ? "Wajib diisi" : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            NeoInputWrapper(
                              label: "Deskripsi",
                              child: TextFormField(
                                controller: _descController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Fasilitas apa saja yang tersedia?",
                                ),
                                maxLines: 3,
                                validator: (value) =>
                                    value!.isEmpty ? "Wajib diisi" : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            NeoInputWrapper(
                              label: "Harga per Jam (Rp)",
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "0",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value!.isEmpty ? "Wajib diisi" : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // DROPDOWNS
                            NeoInputWrapper(
                              label: "Lokasi / Area",
                              child: DropdownButtonFormField<int>(
                                value: _selectedLocation,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: NeoColors.text,
                                ),
                                items: _locations.map<DropdownMenuItem<int>>((
                                  item,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: item['id'],
                                    child: Text(item['name']),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedLocation = val),
                                validator: (val) =>
                                    val == null ? "Pilih lokasi" : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            NeoInputWrapper(
                              label: "Kategori Olahraga",
                              child: DropdownButtonFormField<int>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: NeoColors.text,
                                ),
                                items: _categories.map<DropdownMenuItem<int>>((
                                  item,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: item['id'],
                                    child: Text(item['name']),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCategory = val),
                                validator: (val) =>
                                    val == null ? "Pilih kategori" : null,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // SUBMIT BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: NeoButton(
                                label: "SIMPAN VENUE",
                                icon: Icons.save_alt,
                                onPressed: _submitVenue,
                              ),
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
