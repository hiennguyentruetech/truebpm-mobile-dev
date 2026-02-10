import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:truebpm/models/notification_item.dart';
import 'package:truebpm/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// Hiển thị popup cho notification dạng INFORMATION
class NotificationPopup {
  /// Show popup cho notification INFORMATION không có template
  /// Hiển thị content thuần (plain text)
  static Future<void> showInfoPopup(
    BuildContext context,
    NotificationItem notification,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _InfoContentSheet(notification: notification),
    );
  }

  /// Show popup cho notification INFORMATION có HTML template
  static Future<void> showTemplatePopup(
    BuildContext context,
    NotificationItem notification,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _TemplateContentSheet(notification: notification),
    );
  }
}

// =============================================================================
// INFO CONTENT SHEET (plain text, no template) — Gradient header style
// =============================================================================

class _InfoContentSheet extends StatelessWidget {
  final NotificationItem notification;
  const _InfoContentSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient header
          _buildGradientHeader(context),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + Type badge + Time
                  _buildMetaRow(),

                  const SizedBox(height: 16),

                  // Content text
                  Text(
                    notification.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Notification Detail',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final dateFormat = DateFormat('HH:mm dd/MM/yyyy');
    final formattedDate = dateFormat.format(notification.createdDate);

    return Row(
      children: [
        // App logo placeholder
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(
            Icons.business_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),

        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.info.withOpacity(0.1),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'INFORMATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.info,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Date/time
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TEMPLATE CONTENT SHEET (WebView HTML viewer - render đúng CSS)
// Full-screen flex, chỉ nút X, không header title
// =============================================================================

class _TemplateContentSheet extends StatefulWidget {
  final NotificationItem notification;
  const _TemplateContentSheet({required this.notification});

  @override
  State<_TemplateContentSheet> createState() => _TemplateContentSheetState();
}

class _TemplateContentSheetState extends State<_TemplateContentSheet> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          // Chặn navigation ra ngoài - chỉ render nội dung
          onNavigationRequest: (request) {
            if (request.url.startsWith('data:') ||
                request.url == 'about:blank') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_buildFullHtml());
  }

  /// Wrap notificationTemplate trong một full HTML document
  /// để browser render đúng CSS (gradients, shadows, etc.)
  String _buildFullHtml() {
    final template = widget.notification.notificationTemplate ?? '';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; -webkit-text-size-adjust: 100%; }
    html, body {
      margin: 0;
      padding: 8px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
      background-color: transparent;
      -webkit-font-smoothing: antialiased;
    }
    img { max-width: 100%; height: auto; }
  </style>
</head>
<body>
$template
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Popup né hoàn toàn SafeArea trên + AppBar + TabBar + bottom nav
    final popupHeight = screenHeight - topPadding - kToolbarHeight - 80 - bottomPadding;

    return Container(
      height: popupHeight,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header bar với drag handle + nút X
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Drag handle
                Expanded(
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // X close button — dùng GestureDetector để không bị WebView chặn
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // WebView HTML Content
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(
                  controller: _webViewController,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
