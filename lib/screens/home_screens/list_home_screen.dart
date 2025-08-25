import 'package:flutter/material.dart';
import 'package:truebpm/navigation/app_routes.dart';

class ListHomeScreen extends StatefulWidget {
  const ListHomeScreen({super.key});

  @override
  State<ListHomeScreen> createState() => _ListHomeScreenState();
}

class _ListHomeScreenState extends State<ListHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Danh sách Trang chủ',
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
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.detailHome);
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
