// lib/screens/coach_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'dart:async';
import '/models/coach_list_models.dart';
import 'coach_detail.dart';

class CoachListPage extends StatefulWidget {
  const CoachListPage({Key? key}) : super(key: key);

  @override
  State<CoachListPage> createState() => _CoachListPageState();
}

class _CoachListPageState extends State<CoachListPage> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  CoachListResponse? _coachData;
  String? _errorMessage;

  // Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedSportId;
  int? _selectedAreaId;
  int _currentPage = 1;

  // Dropdown data
  List<SportCategory> _sportCategories = [];
  List<ServiceArea> _locationAreas = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchSportCategories(),
      _fetchLocationAreas(),
    ]);
    await _fetchCoaches();
  }

  Future<void> _fetchSportCategories() async {
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get('http://localhost:8000/api/sport-categories/');
      
      if (response['success'] == true) {
        final categoriesResponse = SportCategoriesResponse.fromJson(response);
        setState(() {
          _sportCategories = categoriesResponse.categories;
        });
      }
    } catch (e) {
      print('Error fetching sport categories: $e');
    }
  }

  Future<void> _fetchLocationAreas() async {
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get('http://localhost:8000/api/location-areas/');
      
      if (response['success'] == true) {
        final areasResponse = LocationAreasResponse.fromJson(response);
        setState(() {
          _locationAreas = areasResponse.areas;
        });
      }
    } catch (e) {
      print('Error fetching location areas: $e');
    }
  }

  Future<void> _fetchCoaches({bool isLoadingMore = false}) async {
    if (isLoadingMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final request = context.read<CookieRequest>();
      
      // Build query parameters
      final params = <String, String>{
        'page': _currentPage.toString(),
      };
      
      if (_searchQuery.isNotEmpty) {
        params['q'] = _searchQuery;
      }
      
      if (_selectedSportId != null) {
        params['sport'] = _selectedSportId.toString();
      }
      
      if (_selectedAreaId != null) {
        params['area'] = _selectedAreaId.toString();
      }
      
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = 'http://localhost:8000/api/coaches/?$queryString';
      final response = await request.get(url);

      if (response['success'] == true) {
        setState(() {
          _coachData = CoachListResponse.fromJson(response);
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat data';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
        _currentPage = 1;
      });
      _fetchCoaches();
    });
  }

  void _onFilterChanged() {
    setState(() {
      _currentPage = 1;
    });
    _fetchCoaches();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedSportId = null;
      _selectedAreaId = null;
      _currentPage = 1;
    });
    _fetchCoaches();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _fetchCoaches();
    
    // Scroll to top
    if (mounted) {
      // Optional: scroll to top smoothly
    }
  }

  void _viewCoachDetail(CoachProfile coach) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachDetailPage(coachId: coach.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Pelatih',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _currentPage = 1);
          await _fetchCoaches();
        },
        color: Colors.teal,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              )
            : _errorMessage != null
                ? _buildErrorView()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _currentPage = 1);
                _fetchCoaches();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: _coachData == null || _coachData!.coaches.isEmpty
              ? _buildEmptyState()
              : _buildCoachList(),
        ),
        if (_coachData != null && _coachData!.pagination.totalPages > 1)
          _buildPagination(),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama pelatih...',
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          
          // Sport and Area filters
          Row(
            children: [
              Expanded(
                child: _buildSportDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAreaDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedSportId,
      decoration: InputDecoration(
        labelText: 'Olahraga',
        prefixIcon: const Icon(Icons.sports_basketball, color: Colors.teal, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Semua Olahraga', style: TextStyle(fontSize: 14)),
        ),
        ..._sportCategories.map((sport) {
          return DropdownMenuItem(
            value: sport.id,
            child: Text(sport.name, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSportId = value;
        });
        _onFilterChanged();
      },
      isExpanded: true,
      isDense: true,
    );
  }

  Widget _buildAreaDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedAreaId,
      decoration: InputDecoration(
        labelText: 'Area',
        prefixIcon: const Icon(Icons.location_on, color: Colors.teal, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Semua Area', style: TextStyle(fontSize: 14)),
        ),
        ..._locationAreas.map((area) {
          return DropdownMenuItem(
            value: area.id,
            child: Text(area.name, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedAreaId = value;
        });
        _onFilterChanged();
      },
      isExpanded: true,
      isDense: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada pelatih ditemukan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah filter pencarian Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coachData!.coaches.length,
      itemBuilder: (context, index) {
        final coach = _coachData!.coaches[index];
        return _buildCoachCard(coach);
      },
    );
  }

  Widget _buildCoachCard(CoachProfile coach) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _viewCoachDetail(coach),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: coach.profilePicture != null
                  ? Image.network(
                      coach.profilePicture!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            
            // Coach Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    coach.user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Age
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Umur',
                    value: '${coach.age ?? '-'} tahun',
                  ),
                  const SizedBox(height: 8),
                  
                  // Sport
                  _buildInfoRow(
                    icon: Icons.sports_basketball,
                    label: 'Olahraga',
                    value: coach.mainSportTrained?.name ?? '-',
                    valueColor: Colors.teal.shade700,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  
                  // Rate
                  _buildInfoRow(
                    icon: Icons.attach_money,
                    label: 'Tarif',
                    value: coach.formattedRate,
                    valueColor: Colors.green.shade700,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  
                  // Service Areas
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Area',
                    value: coach.serviceAreasText,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  // Experience Description
                  Text(
                    coach.displayExperience,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // View Detail Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewCoachDetail(coach),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Lihat Detail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Tidak ada gambar',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: valueColor ?? Colors.grey.shade700,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final pagination = _coachData!.pagination;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pagination.hasPrevious && !_isLoadingMore
                  ? () => _goToPage(pagination.previousPage!)
                  : null,
              icon: const Icon(Icons.chevron_left, size: 20),
              label: const Text('Sebelumnya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Page Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Text(
                'Hal ${pagination.currentPage} / ${pagination.totalPages}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ),
          ),
          
          // Next Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pagination.hasNext && !_isLoadingMore
                  ? () => _goToPage(pagination.nextPage!)
                  : null,
              icon: const Icon(Icons.chevron_right, size: 20),
              label: const Text('Berikutnya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}