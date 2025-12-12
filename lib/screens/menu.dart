import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/widgets/left_drawer.dart';
import 'package:all_ahraga/screens/booking/create_booking.dart';
import 'package:all_ahraga/screens/coach_menu.dart';
import 'package:all_ahraga/constants/api.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _venues = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    if (request.jsonData.isNotEmpty && request.jsonData.containsKey('role_type')) {
      userRole = request.jsonData['role_type'];
    }
    
    // Jika user adalah Coach, redirect ke Coach Menu
    if (userRole == 'COACH') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CoachHomePage()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVenues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
      '${ApiConstants.venues}?search=$_searchQuery', 
    );

      if (response['success'] == true) {
        setState(() {
          _venues = response['venues'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal memuat venue';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ALL-AHRAGA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D9488),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const LeftDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchVenues,
        color: const Color(0xFF0D9488),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner with Search
              _buildHeaderBanner(),

              // Venue List Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Venue List
                    _buildVenueList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan Lapangan Olahraga 🏟️',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cari dan booking lapangan favorit Anda dengan mudah',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
              },
              onSubmitted: (_) => _fetchVenues(),
              decoration: InputDecoration(
                hintText: 'Cari lapangan berdasarkan nama...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF0D9488),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _fetchVenues();
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Color(0xFF0D9488),
                      ),
                      onPressed: _fetchVenues,
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF0D9488)),
              SizedBox(height: 16),
              Text('Memuat venue...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchVenues,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_venues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Belum ada venue tersedia'
                    : 'Tidak ada venue untuk "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _fetchVenues();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Hapus pencarian'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _venues.length,
      itemBuilder: (context, index) {
        final venue = _venues[index];
        return _buildVenueCard(venue);
      },
    );
  }

  Widget _buildVenueCard(Map<String, dynamic> venue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBookingPage(venueId: venue['id']),
            ),
          ).then((result) {
            if (result == true) {
              _fetchVenues(); // Refresh after booking
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Image with Rating Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: venue['image'] != null &&
                          venue['image'].toString().isNotEmpty
                      ? Image.network(
                          'http://localhost:8000${venue['image']}',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            );
                          },
                        )
                      : _buildPlaceholderImage(),
                ),

                // Rating Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${venue['rating'] ?? 5.0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Venue Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue Name
                  Text(
                    venue['name'] ?? 'Venue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue['location'] ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sport Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sports_soccer,
                          size: 14,
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          venue['sport_category'] ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  if (venue['description'] != null &&
                      venue['description'].toString().isNotEmpty)
                    Text(
                      venue['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const Divider(height: 24),

                  // Price & Booking Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ${_formatPrice((venue['price_per_hour'] ?? 0).toDouble())}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          Text(
                            '/jam',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      // Booking Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreateBookingPage(venueId: venue['id']),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _fetchVenues();
                            }
                          });
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Booking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stadium,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}