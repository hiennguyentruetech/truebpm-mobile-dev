import 'package:flutter/material.dart';

class DetailTravelRequestScreen extends StatefulWidget {
  const DetailTravelRequestScreen({super.key});

  @override
  State<DetailTravelRequestScreen> createState() => _DetailTravelRequestScreenState();
}

class _DetailTravelRequestScreenState extends State<DetailTravelRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Yêu cầu đi công tác'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_land,
              size: 80,
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Chi tiết Yêu cầu đi công tác',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Giao diện này sẽ được thiết kế sau',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
