import 'package:flutter/material.dart';

class DetailELeaveScreen extends StatefulWidget {
  const DetailELeaveScreen({super.key});

  @override
  State<DetailELeaveScreen> createState() => _DetailELeaveScreenState();
}

class _DetailELeaveScreenState extends State<DetailELeaveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Đơn xin nghỉ'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Chi tiết Đơn xin nghỉ',
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
