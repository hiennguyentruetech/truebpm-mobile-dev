import 'package:flutter/material.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/styles/app_colors.dart';

/// Widget card hiển thị một notification item
class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: notification.isRead
            ? Colors.white
            : AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: notification.isRead
                    ? Colors.grey.shade200
                    : AppColors.primary.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Icon
                _buildAvatar(),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with type badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            _buildUnreadDot(),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Content preview
                      Text(
                        notification.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Bottom row: type badge + time
                      Row(
                        children: [
                          _buildTypeBadge(),
                          const Spacer(),
                          _buildTimeLabel(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final isInfo = notification.isInformation;
    final hasImage = notification.imageUrl != null &&
        notification.imageUrl!.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isInfo
                    ? [
                        AppColors.info.withOpacity(0.15),
                        AppColors.info.withOpacity(0.08),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.08),
                      ],
              ),
        color: hasImage ? Colors.white : null,
        border: Border.all(
          color: hasImage
              ? Colors.grey.shade200
              : isInfo
                  ? AppColors.info.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: hasImage
          ? ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.network(
                  notification.imageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    isInfo
                        ? Icons.campaign_rounded
                        : Icons.swap_horiz_rounded,
                    color: isInfo ? AppColors.info : AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            )
          : Icon(
              isInfo
                  ? Icons.campaign_rounded
                  : Icons.swap_horiz_rounded,
              color: isInfo ? AppColors.info : AppColors.primary,
              size: 22,
            ),
    );
  }

  Widget _buildUnreadDot() {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isInfo = notification.isInformation;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isInfo
            ? AppColors.info.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        border: Border.all(
          color: isInfo
              ? AppColors.info.withOpacity(0.25)
              : Colors.blue.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        notification.typeLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: isInfo ? AppColors.info : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTimeLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 13,
          color: Colors.grey.shade400,
        ),
        const SizedBox(width: 3),
        Text(
          notification.timeAgo,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
