import 'package:flutter/material.dart';

class CoachSchedulePage extends StatefulWidget {
  const CoachSchedulePage({super.key});

  @override
  State<CoachSchedulePage> createState() => _CoachSchedulePageState();
}

class _CoachSchedulePageState extends State<CoachSchedulePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Jadwal Saya',
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
