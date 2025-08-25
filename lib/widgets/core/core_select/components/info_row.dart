import 'package:flutter/material.dart';

/// Widget for info row similar to _CoreInfoRow in core_list_item_card
class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;

  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.7),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label - 35% width, align right
            Expanded(
              flex: 35,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Colon separator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
            // Value - 65% width, align left
            Expanded(
              flex: 65,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
