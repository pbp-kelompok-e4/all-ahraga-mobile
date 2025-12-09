import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/screens/venue/venue_manage_schedule.dart'; // Sesuaikan path folder kamu

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

          _equipments = response['equipments'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal memuat data: ${response['message']}"),
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("Error fetching manage data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocationId == null ||
        _selectedCategoryId == null ||
        _selectedPaymentOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi pilihan dropdown.")),
      );
      return;
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
          String errorMessage = response['message'] ?? "Gagal menyimpan";
          if (response['errors'] != null) {
            errorMessage += "\n${response['errors']}";
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
          _equipments = response['equipments'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Equipment berhasil dihapus.")),
          );
        }
      }
    } catch (e) {
      print("Error deleting: $e");
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
      builder: (context) => AlertDialog(
        title: Text(equipment == null ? "Tambah Equipment" : "Edit Equipment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Alat"),
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: "Jumlah Stok"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Harga Sewa"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitEquipment(
                id: equipment?['id'],
                name: nameController.text,
                stock: stockController.text,
                price: priceController.text,
                isEdit: equipment != null,
              );
            },
            child: const Text("Simpan"),
          ),
        ],
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
          _equipments = response['equipments'];
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${response['message']}")),
          );
        }
      }
    } catch (e) {
      print("Error submit equipment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kelola Venue",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D9488),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Venue",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Nama Venue",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Harus diisi" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: "Deskripsi",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: "Harga per Jam",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "Lokasi / Area",
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedLocationId,
                          items: _locationsList.map<DropdownMenuItem<int>>((
                            item,
                          ) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['name']),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedLocationId = val),
                          validator: (v) => v == null ? "Pilih lokasi" : null,
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "Kategori Olahraga",
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategoryId,
                          items: _categoriesList.map<DropdownMenuItem<int>>((
                            item,
                          ) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['name']),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategoryId = val),
                          validator: (v) => v == null ? "Pilih kategori" : null,
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Opsi Pembayaran",
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedPaymentOption,
                          items: _paymentOptionsList.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['value'],
                              child: Text(item['label']!),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPaymentOption = val),
                          validator: (v) =>
                              v == null ? "Pilih opsi pembayaran" : null,
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveVenue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Simpan Perubahan Venue"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // === MULAI TAMBAHAN TOMBOL JADWAL ===
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VenueManageSchedulePage(
                              venueId: widget.venueId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Kelola Jadwal & Slot"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .orange
                            .shade800, // Warna oranye agar beda dengan tombol simpan
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  // === AKHIR TAMBAHAN TOMBOL JADWAL ===
                  const Divider(height: 40, thickness: 2),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daftar Equipment",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEquipmentDialog(),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF0D9488),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _equipments.isEmpty
                      ? const Text(
                          "Belum ada equipment.",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _equipments.length,
                          itemBuilder: (context, index) {
                            final eq = _equipments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  eq['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Stok: ${eq['stock']} | Harga: ${eq['price']}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showEquipmentDialog(equipment: eq),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteEquipment(eq['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
