// lib/screens/coach/coach_profile_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'dart:convert';
import '/models/coach_entry.dart';
import '/models/sport_category.dart';
import '/models/location_area.dart';
import '/constants/api.dart';

// Design System Constants
class NeoBrutalism {
  static const Color primary = Color(0xFF0D9488);
  static const Color slate = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color white = Colors.white;
  
  static const double borderWidth = 2.0;
  static const double borderRadius = 8.0;
  static const Offset shadowOffset = Offset(4, 4);
}

class CoachProfileFormPage extends StatefulWidget {
  final CoachEntry? existingProfile;

  const CoachProfileFormPage({super.key, this.existingProfile});

  @override
  State<CoachProfileFormPage> createState() => _CoachProfileFormPageState();
}

class _CoachProfileFormPageState extends State<CoachProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _profilePictureUrlController = TextEditingController();

  bool _isLoading = false;

  List<SportCategory> _sportCategories = [];
  List<LocationArea> _locationAreas = [];

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
      _profilePictureUrlController.text = profile.profilePicture ?? '';
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
      final sportResponse = await request.get(
        ApiConstants.sportCategories,
      );

      if (sportResponse['success'] == true) {
        setState(() {
          _sportCategories = (sportResponse['categories'] as List)
              .map((e) => SportCategory.fromJson(e))
              .toList();
        });
      }

      final areaResponse = await request.get(
        ApiConstants.locationAreas,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih olahraga utama'),
          backgroundColor: NeoBrutalism.danger,
        ),
      );
      return;
    }

    if (_selectedAreaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu area layanan'),
          backgroundColor: NeoBrutalism.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = context.read<CookieRequest>();
      
      final response = await request.post(
        ApiConstants.coachProfileSave,
        jsonEncode({
          'age': int.parse(_ageController.text),
          'rate_per_hour': double.parse(_rateController.text),
          'main_sport_trained_id': _selectedSportId,
          'experience_desc': _experienceController.text,
          'service_area_ids': _selectedAreaIds,
          'profile_picture': _profilePictureUrlController.text.isEmpty 
              ? null 
              : _profilePictureUrlController.text,
        }),
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Profil berhasil disimpan',
              ),
              backgroundColor: NeoBrutalism.primary,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Gagal menyimpan profil',
              ),
              backgroundColor: NeoBrutalism.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: NeoBrutalism.danger,
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
    _profilePictureUrlController.dispose();
    super.dispose();
  }

  String _getProxiedImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    String fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : "${ApiConstants.baseUrl}$imageUrl";
    return '${ApiConstants.imageProxy}?url=${Uri.encodeComponent(fullUrl)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutalism.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: _isLoadingData
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(NeoBrutalism.primary),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: NeoBrutalism.white,
        border: Border(
          bottom: BorderSide(
            color: NeoBrutalism.slate,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
                boxShadow: const [
                  BoxShadow(
                    color: NeoBrutalism.slate,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: NeoBrutalism.slate, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PROFILE FORM",
                style: TextStyle(
                  color: NeoBrutalism.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                widget.existingProfile == null ? 'LENGKAPI PROFIL' : 'EDIT PROFIL',
                style: const TextStyle(
                  color: NeoBrutalism.slate,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: NeoBrutalism.danger),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: NeoBrutalism.slate,
              ),
            ),
            const SizedBox(height: 24),
            _buildNeoButton(
              onPressed: _loadFormData,
              label: 'COBA LAGI',
              icon: Icons.refresh,
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
            // Profile Picture Preview Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: NeoBrutalism.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoBrutalism.slate,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _profilePictureUrlController.text.isNotEmpty
                          ? Image.network(
                              _getProxiedImageUrl(_profilePictureUrlController.text),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('❌ Coach image proxy error: $error');
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: NeoBrutalism.grey,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(NeoBrutalism.primary),
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: NeoBrutalism.grey,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PREVIEW FOTO PROFIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: NeoBrutalism.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Picture URL Field
            _buildTextField(
              controller: _profilePictureUrlController,
              label: 'URL FOTO PROFIL',
              hint: 'https://example.com/foto-profil.jpg',
              icon: Icons.image,
              keyboardType: TextInputType.url,
              onChanged: (value) {
                // Trigger rebuild to update preview
                setState(() {});
              },
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
                    return 'URL tidak valid. Gunakan format: https://...';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Age Field
            _buildTextField(
              controller: _ageController,
              label: 'UMUR',
              hint: 'Masukkan umur Anda',
              icon: Icons.cake,
              keyboardType: TextInputType.number,
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

            // Rate Field
            _buildTextField(
              controller: _rateController,
              label: 'TARIF PER JAM (RP)',
              hint: 'Contoh: 100000',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
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

            // Sport Dropdown
            _buildDropdown(
              value: _selectedSportId,
              label: 'OLAHRAGA UTAMA',
              hint: 'Pilih olahraga',
              icon: Icons.sports,
              items: _sportCategories.map((sport) {
                return DropdownMenuItem<int>(
                  value: sport.id,
                  child: Text(sport.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSportId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Service Areas
            const Text(
              'AREA LAYANAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.slate,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
                boxShadow: const [
                  BoxShadow(
                    color: NeoBrutalism.slate,
                    offset: NeoBrutalism.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: _locationAreas.map((area) {
                  final isSelected = _selectedAreaIds.contains(area.id);
                  return CheckboxListTile(
                    title: Text(
                      area.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
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
                    activeColor: NeoBrutalism.primary,
                  );
                }).toList(),
              ),
            ),
            if (_selectedAreaIds.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  'Pilih minimal satu area layanan',
                  style: TextStyle(color: NeoBrutalism.danger, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 16),

            // Experience Field
            _buildTextField(
              controller: _experienceController,
              label: 'DESKRIPSI PENGALAMAN',
              hint: 'Ceritakan pengalaman Anda sebagai pelatih...',
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi pengalaman harus diisi';
                }
                if (value.length < 15) {
                  return 'Deskripsi minimal 15 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildNeoButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    label: 'BATAL',
                    icon: Icons.close,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNeoButton(
                    onPressed: _isLoading ? null : _submitForm,
                    label: _isLoading ? 'MENYIMPAN...' : 'SIMPAN',
                    icon: Icons.save,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: NeoBrutalism.slate,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: NeoBrutalism.slate,
                offset: NeoBrutalism.shadowOffset,
                blurRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(fontWeight: FontWeight.w600, color: NeoBrutalism.slate),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: NeoBrutalism.grey, fontWeight: FontWeight.w500),
              prefixIcon: icon != null ? Icon(icon, color: NeoBrutalism.slate, size: 20) : null,
              filled: true,
              fillColor: NeoBrutalism.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.primary, width: NeoBrutalism.borderWidth),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.danger, width: NeoBrutalism.borderWidth),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.danger, width: NeoBrutalism.borderWidth),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required int? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: NeoBrutalism.slate,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: NeoBrutalism.slate,
                offset: NeoBrutalism.shadowOffset,
                blurRadius: 0,
              ),
            ],
          ),
          child: DropdownButtonFormField<int>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: NeoBrutalism.grey, fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: NeoBrutalism.slate, size: 20),
              filled: true,
              fillColor: NeoBrutalism.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                borderSide: const BorderSide(color: NeoBrutalism.primary, width: NeoBrutalism.borderWidth),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNeoButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    bool isPrimary = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        boxShadow: onPressed != null
            ? const [
                BoxShadow(
                  color: NeoBrutalism.slate,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? NeoBrutalism.primary : NeoBrutalism.white,
          foregroundColor: isPrimary ? NeoBrutalism.white : NeoBrutalism.slate,
          disabledBackgroundColor: NeoBrutalism.grey,
          disabledForegroundColor: NeoBrutalism.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            side: BorderSide(
              color: onPressed != null ? NeoBrutalism.slate : NeoBrutalism.grey,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}