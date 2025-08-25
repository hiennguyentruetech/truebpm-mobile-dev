import 'package:flutter/material.dart';

class TabFormField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final bool required;
  final String? hintText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool isDropdown;
  final List<String>? dropdownItems;

  const TabFormField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.required = false,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.isDropdown = false,
    this.dropdownItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red.shade600),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Input Field
        if (isDropdown && dropdownItems != null)
          DropdownButtonFormField<String>(
            value: dropdownItems!.contains(value) ? value : null,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: dropdownItems!.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && onChanged != null) {
                onChanged!(newValue);
              }
            },
          )
        else
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }
}
