import 'package:flutter/material.dart';
import 'package:truebpm/widgets/dialogs/app_themed_dialog.dart';

/// Model for print report options with dynamic URL support
class PrintReportOption {
  final String reportName;
  final String reportUrl;
  final String? reportDescription;
  final IconData? reportIcon;
  final Map<String, String>? urlParams; // Dynamic parameters to replace in URL

  const PrintReportOption({
    required this.reportName,
    required this.reportUrl,
    this.reportDescription,
    this.reportIcon,
    this.urlParams,
  });

  /// Generate final URL by replacing placeholders with actual values
  String generateUrl(Map<String, dynamic> itemDetail) {
    String finalUrl = reportUrl;
    
    if (urlParams != null) {
      for (final entry in urlParams!.entries) {
        final placeholder = '{${entry.key}}';
        final value = _getValueFromPath(itemDetail, entry.value);
        finalUrl = finalUrl.replaceAll(placeholder, value);
      }
    }
    
    return finalUrl;
  }

  /// Get value from nested path in itemDetail (e.g., "value.id", "value.code")
  String _getValueFromPath(Map<String, dynamic> itemDetail, String path) {
    final keys = path.split('.');
    dynamic current = itemDetail;
    
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }
    
    return current?.toString() ?? '';
  }
}

/// Response dialog for API actions
class CoreActionDialog {
  /// Show response dialog based on API response
  static void showResponseDialog(
    BuildContext context, {
    required Map<String, dynamic> response,
    String? title,
    VoidCallback? onSuccess,
  }) {
    final success = response['success'] == true;
    final messageType = response['messageType']?.toString().toLowerCase() ?? '';
    final message = response['message']?.toString() ?? 
                   (success ? 'Operation completed successfully' : 'Operation failed');
    
    // Determine colors and icon based on messageType
    switch (messageType) {
      case 'success':
        break;
      case 'error':
        break;
      case 'warning':
        break;
      default:
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AppThemedDialog(
        title: title ?? (success ? 'Success' : 'Error'),
        message: message,
        type: switch (messageType) {
          'success' => AppDialogType.success,
          'warning' => AppDialogType.warning,
          'error' => AppDialogType.error,
          _ => success ? AppDialogType.success : AppDialogType.info,
        },
        confirmText: 'OK',
        onConfirm: () {
          Navigator.of(context).pop();
          if (success && onSuccess != null) {
            onSuccess();
          }
        },
      ),
    );
  }

  /// Show print report selection dialog
  static void showPrintDialog(
    BuildContext context, {
    required List<PrintReportOption> reports,
    required Function(String url) onReportSelected,
    Map<String, dynamic>? itemDetail,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _PrintDialog(
        reports: reports,
        primaryColor: primaryColor,
        onReportSelected: onReportSelected,
        itemDetail: itemDetail,
      ),
    );
  }
}

/// Custom response dialog widget
class _ResponseDialog extends StatefulWidget {
  final String title;
  final String message;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData icon;
  final bool isSuccess;
  final VoidCallback onConfirm;

  const _ResponseDialog({
    required this.title,
    required this.message,
    required this.primaryColor,
    required this.backgroundColor,
    required this.icon,
    required this.isSuccess,
    required this.onConfirm,
  });

  @override
  State<_ResponseDialog> createState() => _ResponseDialogState();
}

class _ResponseDialogState extends State<_ResponseDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.backgroundColor,
                            widget.backgroundColor.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Icon with animation
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: widget.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      },
    );
  }
}

/// Custom print dialog widget
class _PrintDialog extends StatelessWidget {
  final List<PrintReportOption> reports;
  final Color primaryColor;
  final Function(String url) onReportSelected;
  final Map<String, dynamic>? itemDetail;

  const _PrintDialog({
    required this.reports,
    required this.primaryColor,
    required this.onReportSelected,
    this.itemDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 450,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Beautiful header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Animated icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.assessment_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Print Reports',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select a report to generate and print',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button with hover effect
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Report list with enhanced design
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reports.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(context, report, index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, PrintReportOption report, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            final finalUrl = report.generateUrl(itemDetail ?? {});
            onReportSelected(finalUrl);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    report.reportIcon ?? Icons.assessment_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // Report details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (report.reportDescription != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          report.reportDescription!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow icon with animation
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: primaryColor,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
