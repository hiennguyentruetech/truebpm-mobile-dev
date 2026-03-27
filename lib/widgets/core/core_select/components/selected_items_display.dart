import 'package:flutter/material.dart';

/// Widget for displaying selected items in multiple selection
class SelectedItemsDisplay extends StatelessWidget {
  final List<dynamic> selectedValues;
  final String Function(dynamic) getDisplayText;
  final bool isDisabled;

  const SelectedItemsDisplay({
    super.key,
    required this.selectedValues,
    required this.getDisplayText,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedValues.isEmpty) return const SizedBox.shrink();
    
    // Calculate max items to show (approximately 3 lines with wrapping)
    const int maxItemsToShow = 4; // Adjust based on typical screen width
    const Color disabledValueColor = Color.fromARGB(255, 125, 125, 125);
    final itemsToShow = selectedValues.take(maxItemsToShow).toList();
    final hasMoreItems = selectedValues.length > maxItemsToShow;
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // Show items up to the limit
        ...itemsToShow.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDisabled ? Colors.grey.shade300 : Colors.blue.shade300),
          ),
          child: Text(
            getDisplayText(item),
            style: TextStyle(
              color: isDisabled ? disabledValueColor : Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        )),
        // Show "+X more" if there are additional items
        if (hasMoreItems)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDisabled ? Colors.grey.shade300 : Colors.orange.shade300),
            ),
            child: Text(
              '+${selectedValues.length - maxItemsToShow} more',
              style: TextStyle(
                color: isDisabled ? disabledValueColor : Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
