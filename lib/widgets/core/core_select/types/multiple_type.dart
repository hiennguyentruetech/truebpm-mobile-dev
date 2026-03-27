import 'package:flutter/material.dart';
import '../components/clear_button.dart';
import '../components/selected_items_display.dart';

/// Build multiple selection type - similar to dropdown but allows multiple selection
class MultipleTypeBuilder extends StatelessWidget {
  final dynamic selectedValue;
  final bool isDisabled;
  final String? hintText;
  final Widget? floatingLabel;
  final String Function(dynamic) getDisplayText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const MultipleTypeBuilder({
    super.key,
    required this.selectedValue,
    required this.isDisabled,
    this.hintText,
    this.floatingLabel,
    required this.getDisplayText,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    const Color disabledValueColor = Color.fromARGB(255, 125, 125, 125);

    // Convert selected values to List if not already
    List<dynamic> selectedValues = [];
    if (selectedValue is List) {
      selectedValues = List.from(selectedValue);
    } else if (selectedValue != null) {
      selectedValues = [selectedValue];
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isDisabled ? Colors.grey.shade50 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 24,
                        maxHeight: 155, // Approximately 5 lines with padding
                      ),
                      child: SingleChildScrollView(
                        child: selectedValues.isNotEmpty
                            ? SelectedItemsDisplay(
                                selectedValues: selectedValues,
                                getDisplayText: getDisplayText,
                                isDisabled: isDisabled,
                              )
                            : Text(
                                !isDisabled ? (hintText ?? 'Select options') : '',
                                style: TextStyle(
                                  color: isDisabled
                                      ? disabledValueColor
                                      : Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Clear icon (X) - show when has selected items and not disabled
                  if (selectedValues.isNotEmpty && !isDisabled && onClear != null) ...[
                    ClearButtonWithAnimation(
                      onTap: onClear!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Multiple selection icon
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.grey.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      color: isDisabled ? Colors.grey.shade400 : Colors.blue.shade600,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (floatingLabel != null) floatingLabel!,
      ],
    );
  }
}
