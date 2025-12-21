import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '/models/coach_list_models.dart';
import '/constants/api.dart';

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

class CoachDetailPage extends StatefulWidget {
  final int coachId;

  const CoachDetailPage({Key? key, required this.coachId}) : super(key: key);

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage> {
  bool _isLoading = true;
  CoachDetail? _coach;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCoachDetail();
  }

  Future<void> _fetchCoachDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(
        ApiConstants.coachDetail(widget.coachId),
      );

      if (response['success'] == true) {
        final detailResponse = CoachDetailResponse.fromJson(response);
        setState(() {
          _coach = detailResponse.coach;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat detail coach';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutalism.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeoBrutalism.primary),
              ),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : _coach == null
          ? const Center(child: Text('Data tidak tersedia'))
          : _buildContent(),
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
              onPressed: _fetchCoachDetail,
              label: 'COBA LAGI',
              icon: Icons.refresh,
            ),
            const SizedBox(height: 12),
            _buildNeoButton(
              onPressed: () => Navigator.pop(context),
              label: 'KEMBALI',
              icon: Icons.arrow_back,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildCustomAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoachHeader(),
              const SizedBox(height: 16),
              _buildQuickInfo(),
              const SizedBox(height: 16),
              _buildExperienceSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: NeoBrutalism.white,
      iconTheme: const IconThemeData(color: NeoBrutalism.slate),
      leading: Container(
        margin: const EdgeInsets.all(8),
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
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoBrutalism.slate),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _coach!.profilePicture != null
                ? Image.network(
                    _coach!.profilePicture!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: NeoBrutalism.slate,
                    width: NeoBrutalism.borderWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: NeoBrutalism.grey,
      child: const Center(
        child: Icon(Icons.person, size: 120, color: NeoBrutalism.white),
      ),
    );
  }

  Widget _buildCoachHeader() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ), 
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
          mainAxisSize: MainAxisSize
              .min, 
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _coach!.user.fullName.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.slate,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_coach!.mainSportTrained != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min, 
                  children: [
                    const Icon(
                      Icons.sports_basketball,
                      size: 16,
                      color: NeoBrutalism.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _coach!.mainSportTrained!.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.white,
                        letterSpacing: 0.5,
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

  Widget _buildQuickInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          _buildQuickInfoRow(
            icon: Icons.person_outline,
            label: 'UMUR',
            value: '${_coach!.age ?? '-'} tahun',
          ),
          _buildDivider(),
          _buildQuickInfoRow(
            icon: Icons.attach_money,
            label: 'RATE PER JAM',
            value: _coach!.formattedRate,
            isHighlight: true,
          ),
          _buildDivider(),
          _buildQuickInfoRow(
            icon: Icons.location_on_outlined,
            label: 'AREA LAYANAN',
            value: _coach!.serviceAreasText,
            isMultiline: true,
          ),
        ],
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

  Widget _buildQuickInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NeoBrutalism.white,
            borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
            border: Border.all(
              color: NeoBrutalism.slate,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          child: Icon(icon, size: 20, color: NeoBrutalism.slate),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: NeoBrutalism.grey,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: isHighlight
                      ? NeoBrutalism.primary
                      : NeoBrutalism.slate,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    if (_coach!.experienceDesc.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeoBrutalism.white,
                  borderRadius: BorderRadius.circular(
                    NeoBrutalism.borderRadius,
                  ),
                  border: Border.all(
                    color: NeoBrutalism.slate,
                    width: NeoBrutalism.borderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.history_edu,
                  color: NeoBrutalism.slate,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PENGALAMAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.slate,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _coach!.experienceDesc,
            style: const TextStyle(
              fontSize: 14,
              color: NeoBrutalism.slate,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
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
      width: double.infinity,
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
