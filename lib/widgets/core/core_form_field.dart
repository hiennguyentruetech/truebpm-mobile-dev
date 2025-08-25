import 'package:flutter/material.dart';

class CoreFormField extends StatelessWidget {
  final String fieldKey;
  final String label;
  final dynamic value;
  final bool isDisabled;
  final bool isRequired;
  final ValueChanged<dynamic>? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;

  const CoreFormField({
    super.key,
    required this.fieldKey,
    required this.label,
    this.value,
    this.isDisabled = false,
    this.isRequired = false,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
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
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red.shade600),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Input Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled 
                  ? Colors.grey.shade300 
                  : Colors.blue.shade300,
              width: 1,
            ),
            color: isDisabled 
                ? Colors.grey.shade100 
                : Colors.white,
          ),
          child: TextFormField(
            initialValue: value?.toString() ?? '',
            enabled: !isDisabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 16,
              color: isDisabled 
                  ? Colors.grey.shade600 
                  : Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: isDisabled ? 'Disabled' : 'Enter $label',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CoreFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const CoreFormSection({
    super.key,
    required this.title,
    required this.children,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCollapsible) {
      return _buildContent();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
