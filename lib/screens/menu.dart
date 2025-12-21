import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/widgets/left_drawer.dart';
import 'package:all_ahraga/screens/booking/create_booking.dart';
import 'package:all_ahraga/screens/coach_menu.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/widgets/error_retry_widget.dart';

const Color _kBg = Colors.white;
const Color _kTosca = Color(0xFF0D9488); 
const Color _kYellow = Color(0xFFFBBF24);
const Color _kSlate = Color(0xFF0F172A); 
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626); 

const double _kBorderWidth = 2.0;
const double _kRadius = 8.0;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> _venues = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? _selectedLocation;
  String? _selectedCategory;

  int _currentPage = 1;
  int _totalPages = 1;

  final List<String> _allLocations = [
    'Bekasi',
    'Bogor',
    'Depok',
    'Jakarta',
    'Tangerang',
  ];
  final List<String> _allCategories = [
    'Basket',
    'Futsal',
    'Mini Soccer',
    'Padel',
    'Tenis',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRoleAndRoute();
      _fetchVenues();
    });
  }

  void _checkUserRoleAndRoute() {
    final request = context.read<CookieRequest>();
    String userRole = 'CUSTOMER'; 
    if (request.jsonData.isNotEmpty &&
        request.jsonData.containsKey('role_type')) {
      userRole = request.jsonData['role_type'];
    }

    if (userRole == 'COACH') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CoachHomePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredVenues {
    return _venues.where((venue) {
      final bool locationMatches =
          _selectedLocation == null ||
          (venue['location'] ?? '') == _selectedLocation;
      final bool categoryMatches =
          _selectedCategory == null ||
          (venue['sport_category'] ?? '') == _selectedCategory;
      return locationMatches && categoryMatches;
    }).toList();
  }

  Future<void> _fetchVenues({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        '${ApiConstants.venues}?search=$_searchQuery&page=$_currentPage',
      );

      if (response['success'] == true) {
        final List<dynamic> fetchedVenues = response['venues'] ?? [];
        if (mounted) {
          setState(() {
            _venues = fetchedVenues;
            _totalPages = response['total_pages'] ?? 1;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response['message'] ?? 'Gagal memuat venue';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: const LeftDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildDecoratedAppBar(),

            Expanded(
              child: RefreshIndicator(
                color: _kTosca,
                backgroundColor: _kBg,
                onRefresh: () => _fetchVenues(page: 1),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildFilterSection(),
                            const SizedBox(height: 24),

                            // Section Title
                            Row(
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  color: _kTosca,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "AVAILABLE VENUES",
                                  style: TextStyle(
                                    color: _kSlate,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildContentList(),
                            
                            if (!_isLoading && _venues.isNotEmpty)
                              _buildPagination(),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSlate, width: _kBorderWidth),
        boxShadow: const [
          BoxShadow(color: _kSlate, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Sebelumnya
          _PaginationButton(
            text: "Sebelumnya",
            icon: Icons.chevron_left,
            isDisabled: _currentPage <= 1,
            onTap: () => _fetchVenues(page: _currentPage - 1),
          ),

          // Info Halaman
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kTosca.withOpacity(0.5)),
            ),
            child: Text(
              "Halaman $_currentPage dari $_totalPages",
              style: const TextStyle(
                color: _kSlate,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),

          // Tombol Berikutnya
          _PaginationButton(
            text: "Berikutnya",
            icon: Icons.chevron_right,
            isRightIcon: true,
            isDisabled: _currentPage >= _totalPages,
            onTap: () => _fetchVenues(page: _currentPage + 1),
            color: _kTosca,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildDecoratedAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(
          bottom: BorderSide(color: _kSlate, width: _kBorderWidth),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NeoIconButton(
            icon: Icons.menu,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            bgColor: Colors.white,
          ),
          Row(
            children: const [
              Icon(Icons.sports_soccer, color: _kTosca, size: 24),
              SizedBox(width: 8),
              Text(
                "ALL-AHRAGA",
                style: TextStyle(
                  color: _kSlate,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kTosca,
        border: Border(
          bottom: BorderSide(color: _kSlate, width: _kBorderWidth),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kSlate.withOpacity(0.2), width: 2),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kYellow,
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kSlate, width: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Temukan Lapangan Olahraga",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        color: _kSlate,
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Cari dan booking lapangan favorit Anda dengan mudah",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_kRadius),
                    border: Border.all(color: _kSlate, width: _kBorderWidth),
                    boxShadow: const [
                      BoxShadow(
                        color: _kSlate,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchQuery = value,
                    onSubmitted: (_) {
                      setState(() {
                        _selectedLocation = null;
                        _selectedCategory = null;
                      });
                      _fetchVenues(page: 1);
                    },
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _kSlate,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari Lapangan berdasarkan nama...',
                      hintStyle: const TextStyle(
                        color: _kMuted,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: _kSlate),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: _kRed),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _fetchVenues(page: 1);
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kSlate,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          _NeoDropdown(
            hint: "LOKASI",
            value: _selectedLocation,
            items: _allLocations,
            onChanged: (val) => setState(() => _selectedLocation = val),
          ),
          const SizedBox(width: 12),
          _NeoDropdown(
            hint: "KATEGORI",
            value: _selectedCategory,
            items: _allCategories,
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          if (_selectedLocation != null || _selectedCategory != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = null;
                  _selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: _kSlate, width: _kBorderWidth),
                  boxShadow: const [
                    BoxShadow(color: _kSlate, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: _kTosca),
        ),
      );
    }

    if (_error != null) {
      return ErrorRetryWidget(
        message: _error!,
        onRetry: () => _fetchVenues(page: 1),
      );
    }

    if (_filteredVenues.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: _kSlate, width: 2),
            borderRadius: BorderRadius.circular(_kRadius),
            color: const Color(0xFFF1F5F9),
          ),
          child: Column(
            children: const [
              Icon(Icons.search_off, size: 48, color: _kMuted),
              SizedBox(height: 12),
              Text(
                "TIDAK DITEMUKAN",
                style: TextStyle(fontWeight: FontWeight.w900, color: _kSlate),
              ),
              Text(
                "Coba kata kunci atau filter lain.",
                style: TextStyle(color: _kMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredVenues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return _VenueCard(
          venue: _filteredVenues[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CreateBookingPage(venueId: _filteredVenues[index]['id']),
              ),
            ).then((result) {
              if (result == true) _fetchVenues(page: _currentPage);
            });
          },
        );
      },
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isRightIcon;
  final Color color;
  final Color textColor;

  const _PaginationButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
    this.isRightIcon = false,
    this.color = const Color(0xFFE2E8F0),
    this.textColor = _kSlate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kSlate, width: 1.5),
            boxShadow: isDisabled 
                ? null 
                : [const BoxShadow(color: _kSlate, offset: Offset(2, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isRightIcon) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (isRightIcon) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _NeoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;

  const _NeoIconButton({
    required this.icon,
    required this.onTap,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: _kSlate, width: _kBorderWidth),
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: const [BoxShadow(color: _kSlate, offset: Offset(2, 2))],
        ),
        child: Icon(icon, color: _kSlate, size: 22),
      ),
    );
  }
}

class _NeoDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const _NeoDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: value != null ? const Color(0xFFE0F2F1) : Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSlate, width: _kBorderWidth),
        boxShadow: const [BoxShadow(color: _kSlate, offset: Offset(2, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: _kMuted,
              fontSize: 13,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: _kSlate),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(_kRadius),
          style: const TextStyle(
            color: _kSlate,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item.toUpperCase()),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _NeoButton({
    required this.text,
    required this.onTap,
    this.color = _kTosca,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: _kSlate, width: _kBorderWidth),
          boxShadow: const [BoxShadow(color: _kSlate, offset: Offset(2, 2))],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  final VoidCallback onTap;

  const _VenueCard({required this.venue, required this.onTap});

  String _formatPrice(dynamic price) {
    double p = 0;
    if (price is int) p = price.toDouble();
    if (price is double) p = price;
    return p
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _getProxiedImageUrl(String originalUrl) {
    return '${ApiConstants.imageProxy}?url=${Uri.encodeComponent(originalUrl)}';
  }

  @override
  Widget build(BuildContext context) {
    String? rawImage = venue['image'];
    String? imageUrl;
    String? proxiedUrl;
    
    if (rawImage != null && rawImage.toString().isNotEmpty) {
      if (rawImage.startsWith('http')) {
        imageUrl = rawImage;
      } else {
        imageUrl =
            '${ApiConstants.baseUrl}$rawImage'; 
      }
      proxiedUrl = _getProxiedImageUrl(imageUrl);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: _kSlate, width: _kBorderWidth),
          boxShadow: const [
            BoxShadow(color: _kSlate, offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _kSlate, width: _kBorderWidth),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_kRadius - 2),
                ),
                child: proxiedUrl != null
                    ? Image.network(
                        proxiedUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Image proxy error: $error');
                          return _PlaceholderImage();
                        },
                      )
                    : _PlaceholderImage(),
              ),
            ),

            // INFO SECTION
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Tag(
                        text: venue['sport_category'] ?? 'SPORTS',
                        color: _kTosca,
                      ),
                      const SizedBox(width: 8),
                      // RATING BOX 
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kYellow,
                          border: Border.all(color: _kSlate, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: _kSlate),
                            const SizedBox(width: 4),
                            Text(
                              "${venue['rating'] ?? 5.0}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _kSlate,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    (venue['name'] ?? 'Venue Name').toString().toUpperCase(),
                    style: const TextStyle(
                      color: _kSlate,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: _kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue['location'] ?? 'Unknown Location',
                          style: const TextStyle(
                            color: _kMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: _kSlate, thickness: 1),
                  const SizedBox(height: 12),

                  // Footer: Price & Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "HARGA / JAM",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _kMuted,
                            ),
                          ),
                          Text(
                            "RP ${_formatPrice(venue['price_per_hour'])}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _kTosca,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _kSlate,
                          borderRadius: BorderRadius.circular(_kRadius),
                          boxShadow: const [
                            BoxShadow(color: _kMuted, offset: Offset(2, 2)),
                          ],
                        ),
                        child: const Text(
                          "BOOK NOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.image_not_supported_outlined, color: _kMuted, size: 32),
            SizedBox(height: 4),
            Text(
              "NO IMAGE",
              style: TextStyle(
                color: _kMuted,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _Tag({
    required this.text,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _kSlate, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
