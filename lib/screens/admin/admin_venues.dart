import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:all_ahraga/constants/api.dart';
import 'package:all_ahraga/screens/admin/admin_menu.dart';

class AdminVenuesPage extends StatefulWidget {
  const AdminVenuesPage({super.key});

  @override
  State<AdminVenuesPage> createState() => _AdminVenuesPageState();
}

class _AdminVenuesPageState extends State<AdminVenuesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<dynamic>> fetchVenues(CookieRequest request) async {
    String url = ApiConstants.adminVenues;

    if (_searchQuery.isNotEmpty) {
      url += '?q=${Uri.encodeComponent(_searchQuery)}';
    }

    final response = await request.get(url);
    return response['venues'];
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
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
                    "DAFTAR VENUE",
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
              hintText: 'Cari nama venue...',
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
                future: fetchVenues(request),
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
                                ? "Belum ada venue terdaftar."
                                : "Venue '$_searchQuery' tidak ditemukan.",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final venues = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: venues.length,
                    itemBuilder: (context, index) {
                      final venue = venues[index];
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    venue['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: NeoBrutalism.slate,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: NeoBrutalism.slate,
                                    ),
                                  ),
                                  child: Text(
                                    venue['category'],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              color: NeoBrutalism.slate,
                              height: 24,
                            ),
                            _infoRow(
                              Icons.person,
                              "Pemilik: ${venue['owner']}",
                            ),
                            _infoRow(
                              Icons.location_on,
                              "Lokasi: ${venue['location']}",
                            ),
                            _infoRow(
                              Icons.attach_money,
                              "Harga: Rp ${venue['price']}/jam",
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

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: NeoBrutalism.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: NeoBrutalism.slate),
            ),
          ),
        ],
      ),
    );
  }
}
