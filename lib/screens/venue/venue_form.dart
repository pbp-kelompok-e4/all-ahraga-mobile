import 'dart:convert';
import 'dart:io'; // Tetap butuh untuk Android/iOS
import 'package:flutter/foundation.dart'; // Untuk cek kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';

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

  List<dynamic> _locations = [];
  List<dynamic> _categories = [];
  
  int? _selectedLocation;
  int? _selectedCategory;
  String? _selectedPaymentOption = 'TRANSFER'; 
  
  final List<Map<String, String>> _paymentOptionsList = [
    {'value': 'CASH', 'label': 'Bayar di Tempat (Cash)'},
    {'value': 'TRANSFER', 'label': 'Transfer Manual'},
  ];

  bool _isLoading = true;
  
  // PERBAIKAN 1: Gunakan XFile, bukan File
  XFile? _imageFile; 
  final ImagePicker _picker = ImagePicker();

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, 
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        // PERBAIKAN 2: Simpan langsung sebagai XFile
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _submitVenue() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null || _selectedCategory == null || _selectedPaymentOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua pilihan")),
      );
      return;
    }

    // PERBAIKAN 3: Baca bytes langsung dari XFile (Aman untuk Web & Mobile)
    String? base64Image;
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
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
          'payment_options': _selectedPaymentOption,
          'image': base64Image,
        }),
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Venue berhasil dibuat!")),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${response['message']}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Venue Baru", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D9488),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PERBAIKAN 4: TAMPILAN GAMBAR (WEB SAFE) ---
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      // Jika Web: Pakai Network Image (Blob URL dari path)
                                      ? Image.network(
                                          _imageFile!.path,
                                          fit: BoxFit.cover,
                                        )
                                      // Jika Mobile: Pakai File Image
                                      : Image.file(
                                          File(_imageFile!.path),
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text("Tap untuk tambah foto", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ---------------------------------------------

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Nama Venue", border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Harga per Jam (Rp)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: "Lokasi / Area", border: OutlineInputBorder()),
                      value: _selectedLocation,
                      items: _locations.map<DropdownMenuItem<int>>((item) {
                        return DropdownMenuItem<int>(value: item['id'], child: Text(item['name']));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLocation = val),
                      validator: (val) => val == null ? "Pilih lokasi" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: "Kategori Olahraga", border: OutlineInputBorder()),
                      value: _selectedCategory,
                      items: _categories.map<DropdownMenuItem<int>>((item) {
                        return DropdownMenuItem<int>(value: item['id'], child: Text(item['name']));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      validator: (val) => val == null ? "Pilih kategori" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Opsi Pembayaran", border: OutlineInputBorder()),
                      value: _selectedPaymentOption,
                      items: _paymentOptionsList.map((item) {
                        return DropdownMenuItem<String>(value: item['value'], child: Text(item['label']!));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPaymentOption = val),
                      validator: (val) => val == null ? "Pilih opsi" : null,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitVenue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Simpan Venue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}