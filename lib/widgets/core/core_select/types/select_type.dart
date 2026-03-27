import 'package:flutter/material.dart';
import '../components/clear_button.dart';

/// Build select type dropdown with floating label
class SelectTypeBuilder extends StatelessWidget {
  final dynamic selectedValue;
  final List<dynamic> filteredOptions;
  final bool isDisabled;
  final String? hintText;
  final Widget? floatingLabel;
  final String Function(dynamic) getDisplayText;
  final dynamic Function(dynamic) getOptionValue;
  final Function(dynamic) onChanged;
  final Future<void> Function() loadOptionsFromAPI;

  const SelectTypeBuilder({
    super.key,
    required this.selectedValue,
    required this.filteredOptions,
    required this.isDisabled,
    this.hintText,
    this.floatingLabel,
    required this.getDisplayText,
    required this.getOptionValue,
    required this.onChanged,
    required this.loadOptionsFromAPI,
  });

  @override
  Widget build(BuildContext context) {
    const Color disabledValueColor = Color.fromARGB(255, 125, 125, 125);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DropdownButtonFormField<dynamic>(
              value: selectedValue,
              isDense: true,
              hint: Text(
                hintText ?? 'Select an option',
                style: TextStyle(
                  color: isDisabled ? disabledValueColor : Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: isDisabled ? Colors.grey.shade50 : Colors.white,
                // Custom suffix with clear button and dropdown arrow
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clear icon (X) or invisible placeholder to maintain consistent positioning
                    selectedValue != null && !isDisabled
                        ? ClearButtonWithAnimation(
                            onTap: () {
                              onChanged(null);
                            },
                          )
                        : const SizedBox(width: 28), // Invisible placeholder with same width as clear button
                    const SizedBox(width: 8),
                    // Dropdown arrow icon (always show)
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
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              dropdownColor: Colors.white,
              elevation: 8,
              icon: const SizedBox.shrink(),
              items: filteredOptions.map<DropdownMenuItem<dynamic>>((option) {
                return DropdownMenuItem<dynamic>(
                  value: getOptionValue(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      getDisplayText(option),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDisabled ? disabledValueColor : Colors.grey.shade800,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: isDisabled ? null : onChanged,
              onTap: () async {
                await loadOptionsFromAPI();
              },
            ),
          ),
        ),
        if (floatingLabel != null) floatingLabel!,
      ],
    );
  }
}
