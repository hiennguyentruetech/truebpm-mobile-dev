import 'package:flutter/material.dart';
import 'package:truebpm/navigation/app_routes.dart';

class ListTravelRequestScreen extends StatefulWidget {
  const ListTravelRequestScreen({super.key});

  @override
  State<ListTravelRequestScreen> createState() => _ListTravelRequestScreenState();
}

class _ListTravelRequestScreenState extends State<ListTravelRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu đi công tác'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 80,
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Danh sách Yêu cầu đi công tác',
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.detailTravelRequest);
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
