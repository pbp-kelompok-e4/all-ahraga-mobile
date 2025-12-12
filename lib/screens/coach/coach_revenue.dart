import 'package:flutter/material.dart';

class CoachRevenuePage extends StatefulWidget {
  const CoachRevenuePage({super.key});

  @override
  State<CoachRevenuePage> createState() => _CoachRevenuePageState();
}

class _CoachRevenuePageState extends State<CoachRevenuePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Laporan Pendapatan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini akan segera diimplementasikan',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
