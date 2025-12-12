import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/foundation.dart'; // PENTING: Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/screens/venue/venue_manage_schedule.dart';

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

  List<dynamic> _locationsList = [];
  List<dynamic> _categoriesList = [];

  int? _selectedLocationId;
  int? _selectedCategoryId;
  String? _selectedPaymentOption;

  final List<Map<String, String>> _paymentOptionsList = [
    {'value': 'CASH', 'label': 'Bayar di Tempat (Cash)'},
    {'value': 'TRANSFER', 'label': 'Transfer Manual'},
  ];

  List<dynamic> _equipments = [];
  bool _isLoading = true;

  // PERBAIKAN 1: Gunakan XFile
  XFile? _newImageFile;
  String? _currentImageUrl; 
  final ImagePicker _picker = ImagePicker();

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
          _selectedPaymentOption = venue['payment_options'];
          
          _currentImageUrl = venue['image']; // URL dari server

          _equipments = response['equipments'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        _newImageFile = pickedFile; // Simpan XFile langsung
      });
    }
  }

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;
    
    // PERBAIKAN 2: Baca bytes dari XFile
    String? base64Image;
    if (_newImageFile != null) {
      final bytes = await _newImageFile!.readAsBytes();
      base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
    }

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
          'payment_options': _selectedPaymentOption,
          'image': base64Image, 
        }),
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data venue berhasil diperbarui!")),
          );
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
  
  // (Bagian Equipment tidak berubah, saya singkat agar fokus ke perbaikan gambar)
  Future<void> _deleteEquipment(int id) async { /* ... kode lama ... */ }
  void _showEquipmentDialog({Map<String, dynamic>? equipment}) { /* ... kode lama ... */ }
  Future<void> _submitEquipment({int? id, required String name, required String stock, required String price, required bool isEdit}) async { /* ... kode lama ... */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Venue", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0D9488), iconTheme: const IconThemeData(color: Colors.white)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Detail Venue", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   
                   // --- PERBAIKAN 3: TAMPILAN GAMBAR (WEB SAFE) ---
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _newImageFile != null
                                ? (kIsWeb 
                                    ? Image.network(_newImageFile!.path, fit: BoxFit.cover)
                                    : Image.file(File(_newImageFile!.path), fit: BoxFit.cover))
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                    ? Image.network(
                                        _currentImageUrl!.startsWith('http') 
                                            ? _currentImageUrl! 
                                            : "${ApiConstants.baseUrl}$_currentImageUrl",
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                          Text("Tap ganti foto", style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                    ),
                   const SizedBox(height: 16),
                   // ---------------------------------------------

                   Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Nama Venue", border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()), maxLines: 3),
                        const SizedBox(height: 10),
                        TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: "Harga per Jam", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                        const SizedBox(height: 10),
                        
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: "Lokasi", border: OutlineInputBorder()),
                          value: _selectedLocationId,
                          items: _locationsList.map<DropdownMenuItem<int>>((item) => DropdownMenuItem<int>(value: item['id'], child: Text(item['name']))).toList(),
                          onChanged: (val) => setState(() => _selectedLocationId = val),
                        ),
                        const SizedBox(height: 10),
                         DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                          value: _selectedCategoryId,
                          items: _categoriesList.map<DropdownMenuItem<int>>((item) => DropdownMenuItem<int>(value: item['id'], child: Text(item['name']))).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Pembayaran", border: OutlineInputBorder()),
                          value: _selectedPaymentOption,
                          items: _paymentOptionsList.map((item) => DropdownMenuItem<String>(value: item['value'], child: Text(item['label']!))).toList(),
                          onChanged: (val) => setState(() => _selectedPaymentOption = val),
                        ),

                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveVenue, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white), child: const Text("Simpan Perubahan Venue"))),
                      ],
                    ),
                  ),
                  
                  // ... (Bagian Jadwal & Equipment tetap sama) ...
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => VenueManageSchedulePage(venueId: widget.venueId))); }, icon: const Icon(Icons.calendar_month), label: const Text("Kelola Jadwal & Slot"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
                  // ... dan seterusnya (ListView Equipment) ...
                ],
              ),
            ),
    );
  }
}