import 'package:flutter/material.dart';
import 'package:truebpm/utils/core_constants.dart';

class CoreEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CoreEmptyState({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              CoreConstants.noDataTitle,
              style: TextStyle(
                fontSize: 18, 
                color: Colors.grey.shade600, 
                fontWeight: FontWeight.w500
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CoreConstants.noDataSubtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    CoreConstants.refreshHint,
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh!(),
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: content,
        ),
      );
    }

    return content;
  }
}
