import 'package:flutter/material.dart';
import 'package:truebpm/navigation/app_routes.dart';

class ListELeaveScreen extends StatefulWidget {
  const ListELeaveScreen({super.key});

  @override
  State<ListELeaveScreen> createState() => _ListELeaveScreenState();
}

class _ListELeaveScreenState extends State<ListELeaveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn xin nghỉ'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Danh sách Đơn xin nghỉ',
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
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.detailELeave);
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
