import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:all_ahraga/constants/api.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:all_ahraga/widgets/error_retry_widget.dart';

const Color _kBg = Colors.white;
const Color _kSlate = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kRed = Color(0xFFDC2626);
const Color _kLightGrey = Color(0xFFF1F5F9);
const double _kRadius = 8.0;
const double _kBorderWidth = 2.0;

class CustomerPaymentPage extends StatefulWidget {
  final int bookingId;
  final String paymentMethod;
  final String totalPrice;

  const CustomerPaymentPage({
    super.key,
    required this.bookingId,
    required this.paymentMethod,
    required this.totalPrice,
  });

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  bool _isProcessing = false;
  String? _errorMessage;

  String formatCurrency(String value) {
    try {
      final double amount = double.parse(value);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (e) {
      return "Rp $value";
    }
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final request = context.read<CookieRequest>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    try {
      final response = await request.postJson(
        ApiConstants.confirmPayment(widget.bookingId),
        jsonEncode({}),
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (response['success'] == true) {
        _showSuccessDialog(response['message'] ?? 'Pembayaran berhasil!', primaryColor);
      } else {
        setState(() => _errorMessage = response['message'] ?? 'Gagal konfirmasi pembayaran');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = "Gangguan koneksi. Coba lagi.";
      });
    }
  }

  void _showSuccessDialog(String message, Color primaryColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _kSlate, width: 2),
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade600, width: 3),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PEMBAYARAN BERHASIL!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _kSlate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_kRadius),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kRadius),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: const Text(
                      'KEMBALI',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrutalBox({
    required Widget child,
    Color bgColor = Colors.white,
    Color borderColor = _kSlate,
    double shadowOffset = 4.0,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: borderColor, width: _kBorderWidth),
        boxShadow: [
          BoxShadow(
            color: _kSlate,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kSlate, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: _kSlate, width: _kBorderWidth),
                  boxShadow: const [
                    BoxShadow(color: _kSlate, offset: Offset(2, 2), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: _kSlate, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PAYMENT AREA",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'BOOKING #${widget.bookingId}',
                    style: const TextStyle(
                      color: _kSlate,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isCash = widget.paymentMethod.toUpperCase() == 'CASH';

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(primaryColor),
          Expanded(
            child: _errorMessage != null
                ? ErrorRetryWidget(
                    message: _errorMessage!,
                    onRetry: _confirmPayment,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildPaymentCard(primaryColor, isCash),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Color primaryColor, bool isCash) {
    return _buildBrutalBox(
      shadowOffset: 6,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon Header
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCash ? Colors.green.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCash ? Colors.green.shade600 : Colors.blue.shade600,
                  width: 3,
                ),
              ),
              child: Icon(
                isCash ? Icons.money : Icons.account_balance,
                size: 48,
                color: isCash ? Colors.green.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Method Title
          Text(
            isCash ? 'BAYAR DI TEMPAT' : 'TRANSFER BANK',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _kSlate,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Payment Details Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kLightGrey,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: _kSlate, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RINCIAN PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _kSlate,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kMuted,
                      ),
                    ),
                    Text(
                      formatCurrency(widget.totalPrice),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'METODE:',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isCash ? 'CASH' : 'TRANSFER',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _kSlate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCash ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: isCash ? Colors.green.shade600 : Colors.blue.shade600,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isCash ? Colors.green.shade700 : Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isCash
                        ? 'Booking berhasil! Bayar saat tiba di venue.'
                        : 'Lakukan transfer lalu tekan "SUDAH BAYAR".',
                    style: TextStyle(
                      color: isCash ? Colors.green.shade900 : Colors.blue.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          if (isCash) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadius),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadius),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: const Text(
                  'LIHAT DETAIL BOOKING',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadius),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing ? _kMuted : primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadius),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SUDAH BAYAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadius),
                boxShadow: const [
                  BoxShadow(
                    color: _kSlate,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kSlate,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: _kSlate, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadius),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'KEMBALI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}