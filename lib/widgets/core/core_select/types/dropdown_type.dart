import 'package:flutter/material.dart';
import '../components/clear_button.dart';

/// Build dropdown type - simple button that opens popup
class DropdownTypeBuilder extends StatelessWidget {
  final dynamic selectedValue;
  final bool isDisabled;
  final String? hintText;
  final Widget? floatingLabel;
  final String Function(dynamic) getDisplayText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const DropdownTypeBuilder({
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
                    child: Builder(
                      builder: (context) {
                        // Get display text for selected value
                        final displayText = selectedValue != null ? getDisplayText(selectedValue) : '';
                        final hasValidDisplayText = displayText.isNotEmpty;
                        
                        return Text(
                          hasValidDisplayText
                              ? displayText
                              : (!isDisabled ? (hintText ?? 'Select an option') : ''),
                          style: TextStyle(
                            color: isDisabled
                                ? Colors.grey.shade400
                                : (hasValidDisplayText ? Colors.grey.shade800 : Colors.grey.shade500),
                            fontSize: 14,
                            fontWeight: hasValidDisplayText ? FontWeight.w500 : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Clear icon (X) - show when has valid display text and not disabled
                  Builder(
                    builder: (context) {
                      final displayText = selectedValue != null ? getDisplayText(selectedValue) : '';
                      final hasValidDisplayText = displayText.isNotEmpty;
                      
                      if (hasValidDisplayText && !isDisabled && onClear != null) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClearButtonWithAnimation(
                              onTap: onClear!,
                            ),
                            const SizedBox(width: 8),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Dropdown arrow icon
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.grey.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
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
