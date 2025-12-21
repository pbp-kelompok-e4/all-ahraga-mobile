import 'package:intl/intl.dart';

class CoachRevenueResponse {
  final bool success;
  final bool hasProfile;
  final double totalRevenue;
  final List<TransactionItem> transactions;
  final int transactionsCount;
  final String? message;

  CoachRevenueResponse({
    required this.success,
    required this.hasProfile,
    required this.totalRevenue,
    required this.transactions,
    required this.transactionsCount,
    this.message,
  });

  factory CoachRevenueResponse.fromJson(Map<String, dynamic> json) {
    return CoachRevenueResponse(
      success: json['success'] ?? false,
      hasProfile: json['has_profile'] ?? false,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
                .map((item) => TransactionItem.fromJson(item))
                .toList()
          : [],
      transactionsCount: json['transactions_count'] ?? 0,
      message: json['message'],
    );
  }
}

class TransactionItem {
  final int id;
  final String paymentMethod;
  final String status;
  final double revenueCoach;
  final DateTime transactionTime;

  TransactionItem({
    required this.id,
    required this.paymentMethod,
    required this.status,
    required this.revenueCoach,
    required this.transactionTime,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    String datetimeStr = json['transaction_time'];

    String isoFormat = datetimeStr.replaceFirst(' ', 'T');

    DateTime utcTime = DateTime.parse(isoFormat + 'Z');

    // Konversi ke WIB (UTC + 7 jam)
    DateTime wibTime = utcTime.add(const Duration(hours: 7));

    return TransactionItem(
      id: json['id'] ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      revenueCoach: (json['revenue_coach'] ?? 0).toDouble(),
      transactionTime: wibTime,
    );
  }

  // Helper method untuk format rupiah
  String get formattedRevenue {
    return 'Rp ${revenueCoach.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Helper method untuk format tanggal
  String get formattedDate {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transactionTime);
  }

  // Helper method untuk status display
  String get statusDisplay {
    switch (status) {
      case 'CONFIRMED':
        return 'Berhasil';
      case 'PENDING':
        return 'Menunggu';
      case 'FAILED':
        return 'Gagal';
      default:
        return status;
    }
  }
}
