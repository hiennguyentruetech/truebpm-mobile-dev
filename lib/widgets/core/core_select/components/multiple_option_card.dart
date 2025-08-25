import 'package:flutter/material.dart';

/// Widget for multiple option card with checkbox and scale animation
class MultipleOptionCard extends StatefulWidget {
  final dynamic option;
  final int index;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool hasMoreDisplay;
  final String codeValue;
  final List<MapEntry<String, String>> additionalFields;
  final Widget Function(String, String) buildInfoRow;

  const MultipleOptionCard({
    super.key,
    required this.option,
    required this.index,
    required this.isSelected,
    required this.onToggle,
    required this.hasMoreDisplay,
    required this.codeValue,
    required this.additionalFields,
    required this.buildInfoRow,
  });

  @override
  State<MultipleOptionCard> createState() => _MultipleOptionCardState();
}

class _MultipleOptionCardState extends State<MultipleOptionCard> {
  double _cardScale = 1.0;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _cardScale = 0.95;
            _isTapped = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _cardScale = 1.0;
            _isTapped = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _cardScale = 1.0;
            _isTapped = false;
          });
        },
        child: AnimatedScale(
          scale: _isTapped ? _cardScale : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.blue.shade100.withOpacity(0.3),
              highlightColor: Colors.blue.shade50.withOpacity(0.5),
              onTap: widget.onToggle,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    if (widget.isSelected)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.hasMoreDisplay ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with checkbox, index and code
                      Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.isSelected ? Colors.blue.shade600 : Colors.transparent,
                              border: Border.all(
                                color: widget.isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: widget.isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Index circle
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isSelected 
                                    ? [Colors.blue.shade500, Colors.blue.shade700]
                                    : [Colors.blue.shade400, Colors.blue.shade600],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.index.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Code container
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.isSelected 
                                      ? [Colors.blue.shade400, Colors.blue.shade500]
                                      : [Colors.blue.shade500, Colors.blue.shade600],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.code_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.codeValue,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Additional fields
                      if (widget.additionalFields.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...widget.additionalFields.map((field) => 
                          widget.buildInfoRow(field.key, field.value)),
                      ],
                    ],
                  ) : 
                  // Simple layout when no moreDisplay
                  Row(
                    children: [
                      // Checkbox
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.isSelected ? Colors.blue.shade600 : Colors.transparent,
                          border: Border.all(
                            color: widget.isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.codeValue,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: widget.isSelected ? Colors.blue.shade700 : Colors.black87,
                          ),
                        ),
                      ),
                      if (widget.isSelected) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
