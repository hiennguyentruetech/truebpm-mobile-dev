/// Model cho một notification item từ API
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String notificationType;
  final String? targetUrl;
  final String? imageUrl;
  final bool isRead;
  final String? readAt;
  final DateTime createdDate;
  final String? notificationConfigId;
  final bool? isShowTemplate;
  final String? notificationTemplate;
  final String? recordId;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.notificationType,
    this.targetUrl,
    this.imageUrl,
    required this.isRead,
    this.readAt,
    required this.createdDate,
    this.notificationConfigId,
    this.isShowTemplate,
    this.notificationTemplate,
    this.recordId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      notificationType: json['notificationType'] ?? '',
      targetUrl: json['targetUrl'],
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
      createdDate: DateTime.tryParse(json['createdDate'] ?? '') ?? DateTime.now(),
      notificationConfigId: json['notificationConfigId'],
      isShowTemplate: json['isShowTemplate'],
      notificationTemplate: json['notificationTemplate'],
      recordId: json['recordId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'notificationType': notificationType,
      'targetUrl': targetUrl,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'readAt': readAt,
      'createdDate': createdDate.toIso8601String(),
      'notificationConfigId': notificationConfigId,
      'isShowTemplate': isShowTemplate,
      'notificationTemplate': notificationTemplate,
      'recordId': recordId,
    };
  }

  /// Check if this is a STATUS_CHANGE notification
  bool get isStatusChange => notificationType == 'STATUS_CHANGE';

  /// Check if this is an INFORMATION notification
  bool get isInformation => notificationType == 'INFORMATION';

  /// Check if this notification has an HTML template
  bool get hasTemplate =>
      notificationTemplate != null && notificationTemplate!.isNotEmpty;

  /// Check if targetUrl points to task-list module
  bool get isTaskListTarget =>
      targetUrl != null && targetUrl!.contains('task-list');

  /// Parse module page name from targetUrl
  /// e.g. "https://truebpm.truetech.com.vn/bonita/apps/SolomonApp/e-leave-page?code=ELEAVE-10125"
  /// → "e-leave-page"
  String? get targetModulePage {
    if (targetUrl == null || targetUrl!.isEmpty) return null;
    try {
      final uri = Uri.parse(targetUrl!);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last; // e.g. "e-leave-page" or "quotation-page"
      }
    } catch (_) {}
    return null;
  }

  /// Parse the record code from targetUrl
  /// e.g. "?code=ELEAVE-10125" → "ELEAVE-10125"
  String? get targetRecordCode {
    if (targetUrl == null || targetUrl!.isEmpty) return null;
    try {
      final uri = Uri.parse(targetUrl!);
      return uri.queryParameters['code'];
    } catch (_) {}
    return null;
  }

  /// Map module page name to core module code used in the app
  String? get targetModuleCode {
    final page = targetModulePage;
    if (page == null) return null;

    // Map URL page names → module codes
    const pageToModuleCode = {
      'e-leave-page': 'ELEAVE',
      'quotation-page': 'QUTATI',
      'ot-registration-page': 'OVTIME',
      'car-booking-page': 'CARBKG',
      'travel-request-page': 'TRAREQ',
      'travel-claim-page': 'TRACLA',
      'product-page': 'PRD',
      'customer-page': 'CTM',
      'weekly-report-page': 'WKLRPT',
      'opportunities-page': 'OPP',
      'project-management-page': 'PRJMGT',
    };

    // Nếu page nằm trong map → trả về module code
    if (pageToModuleCode.containsKey(page)) {
      return pageToModuleCode[page];
    }

    // Trường hợp task-list: extract module code từ query param 'code'
    // e.g. "task-list?code=ELEAVE-10133" → "ELEAVE"
    if (page == 'task-list') {
      final code = targetRecordCode; // e.g. "ELEAVE-10133"
      if (code != null && code.contains('-')) {
        return code.split('-').first; // "ELEAVE"
      }
    }

    return null;
  }

  /// Get relative time string from createdDate
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdDate);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Get notification type label for display
  String get typeLabel {
    switch (notificationType) {
      case 'STATUS_CHANGE':
        return 'PROCESS';
      case 'INFORMATION':
        return 'INFORMATION';
      default:
        return notificationType;
    }
  }
}
