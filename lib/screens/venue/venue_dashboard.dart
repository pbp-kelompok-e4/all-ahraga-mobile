import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/screens/venue/venue_manage.dart';
import 'package:all_ahraga/screens/venue/venue_form.dart';
import 'package:all_ahraga/constants/api.dart';
import 'dart:convert';

class NeoColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Colors.white;
}

class NeoContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool hasShadow;

  const NeoContainer({
    super.key,
    required this.child,
    this.color = NeoColors.background,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NeoColors.text, width: 2),
          boxShadow: hasShadow
              ? const [
                  BoxShadow(
                    color: NeoColors.text,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

class NeoButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = NeoColors.primary,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoContainer(
      onTap: onPressed,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class VenueDashboardPage extends StatefulWidget {
  const VenueDashboardPage({super.key});

  @override
  State<VenueDashboardPage> createState() => _VenueDashboardPageState();
}

class _VenueDashboardPageState extends State<VenueDashboardPage> {
  late Future<List<Map<String, dynamic>>> _venuesFuture;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _venuesFuture = fetchVenues(request);
  }

  Future<List<Map<String, dynamic>>> fetchVenues(CookieRequest request) async {
    final String url = ApiConstants.venueDashboard;

    try {
      final response = await request.get(url);

      if (response is! Map<String, dynamic>) {
        throw Exception("Server returned invalid format.");
      }

      List<Map<String, dynamic>> listVenues = [];
      if (response['venues'] != null) {
        for (var d in response['venues']) {
          listVenues.add(d);
        }
      }
      return listVenues;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshVenues() async {
    final request = context.read<CookieRequest>();
    setState(() {
      _venuesFuture = fetchVenues(request);
    });
    await _venuesFuture;
  }

  Future<void> _deleteVenue(int venueId) async {
    final request = context.read<CookieRequest>();
    final url = ApiConstants.venueDelete(venueId);

    try {
      final response = await request.postJson(url, jsonEncode({}));

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? "Venue berhasil dihapus",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: NeoColors.text,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.white, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          );
          _refreshVenues();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${response['message']}")),
          );
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

  void _showDeleteConfirmation(int venueId, String venueName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoContainer(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: NeoColors.text, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    "HAPUS VENUE?",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: NeoColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Apakah Anda yakin ingin menghapus '$venueName'? Data tidak dapat dikembalikan.",
                style: const TextStyle(
                  color: NeoColors.muted,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "BATAL",
                      style: TextStyle(
                        color: NeoColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeoButton(
                    label: "HAPUS",
                    backgroundColor: NeoColors.danger,
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteVenue(venueId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Widget (Updated to match Coach Revenue)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: NeoColors.background,
        border: Border(bottom: BorderSide(color: NeoColors.text, width: 2.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.text, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.text,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: NeoColors.text,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "VENUE AREA",
                    style: TextStyle(
                      color: NeoColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "VENUE DASHBOARD",
                    style: TextStyle(
                      color: NeoColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Refresh Button
          GestureDetector(
            onTap: _refreshVenues,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NeoColors.text, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: NeoColors.text,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.refresh, color: NeoColors.text, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(), // Updated Header

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshVenues,
                color: NeoColors.text,
                backgroundColor: NeoColors.primary,
                child: FutureBuilder(
                  future: _venuesFuture,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: NeoColors.text,
                          strokeWidth: 4,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: NeoColors.text,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "SOMETHING WENT WRONG",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${snapshot.error}",
                              style: const TextStyle(color: NeoColors.muted),
                            ),
                            const SizedBox(height: 24),
                            NeoButton(
                              label: "TRY AGAIN",
                              onPressed: _refreshVenues,
                              backgroundColor: NeoColors.text,
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NeoContainer(
                              padding: const EdgeInsets.all(24),
                              hasShadow: true,
                              child: const Icon(
                                Icons.stadium_outlined,
                                size: 64,
                                color: NeoColors.text,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "NO VENUES FOUND",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Start adding your venue collection now.",
                              style: TextStyle(color: NeoColors.muted),
                            ),
                            const SizedBox(height: 32),
                            NeoButton(
                              label: "ADD FIRST VENUE",
                              icon: Icons.add,
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const VenueFormPage(),
                                  ),
                                );
                                if (result == true) _refreshVenues();
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          NeoContainer(
                            padding: const EdgeInsets.all(20),
                            color: NeoColors.primary,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "TOTAL VENUES",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${snapshot.data!.length}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: NeoColors.text,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: NeoColors.text,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          const Text(
                            "YOUR LIST",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.text,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          ...List.generate(snapshot.data!.length, (index) {
                            final venue = snapshot.data![index];
                            final String? imageUrl = venue['image_url'];

                            String _getProxiedImageUrl(String originalUrl) {
                              return '${ApiConstants.imageProxy}?url=${Uri.encodeComponent(originalUrl)}';
                            }

                            String? proxiedUrl;
                            if (imageUrl != null && imageUrl.isNotEmpty) {
                              String fullImageUrl = imageUrl.startsWith('http')
                                  ? imageUrl
                                  : "${ApiConstants.baseUrl}$imageUrl";
                              proxiedUrl = _getProxiedImageUrl(fullImageUrl);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: NeoContainer(
                                color: Colors.white,
                                padding: EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                        border: const Border(
                                          bottom: BorderSide(
                                            color: NeoColors.text,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child:
                                          (imageUrl != null &&
                                              imageUrl.isNotEmpty)
                                          ? Image.network(
                                              proxiedUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    debugPrint(
                                                      '❌ Venue image proxy error: $error',
                                                    );
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 50,
                                                          color:
                                                              NeoColors.muted,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: NeoColors.muted,
                                                ),
                                              ),
                                            ),
                                    ),

                                    // Content Section
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  venue['name']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w900,
                                                    color: NeoColors.text,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () =>
                                                    _showDeleteConfirmation(
                                                      venue['id'],
                                                      venue['name'],
                                                    ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    border: Border.all(
                                                      color: NeoColors.text,
                                                      width: 2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                    color: NeoColors.danger,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              border: Border.all(
                                                color: NeoColors.text,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              venue['category'] ??
                                                  'UNCATEGORIZED',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: NeoColors.muted,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: NeoColors.text,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  venue['location'] ?? '-',
                                                  style: const TextStyle(
                                                    color: NeoColors.text,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // Action Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: NeoButton(
                                              label: "MANAGE VENUE",
                                              icon: Icons.settings,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        VenueManagePage(
                                                          venueId: venue['id'],
                                                        ),
                                                  ),
                                                ).then((_) => _refreshVenues());
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 10),
        child: NeoContainer(
          width: 64,
          height: 64,
          color: NeoColors.primary,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VenueFormPage()),
            );
            if (result == true) _refreshVenues();
          },
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
