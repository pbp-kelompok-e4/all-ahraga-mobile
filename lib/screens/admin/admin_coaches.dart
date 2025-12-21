import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/screens/admin/admin_menu.dart';

class AdminCoachesPage extends StatefulWidget {
  const AdminCoachesPage({super.key});

  @override
  State<AdminCoachesPage> createState() => _AdminCoachesPageState();
}

class _AdminCoachesPageState extends State<AdminCoachesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<dynamic>> fetchCoaches(CookieRequest request) async {
    String url = ApiConstants.adminCoaches;

    if (_searchQuery.isNotEmpty) {
      url += '?q=${Uri.encodeComponent(_searchQuery)}';
    }

    final response = await request.get(url);
    return response['coaches'];
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  String _formatAreas(dynamic serviceAreas) {
    if (serviceAreas == null) return '-';
    if (serviceAreas is List) {
      if (serviceAreas.isEmpty) return '-';
      if (serviceAreas.first is Map) {
        return serviceAreas.map((area) => area['name'].toString()).join(', ');
      }
      return serviceAreas.join(', ');
    }
    return '-';
  }

  String _getProxiedImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) {
      return '${ApiConstants.imageProxy}?url=${Uri.encodeComponent(imageUrl)}';
    }
    return imageUrl;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: NeoBrutalism.white,
        border: Border(
          bottom: BorderSide(color: NeoBrutalism.slate, width: 2.0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoBrutalism.slate, width: 2),
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
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MANAGEMENT AREA",
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
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(
              color: NeoBrutalism.slate,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Cari username pelatih...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: NeoBrutalism.slate),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: NeoBrutalism.slate,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: NeoBrutalism.slate,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: NeoBrutalism.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: NeoBrutalism.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder(
                future: fetchCoaches(request),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: NeoBrutalism.primary,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? "Belum ada pelatih terdaftar."
                                : "Username '$_searchQuery' tidak ditemukan.",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final coaches = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: coaches.length,
                    itemBuilder: (context, index) {
                      final coach = coaches[index];
                      final imageUrl = _getProxiedImageUrl(
                        coach['profile_picture'],
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: NeoBrutalism.slate,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: NeoBrutalism.slate,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: imageUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: NeoBrutalism.slate,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coach['username'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: NeoBrutalism.slate,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Sport: ${coach['sport'] ?? '-'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rate: Rp ${coach['rate'] ?? '-'} / jam",
                                  ),
                                  Text(
                                    "Area: ${_formatAreas(coach['service_areas'])}",
                                    style: const TextStyle(color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
