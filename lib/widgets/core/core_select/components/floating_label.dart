import 'package:flutter/material.dart';

/// Widget for floating label
class FloatingLabel extends StatelessWidget {
  final String labelText;
  final bool isRequired;
  final bool isDisabled;

  const FloatingLabel({
    super.key,
    required this.labelText,
    this.isRequired = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (labelText.isEmpty) return const SizedBox.shrink();

    // Match CoreInput floatingLabelStyle when blurred
    final Color labelColor = isDisabled
        ? const Color.fromARGB(255, 145, 145, 145)
        : const Color(0xFF5B5B5B); // #5B5B5B giống CoreInput khi blur

    return Positioned(
      left: 8,
      top: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: RichText(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
            children: isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
