import 'package:flutter/material.dart';

class CoachListPage extends StatefulWidget {
  const CoachListPage({super.key});

  @override
  State<CoachListPage> createState() => _CoachListPageState();
}

class _CoachListPageState extends State<CoachListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Daftar Coach',
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
