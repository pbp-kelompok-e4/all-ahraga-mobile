import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/models/coach_entry.dart';
import '/models/sport_category.dart';
import '/models/location_area.dart';
import 'package:http/browser_client.dart'; // Tambahkan ini (khusus web)
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk cek apakah ini Web

class CoachProfileFormPage extends StatefulWidget {
  final CoachEntry? existingProfile;
  
  const CoachProfileFormPage({
    super.key,
    this.existingProfile,
  });

  @override
  State<CoachProfileFormPage> createState() => _CoachProfileFormPageState();
}

class _CoachProfileFormPageState extends State<CoachProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  // Dropdown data
  List<SportCategory> _sportCategories = [];
  List<LocationArea> _locationAreas = [];
  
  // Selected values
  int? _selectedSportId;
  List<int> _selectedAreaIds = [];
  
  bool _isLoadingData = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _fillExistingData();
  }

  void _fillExistingData() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _ageController.text = profile.age?.toString() ?? '';
      _rateController.text = profile.ratePerHour?.toString() ?? '';
      _experienceController.text = profile.experienceDesc ?? '';
      _selectedSportId = profile.mainSportTrainedId;
      _selectedAreaIds = profile.serviceAreaIds ?? [];
    }
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    final request = context.read<CookieRequest>();
    
    try {
      // Load sport categories
      final sportResponse = await request.get(
        'http://localhost:8000/api/sport-categories/', // Ganti dengan URL Anda
      );
      
      if (sportResponse['success'] == true) {
        setState(() {
          _sportCategories = (sportResponse['categories'] as List)
              .map((e) => SportCategory.fromJson(e))
              .toList();
        });
      }
      
      // Load location areas
      final areaResponse = await request.get(
        'http://localhost:8000/api/location-areas/', // Ganti dengan URL Anda
      );
      
      if (areaResponse['success'] == true) {
        setState(() {
          _locationAreas = (areaResponse['areas'] as List)
              .map((e) => LocationArea.fromJson(e))
              .toList();
        });
      }
      
      setState(() {
        _isLoadingData = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih olahraga utama'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAreaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu area layanan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = context.read<CookieRequest>();
      
      // Prepare multipart request
      var uri = Uri.parse('http://localhost:8000/coach/profile/save/'); // Ganti dengan URL Anda
      var multipartRequest = http.MultipartRequest('POST', uri);
      
      // Add cookies from CookieRequest
      final cookies = request.cookies;
      if (cookies.isNotEmpty) {
        multipartRequest.headers['cookie'] = cookies.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
      }
      
      // Add form fields
      multipartRequest.fields['age'] = _ageController.text;
      multipartRequest.fields['rate_per_hour'] = _rateController.text;
      multipartRequest.fields['main_sport_trained_id'] = _selectedSportId.toString();
      multipartRequest.fields['experience_desc'] = _experienceController.text;
      multipartRequest.fields['service_area_ids'] = jsonEncode(_selectedAreaIds);
      
      // Add image if selected
      if (_imageFile != null) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            _imageFile!.path,
          ),
        );
      }
      
      // Send request
      http.StreamedResponse streamedResponse;

      if (kIsWeb) {
        final client = BrowserClient()..withCredentials = true;
        streamedResponse = await client.send(multipartRequest);
      } else {
        final request = context.read<CookieRequest>(); 
        final cookies = request.cookies;
        if (cookies.isNotEmpty) {
           multipartRequest.headers['cookie'] = cookies.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
        }
        streamedResponse = await multipartRequest.send();
      }

      final response = await http.Response.fromStream(streamedResponse);
      // --- SELESAI KODE BARU ---

      final responseData = jsonDecode(response.body);
      
      if (mounted) {
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Profil berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Gagal menyimpan profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _rateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile == null 
            ? 'Lengkapi Profil' 
            : 'Edit Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFormData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: _imageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : widget.existingProfile?.profilePicture != null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.existingProfile!.profilePicture!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey.shade600,
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload),
                    label: Text(_imageFile != null || widget.existingProfile?.profilePicture != null
                        ? 'Ganti Foto'
                        : 'Pilih Foto Profil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Age Field
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Umur',
                hintText: 'Masukkan umur Anda',
                prefixIcon: const Icon(Icons.cake),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Umur harus diisi';
                }
                final age = int.tryParse(value);
                if (age == null || age < 18 || age > 100) {
                  return 'Umur harus antara 18-100 tahun';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Rate per Hour Field
            TextFormField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tarif per Jam (Rp)',
                hintText: 'Contoh: 100000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tarif harus diisi';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate <= 0) {
                  return 'Tarif harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Sport Category Dropdown
            DropdownButtonFormField<int>(
              value: _selectedSportId,
              decoration: InputDecoration(
                labelText: 'Olahraga Utama',
                prefixIcon: const Icon(Icons.sports),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text('Pilih olahraga'),
              items: _sportCategories.map((sport) {
                return DropdownMenuItem<int>(
                  value: sport.id,
                  child: Text(sport.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSportId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Pilih olahraga utama';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Service Areas Multi-select
            const Text(
              'Area Layanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _locationAreas.map((area) {
                  final isSelected = _selectedAreaIds.contains(area.id);
                  return CheckboxListTile(
                    title: Text(area.name),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedAreaIds.add(area.id);
                        } else {
                          _selectedAreaIds.remove(area.id);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            ),
            if (_selectedAreaIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  'Pilih minimal satu area layanan',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Experience Description Field
            TextFormField(
              controller: _experienceController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Deskripsi Pengalaman',
                hintText: 'Ceritakan pengalaman Anda sebagai pelatih...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi pengalaman harus diisi';
                }
                if (value.length < 50) {
                  return 'Deskripsi minimal 50 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Simpan Profil'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}