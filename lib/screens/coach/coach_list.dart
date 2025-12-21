import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'dart:async';
import '/models/coach_list_models.dart';
import '/constants/api.dart';
import 'coach_detail.dart';

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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedSportId;
  int? _selectedAreaId;
  int _currentPage = 1;

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
    await Future.wait([_fetchSportCategories(), _fetchLocationAreas()]);
    await _fetchCoaches();
  }

  Future<void> _fetchSportCategories() async {
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(ApiConstants.sportCategories);

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
      final response = await request.get(ApiConstants.locationAreas);

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

      final params = <String, String>{'page': _currentPage.toString()};

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
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      final url = '${ApiConstants.coachList}?$queryString';
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
      backgroundColor: NeoBrutalism.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NeoBrutalism.primary,
                        ),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : RefreshIndicator(
                          onRefresh: () async {
                            setState(() => _currentPage = 1);
                            await _fetchCoaches();
                          },
                          color: NeoBrutalism.primary,
                          child: ListView(
                            children: [
                              _buildFilterSection(),
                              _buildContent(),
                              if (_coachData != null && 
                                  _coachData!.pagination.totalPages > 1)
                                _buildPagination(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                border: Border.all(
                  color: NeoBrutalism.slate,
                  width: NeoBrutalism.borderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: NeoBrutalism.slate,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: NeoBrutalism.slate,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "COACH LIST",
                  style: TextStyle(
                    color: NeoBrutalism.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "DAFTAR PELATIH",
                  style: TextStyle(
                    color: NeoBrutalism.slate,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
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
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(
              color: NeoBrutalism.slate,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Cari nama pelatih...',
              hintStyle: const TextStyle(
                color: NeoBrutalism.grey,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: NeoBrutalism.slate,
                size: 20,
              ),
              filled: true,
              fillColor: NeoBrutalism.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: _buildOutlineBorder(),
              enabledBorder: _buildOutlineBorder(),
              focusedBorder: _buildOutlineBorder(isFocused: true),
            ),
          ),
          const SizedBox(height: 12),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              
              if (isSmallScreen) {
                return Column(
                  children: [
                    _buildSportDropdown(),
                    const SizedBox(height: 12),
                    _buildAreaDropdown(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildResetButton(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSportDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildAreaDropdown()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildResetButton(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
      borderSide: BorderSide(
        color: isFocused ? NeoBrutalism.primary : NeoBrutalism.slate,
        width: NeoBrutalism.borderWidth,
      ),
    );
  }

  Widget _buildSportDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedSportId,
        decoration: const InputDecoration(
          labelText: 'OLAHRAGA',
          labelStyle: TextStyle(
            color: NeoBrutalism.grey,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          prefixIcon: Icon(
            Icons.sports_basketball,
            color: NeoBrutalism.slate,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: NeoBrutalism.slate,
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Semua'),
          ),
          ..._sportCategories.map((sport) {
            return DropdownMenuItem(
              value: sport.id,
              child: Text(sport.name),
            );
          }).toList(),
        ],
        onChanged: (value) {
          setState(() => _selectedSportId = value);
          _onFilterChanged();
        },
        isExpanded: true,
        isDense: true,
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedAreaId,
        decoration: const InputDecoration(
          labelText: 'AREA',
          labelStyle: TextStyle(
            color: NeoBrutalism.grey,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          prefixIcon: Icon(
            Icons.location_on,
            color: NeoBrutalism.slate,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: NeoBrutalism.slate,
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Semua'),
          ),
          ..._locationAreas.map((area) {
            return DropdownMenuItem(
              value: area.id,
              child: Text(area.name),
            );
          }).toList(),
        ],
        onChanged: (value) {
          setState(() => _selectedAreaId = value);
          _onFilterChanged();
        },
        isExpanded: true,
        isDense: true,
      ),
    );
  }

  Widget _buildResetButton() {
    return _buildNeoButton(
      onPressed: _resetFilters,
      label: 'RESET FILTER',
      icon: Icons.refresh,
      isPrimary: false,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: NeoBrutalism.danger,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NeoBrutalism.slate,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildNeoButton(
              onPressed: _fetchCoaches,
              label: 'COBA LAGI',
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_coachData == null || _coachData!.coaches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _coachData!.coaches.length,
      itemBuilder: (context, index) {
        final coach = _coachData!.coaches[index];
        return _buildCoachCard(coach);
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NeoBrutalism.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
              border: Border.all(
                color: NeoBrutalism.slate,
                width: NeoBrutalism.borderWidth,
              ),
              boxShadow: const [
                BoxShadow(
                  color: NeoBrutalism.slate,
                  offset: NeoBrutalism.shadowOffset,
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.group_off,
              size: 64,
              color: NeoBrutalism.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'BELUM ADA PELATIH',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.slate,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba ubah filter pencarian',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NeoBrutalism.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getProxiedImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    String fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : "${ApiConstants.baseUrl}$imageUrl";

    return '${ApiConstants.imageProxy}?url=${Uri.encodeComponent(fullUrl)}';
  }

  Widget _buildCoachCard(CoachProfile coach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalism.slate,
            offset: NeoBrutalism.shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewCoachDetail(coach),
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(NeoBrutalism.borderRadius - 2),
              ),
              child: coach.profilePicture != null &&
                      coach.profilePicture!.isNotEmpty
                  ? Image.network(
                      _getProxiedImageUrl(coach.profilePicture!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.user.fullName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.slate,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person,
                    'Umur: ${coach.age ?? '-'} tahun',
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.sports_basketball,
                    coach.mainSportTrained?.name ?? '-',
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.attach_money,
                    coach.formattedRate,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.location_on, coach.serviceAreasText),
                  const SizedBox(height: 12),
                  Text(
                    coach.displayExperience,
                    style: const TextStyle(
                      fontSize: 13,
                      color: NeoBrutalism.grey,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _buildNeoButton(
                      onPressed: () => _viewCoachDetail(coach),
                      label: 'LIHAT DETAIL',
                      icon: Icons.arrow_forward,
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
      color: NeoBrutalism.grey,
      child: const Center(
        child: Icon(Icons.person, size: 64, color: NeoBrutalism.white),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: NeoBrutalism.slate),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isHighlight ? NeoBrutalism.primary : NeoBrutalism.slate,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final pagination = _coachData!.pagination;
    final itemsPerPage = _coachData!.coaches.length;
    final startItem = (pagination.currentPage - 1) * itemsPerPage + 1;
    final endItem = startItem + _coachData!.coaches.length - 1;
    final totalCoaches = pagination.totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(
          color: NeoBrutalism.slate,
          width: NeoBrutalism.borderWidth,
        ),
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
          Text(
            'Menampilkan $startItem - $endItem dari $totalCoaches pelatih',
            style: const TextStyle(
              fontSize: 12,
              color: NeoBrutalism.grey,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _buildPaginationButton(
                      onPressed: pagination.hasPrevious && !_isLoadingMore
                          ? () => _goToPage(pagination.previousPage!)
                          : null,
                      label: isSmallScreen ? 'Prev' : 'Sebelumnya',
                      icon: Icons.chevron_left,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.primary,
                      borderRadius: BorderRadius.circular(
                        NeoBrutalism.borderRadius,
                      ),
                      border: Border.all(
                        color: NeoBrutalism.slate,
                        width: NeoBrutalism.borderWidth,
                      ),
                    ),
                    child: Text(
                      '${pagination.currentPage}/${pagination.totalPages}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildPaginationButton(
                      onPressed: pagination.hasNext && !_isLoadingMore
                          ? () => _goToPage(pagination.nextPage!)
                          : null,
                      label: isSmallScreen ? 'Next' : 'Berikutnya',
                      icon: Icons.chevron_right,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_coachData!.pagination.totalPages <= 10) ...[
            const SizedBox(height: 16),
            _buildPageDots(pagination),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
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
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoBrutalism.white,
          foregroundColor: NeoBrutalism.slate,
          disabledBackgroundColor: NeoBrutalism.grey,
          disabledForegroundColor: NeoBrutalism.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            side: BorderSide(
              color: onPressed != null ? NeoBrutalism.slate : NeoBrutalism.grey,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPageDots(PaginationInfo pagination) {
    final totalPages = pagination.totalPages;
    final currentPage = pagination.currentPage;

    int startPage = 1;
    int endPage = totalPages;

    if (totalPages > 7) {
      startPage = (currentPage - 3).clamp(1, totalPages - 6);
      endPage = (startPage + 6).clamp(7, totalPages);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (startPage > 1) ...[
            _buildPageDot(1, currentPage == 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
          for (int page = startPage; page <= endPage; page++)
            _buildPageDot(page, currentPage == page),
          if (endPage < totalPages) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            _buildPageDot(totalPages, currentPage == totalPages),
          ],
        ],
      ),
    );
  }

  Widget _buildPageDot(int pageNumber, bool isActive) {
    return GestureDetector(
      onTap: _isLoadingMore ? null : () => _goToPage(pageNumber),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 32 : 24,
        height: 24,
        decoration: BoxDecoration(
          color: isActive ? NeoBrutalism.primary : NeoBrutalism.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
          border: Border.all(
            color: NeoBrutalism.slate,
            width: NeoBrutalism.borderWidth,
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: NeoBrutalism.slate,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isActive ? NeoBrutalism.white : NeoBrutalism.slate,
            ),
          ),
        ),
      ),
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
          backgroundColor: isPrimary
              ? NeoBrutalism.primary
              : NeoBrutalism.white,
          foregroundColor: isPrimary ? NeoBrutalism.white : NeoBrutalism.slate,
          disabledBackgroundColor: NeoBrutalism.grey,
          disabledForegroundColor: NeoBrutalism.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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