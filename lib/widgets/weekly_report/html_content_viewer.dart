import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Reusable HTML Content Viewer for Weekly Report
/// Tap card → popup bottom sheet with WebView HTML rendering
class HtmlContentViewer extends StatelessWidget {
  final String title;
  final String htmlContent;
  final Color themeColor;
  final IconData icon;

  const HtmlContentViewer({
    super.key,
    required this.title,
    required this.htmlContent,
    this.themeColor = Colors.teal,
    this.icon = Icons.article_rounded,
  });

  /// Show HTML content in a bottom sheet popup
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String htmlContent,
    Color themeColor = Colors.teal,
    IconData icon = Icons.article_rounded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HtmlContentSheet(
        title: title,
        htmlContent: htmlContent,
        themeColor: themeColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _decodeHtmlEntities(htmlContent);

    return GestureDetector(
      onTap: () => show(
        context: context,
        title: title,
        htmlContent: htmlContent,
        themeColor: themeColor,
        icon: icon,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor.withOpacity(0.05),
              themeColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: themeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.open_in_full_rounded,
                    size: 16,
                    color: themeColor.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Decoded preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  preview.isNotEmpty ? preview : 'No content available',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tap hint
              Center(
                child: Text(
                  'Tap to view full content',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: themeColor.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Strip HTML tags AND decode HTML entities for clean preview text
  static String _decodeHtmlEntities(String html) {
    if (html.isEmpty) return '';

    // 1. Strip HTML tags
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 2. Decode common HTML entities
    const entities = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&ndash;': '–',
      '&mdash;': '—',
      '&lsquo;': ''',
      '&rsquo;': ''',
      '&ldquo;': '\u201C',
      '&rdquo;': '\u201D',
      '&bull;': '•',
      '&hellip;': '…',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
      // Vietnamese diacritics
      '&agrave;': 'à', '&aacute;': 'á', '&atilde;': 'ã', '&acirc;': 'â',
      '&egrave;': 'è', '&eacute;': 'é', '&ecirc;': 'ê',
      '&igrave;': 'ì', '&iacute;': 'í',
      '&ograve;': 'ò', '&oacute;': 'ó', '&otilde;': 'õ', '&ocirc;': 'ô',
      '&ugrave;': 'ù', '&uacute;': 'ú',
      '&Agrave;': 'À', '&Aacute;': 'Á', '&Atilde;': 'Ã', '&Acirc;': 'Â',
      '&Egrave;': 'È', '&Eacute;': 'É', '&Ecirc;': 'Ê',
      '&Igrave;': 'Ì', '&Iacute;': 'Í',
      '&Ograve;': 'Ò', '&Oacute;': 'Ó', '&Otilde;': 'Õ', '&Ocirc;': 'Ô',
      '&Ugrave;': 'Ù', '&Uacute;': 'Ú',
    };

    entities.forEach((entity, char) {
      text = text.replaceAll(entity, char);
    });

    // 3. Decode numeric entities &#xxx;
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });

    // 4. Decode hex entities &#xHHH;
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });

    // 5. Collapse whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }
}

// =============================================================================
// HTML Content Sheet - Bottom sheet with WebView
// =============================================================================

class _HtmlContentSheet extends StatefulWidget {
  final String title;
  final String htmlContent;
  final Color themeColor;
  final IconData icon;

  const _HtmlContentSheet({
    required this.title,
    required this.htmlContent,
    required this.themeColor,
    required this.icon,
  });

  @override
  State<_HtmlContentSheet> createState() => _HtmlContentSheetState();
}

class _HtmlContentSheetState extends State<_HtmlContentSheet> {
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
            if (mounted) setState(() => _isLoading = false);
          },
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

  String _buildFullHtml() {
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
      padding: 16px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
      background-color: #ffffff;
      -webkit-font-smoothing: antialiased;
      line-height: 1.6;
      color: #333;
    }
    img { max-width: 100%; height: auto; border-radius: 8px; margin: 8px 0; }
    p { margin: 8px 0; }
    strong { color: #1a1a1a; font-weight: 600; }
    ul, ol { padding-left: 24px; margin: 8px 0; }
    li { margin: 4px 0; }
    table { width: 100%; border-collapse: collapse; margin: 12px 0; }
    th, td { border: 1px solid #e0e0e0; padding: 8px; text-align: left; }
    th { background-color: #f5f5f5; font-weight: 600; }
  </style>
</head>
<body>
${widget.htmlContent.isEmpty ? '<p style="color: #999; text-align: center; padding: 40px 0;">No content available</p>' : widget.htmlContent}
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    // Limit to 70% screen height so it doesn't cover safe area
    final screenHeight = MediaQuery.of(context).size.height;
    final popupHeight = screenHeight * 0.70;

    return Container(
      height: popupHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            decoration: BoxDecoration(
              color: widget.themeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              bottom: false,
              top: false,
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Swipe down to close',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // WebView content
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
                  Center(
                    child: CircularProgressIndicator(color: widget.themeColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
