import 'package:flutter/material.dart';

class TaskAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onRefresh;

  const TaskAppBar({
    super.key,
    required this.title,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: onRefresh != null
          ? IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
            )
          : null,
      automaticallyImplyLeading: onRefresh == null, // Show back button only if no refresh button
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
