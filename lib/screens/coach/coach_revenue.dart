import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '/models/coach_revenue_model.dart';
import 'package:all_ahraga/screens/coach/coach_profile.dart';

// Design System Constants
class NeoBrutalism {
  static const Color primary = Color(0xFF0D9488);
  static const Color slate = Color(0xFF0F172A);
  static const Color grey = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
  static const Color white = Colors.white;
  static const Color success = Color(0xFF16a34a);
  static const Color warning = Color(0xFFf59e0b);
  
  static const double borderWidth = 2.0;
  static const double borderRadius = 8.0;
  static const Offset shadowOffset = Offset(4, 4);
}

class CoachRevenuePage extends StatefulWidget {
  const CoachRevenuePage({Key? key}) : super(key: key);

  @override
  State<CoachRevenuePage> createState() => _CoachRevenuePageState();
}

class _CoachRevenuePageState extends State<CoachRevenuePage> {
  bool _isLoading = true;
  CoachRevenueResponse? _revenueData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  Future<void> _fetchRevenueData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await request.get('http://localhost:8000/api/coach/revenue/');

      if (response['success'] == true) {
        setState(() {
          _revenueData = CoachRevenueResponse.fromJson(response);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat data';
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Widget _buildPaymentMethodIcon(String method) {
    IconData icon;
    Color color;

    if (method.contains('Credit') || method.contains('Card')) {
      icon = Icons.credit_card;
      color = NeoBrutalism.primary;
    } else if (method.contains('Transfer')) {
      icon = Icons.account_balance;
      color = NeoBrutalism.success;
    } else {
      icon = Icons.wallet;
      color = NeoBrutalism.warning;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String displayText;

    switch (status) {
      case 'CONFIRMED':
        bgColor = NeoBrutalism.success;
        textColor = NeoBrutalism.white;
        icon = Icons.check_circle;
        displayText = 'BERHASIL';
        break;
      case 'PENDING':
        bgColor = NeoBrutalism.warning;
        textColor = NeoBrutalism.white;
        icon = Icons.access_time;
        displayText = 'MENUNGGU';
        break;
      default:
        bgColor = NeoBrutalism.danger;
        textColor = NeoBrutalism.white;
        icon = Icons.cancel;
        displayText = 'GAGAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                shape: BoxShape.circle,
                border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                size: 60,
                color: NeoBrutalism.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PROFIL BELUM LENGKAP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.slate,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Anda perlu melengkapi profil pelatih untuk melihat laporan pendapatan dan mulai menerima klien.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NeoBrutalism.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildNeoButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CoachProfilePage()),
                );
              },
              label: 'KELOLA PROFIL',
              icon: Icons.edit,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                border: Border.all(color: NeoBrutalism.warning, width: NeoBrutalism.borderWidth),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb, size: 18, color: NeoBrutalism.warning),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Setelah profil lengkap, laporan pendapatan akan muncul di sini.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NeoBrutalism.slate,
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

  Widget _buildRevenueHeader(CoachRevenueResponse data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeoBrutalism.primary,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PENDAPATAN',
                  style: TextStyle(
                    color: NeoBrutalism.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(data.totalRevenue),
                  style: const TextStyle(
                    color: NeoBrutalism.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dari ${data.transactionsCount} transaksi',
                  style: const TextStyle(
                    color: NeoBrutalism.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeoBrutalism.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
              border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 40,
              color: NeoBrutalism.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(CoachRevenueResponse data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
            'RINGKASAN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.slate,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            icon: Icons.check_circle,
            iconColor: NeoBrutalism.success,
            label: 'TRANSAKSI BERHASIL',
            value: '${data.transactionsCount}',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.account_balance_wallet,
            iconColor: NeoBrutalism.primary,
            label: 'TOTAL PENDAPATAN',
            value: _formatCurrency(data.totalRevenue),
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.calendar_today,
            iconColor: NeoBrutalism.warning,
            label: 'PERIODE',
            value: 'Semua Waktu',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoBrutalism.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
        border: Border(left: BorderSide(color: iconColor, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NeoBrutalism.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
              border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: NeoBrutalism.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(48),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NeoBrutalism.white,
                shape: BoxShape.circle,
                border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: NeoBrutalism.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BELUM ADA TRANSAKSI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.slate,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transaksi akan muncul di sini.',
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

    return Container(
      margin: const EdgeInsets.all(16),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.white,
                    borderRadius: BorderRadius.circular(NeoBrutalism.borderRadius),
                    border: Border.all(color: NeoBrutalism.slate, width: NeoBrutalism.borderWidth),
                  ),
                  child: const Icon(Icons.receipt, color: NeoBrutalism.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'RIWAYAT TRANSAKSI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.slate,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: NeoBrutalism.borderWidth,
            color: NeoBrutalism.slate,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Container(
              height: NeoBrutalism.borderWidth,
              color: NeoBrutalism.slate,
            ),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionItem transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: NeoBrutalism.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${transaction.id}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: NeoBrutalism.slate,
                ),
              ),
              _buildStatusBadge(transaction.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPaymentMethodIcon(transaction.paymentMethod),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  transaction.paymentMethod,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NeoBrutalism.slate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction.formattedDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalism.grey,
                ),
              ),
              Text(
                transaction.formattedRevenue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeoButton({
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
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoBrutalism.primary,
          foregroundColor: NeoBrutalism.white,
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
                      : _revenueData == null
                          ? const Center(child: Text('Tidak ada data'))
                          : !_revenueData!.hasProfile
                              ? _buildNoProfileView()
                              : RefreshIndicator(
                                  onRefresh: _fetchRevenueData,
                                  color: NeoBrutalism.primary,
                                  child: ListView(
                                    children: [
                                      _buildRevenueHeader(_revenueData!),
                                      _buildTransactionsList(_revenueData!.transactions),
                                      if (_revenueData!.transactions.isNotEmpty)
                                        _buildSummaryCards(_revenueData!),
                                      const SizedBox(height: 24),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                    "COACH REVENUE",
                    style: TextStyle(
                      color: NeoBrutalism.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "LAPORAN PENDAPATAN",
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
          GestureDetector(
            onTap: _fetchRevenueData,
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
              child: const Icon(Icons.refresh, color: NeoBrutalism.slate, size: 20),
            ),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 64, color: NeoBrutalism.danger),
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
              onPressed: _fetchRevenueData,
              label: 'COBA LAGI',
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}