import 'package:flutter/material.dart';
import 'package:truebpm/styles/app_colors.dart';

/// Widget hiển thị khi danh sách notification rỗng
class NotificationEmptyState extends StatelessWidget {
  final bool isUnreadTab;
  final VoidCallback? onRefresh;

  const NotificationEmptyState({
    super.key,
    this.isUnreadTab = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
              child: Icon(
                isUnreadTab
                    ? Icons.done_all_rounded
                    : Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isUnreadTab
                  ? 'All caught up!'
                  : 'No notifications yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isUnreadTab
                  ? 'You have read all your notifications.'
                  : 'When you receive notifications,\nthey will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),

            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
