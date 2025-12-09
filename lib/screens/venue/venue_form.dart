import 'dart:convert';
import 'package:flutter/material.dart';
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

  // Variabel untuk Dropdown Data dari Server
  List<dynamic> _locations = [];
  List<dynamic> _categories = [];
  
  // Variabel State Pilihan User - UBAH KE INT
  int? _selectedLocation;
  int? _selectedCategory;
  
  String? _selectedPaymentOption = 'TRANSFER'; 
  
  final List<Map<String, String>> _paymentOptionsList = [
    {'value': 'CASH', 'label': 'Bayar di Tempat (Cash)'},
    {'value': 'TRANSFER', 'label': 'Transfer Manual'},
  ];

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
    // PERBAIKAN: Gunakan endpoint venue-add yang sudah include master data
    final url = ApiConstants.venueAdd;

    try {
      final response = await request.get(url);
      
      if (response['success'] == true) {
        setState(() {
          _locations = response['locations'] ?? [];
          _categories = response['sports'] ?? []; // Sesuaikan dengan key dari backend
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

  Future<void> _submitVenue() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null || _selectedCategory == null || _selectedPaymentOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua pilihan (Lokasi, Kategori, Pembayaran)")),
      );
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
          'location': _selectedLocation, // SUDAH INT
          'sport_category': _selectedCategory, // SUDAH INT
          'payment_options': _selectedPaymentOption, 
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
          String errMessage = response['message'] ?? "Gagal menyimpan";
          if (response['errors'] != null) {
             errMessage += ": ${response['errors'].toString()}";
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMessage),
              backgroundColor: Colors.red,
            )
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Venue",
                        border: OutlineInputBorder(),
                        hintText: "Contoh: Lapangan Futsal A",
                      ),
                      validator: (value) => value!.isEmpty ? "Nama tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "Deskripsi",
                        border: OutlineInputBorder(),
                        hintText: "Jelaskan fasilitas venue...",
                      ),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? "Deskripsi tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: "Harga per Jam (Rp)",
                        border: OutlineInputBorder(),
                        prefixText: "Rp ",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Harga harus diisi";
                        if (int.tryParse(value) == null) return "Harus berupa angka";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Dropdown Location - PERBAIKAN: VALUE INT
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Lokasi / Area",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedLocation,
                      items: _locations.map<DropdownMenuItem<int>>((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'], // Langsung int
                          child: Text(item['name']),
                        );
                      }).toList(),
                      onChanged: (int? val) {
                        setState(() => _selectedLocation = val);
                      },
                      validator: (val) => val == null ? "Pilih lokasi" : null,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Category - PERBAIKAN: VALUE INT
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Kategori Olahraga",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCategory,
                      items: _categories.map<DropdownMenuItem<int>>((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'], // Langsung int
                          child: Text(item['name']),
                        );
                      }).toList(),
                      onChanged: (int? val) {
                        setState(() => _selectedCategory = val);
                      },
                      validator: (val) => val == null ? "Pilih kategori" : null,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Payment Options
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Opsi Pembayaran",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedPaymentOption,
                      items: _paymentOptionsList.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(item['label']!),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        setState(() => _selectedPaymentOption = val);
                      },
                      validator: (val) => val == null ? "Pilih opsi pembayaran" : null,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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