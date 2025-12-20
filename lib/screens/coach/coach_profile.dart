// lib/screens/coach/coach_profile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '/models/coach_entry.dart';
import '/constants/api.dart';
import 'coach_profile_form.dart';

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

class CoachProfilePage extends StatefulWidget {
  const CoachProfilePage({super.key});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  bool _isLoading = true;
  CoachEntry? _coachProfile;
  bool _hasProfile = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadCoachProfile();
  }

  Future<void> _loadCoachProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final request = context.read<CookieRequest>();
    
    try {
      final response = await request.get(
        ApiConstants.coachProfileJson,
      );

      if (response['success'] == true) {
        setState(() {
          _hasProfile = response['has_profile'] ?? false;
          
          if (_hasProfile && response['profile'] != null) {
            _coachProfile = CoachEntry.fromJson(response['profile']);
          } else {
            _userData = response['user'];
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat profil';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
          side: const BorderSide(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
        ),
        title: const Text(
          'KONFIRMASI HAPUS',
          style: TextStyle(fontWeight: FontWeight.w900, color: NeoBrutalism.slate),
        ),
        content: const Text('Apakah Anda yakin ingin menghapus profil pelatih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: NeoBrutalism.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: NeoBrutalism.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final request = context.read<CookieRequest>();
    
    try {
      final response = await request.post(
        ApiConstants.coachProfileDelete,
        {},
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Profil berhasil dihapus'),
              backgroundColor: NeoBrutalism.primary,
            ),
          );
          _loadCoachProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal menghapus profil'),
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
    }
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(NeoBrutalism.primary),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : !_hasProfile
                          ? _buildEmptyState()
                          : _buildProfileView(),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MY PROFILE",
                style: TextStyle(
                  color: NeoBrutalism.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "PROFIL PELATIH",
                style: TextStyle(
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: NeoBrutalism.slate,
              ),
            ),
            const SizedBox(height: 24),
            _buildNeoButton(
              onPressed: _loadCoachProfile,
              label: 'COBA LAGI',
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final userName = _userData?['first_name'] ?? _userData?['username'] ?? 'User';
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NeoBrutalism.slate,
                      width: NeoBrutalism.borderWidth,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 80,
                    color: NeoBrutalism.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  userName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.slate,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '@${_userData?['username'] ?? 'coach'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: NeoBrutalism.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'PROFIL BELUM LENGKAP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.slate,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Anda belum menambahkan detail profil pelatih. Lengkapi profil untuk mulai menerima klien.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeoBrutalism.grey,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildNeoButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoachProfileFormPage(),
                      ),
                    );
                    
                    if (result == true) {
                      _loadCoachProfile();
                    }
                  },
                  label: 'LENGKAPI PROFIL',
                  icon: Icons.edit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    if (_coachProfile == null) return const SizedBox();
    
    return RefreshIndicator(
      onRefresh: _loadCoachProfile,
      color: NeoBrutalism.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeoBrutalism.slate,
                        width: NeoBrutalism.borderWidth,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: NeoBrutalism.primary,
                      backgroundImage: _coachProfile!.profilePicture != null
                          ? NetworkImage(_coachProfile!.profilePicture!)
                          : null,
                      child: _coachProfile!.profilePicture == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: NeoBrutalism.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    (_coachProfile!.fullName.isNotEmpty 
                        ? _coachProfile!.fullName 
                        : _coachProfile!.username ?? 'Coach').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.slate,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '@${_coachProfile!.username ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalism.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_coachProfile!.isVerified == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: NeoBrutalism.primary,
                        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                        border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: NeoBrutalism.white),
                          SizedBox(width: 6),
                          Text(
                            'TERVERIFIKASI',
                            style: TextStyle(
                              color: NeoBrutalism.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Detail Information Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMASI DETAIL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.slate,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.cake, 'Usia', 
                      _coachProfile!.age != null ? '${_coachProfile!.age} tahun' : '-'),
                  _buildDivider(),
                  _buildInfoRow(Icons.sports, 'Olahraga Utama', 
                      _coachProfile!.mainSportTrained ?? '-'),
                  _buildDivider(),
                  _buildInfoRow(Icons.attach_money, 'Tarif per Jam', 
                      _coachProfile!.ratePerHour != null 
                          ? 'Rp ${_coachProfile!.ratePerHour!.toStringAsFixed(0)}' 
                          : '-'),
                  _buildDivider(),
                  _buildInfoRow(Icons.location_on, 'Area Layanan', 
                      _coachProfile!.serviceAreas?.join(', ') ?? '-'),
                ],
              ),
            ),
            
            // Experience Card
            if (_coachProfile!.experienceDesc != null && 
                _coachProfile!.experienceDesc!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.white,
                            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                            border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
                          ),
                          child: const Icon(Icons.description, color: NeoBrutalism.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'PENGALAMAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: NeoBrutalism.slate,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _coachProfile!.experienceDesc!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: NeoBrutalism.slate,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNeoButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoachProfileFormPage(
                              existingProfile: _coachProfile,
                            ),
                          ),
                        );
                        
                        if (result == true) {
                          _loadCoachProfile();
                        }
                      },
                      label: 'EDIT',
                      icon: Icons.edit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNeoButton(
                      onPressed: _deleteProfile,
                      label: 'HAPUS',
                      icon: Icons.delete,
                      isPrimary: false,
                      isDanger: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: NeoBrutalism.borderWidth,
      color: NeoBrutalism.slate,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: NeoBrutalism.white,
            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
          ),
          child: Icon(icon, size: 16, color: NeoBrutalism.slate),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: NeoBrutalism.grey,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: NeoBrutalism.slate,
                ),
              ),
            ],
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
    bool isDanger = false,
  }) {
    final bgColor = isDanger ? NeoBrutalism.danger : (isPrimary ? NeoBrutalism.primary : NeoBrutalism.white);
    final fgColor = isDanger ? NeoBrutalism.white : (isPrimary ? NeoBrutalism.white : NeoBrutalism.slate);
    
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
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: NeoBrutalism.grey,
          disabledForegroundColor: NeoBrutalism.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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