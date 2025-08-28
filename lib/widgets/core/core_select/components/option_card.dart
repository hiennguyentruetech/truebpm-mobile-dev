import 'package:flutter/material.dart';

/// Widget for option card with scale animation like core_list_item_card
class OptionCardWithAnimation extends StatefulWidget {
  final dynamic option;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasMoreDisplay;
  final String codeValue;
  final List<MapEntry<String, String>> additionalFields;
  final Widget Function(String, String) buildInfoRow;

  const OptionCardWithAnimation({
    super.key,
    required this.option,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.hasMoreDisplay,
    required this.codeValue,
    required this.additionalFields,
    required this.buildInfoRow,
  });

  @override
  State<OptionCardWithAnimation> createState() => _OptionCardWithAnimationState();
}

class _OptionCardWithAnimationState extends State<OptionCardWithAnimation> {
  double _cardScale = 1.0;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0), // No margin since parent handles spacing
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _cardScale = 0.95; // Same as CoreConstants.cardScaleOnTap
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
          duration: const Duration(milliseconds: 150), // Same as CoreConstants.cardAnimationDuration
          curve: Curves.easeInOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              splashColor: Colors.blue.shade100.withOpacity(0.3),
              highlightColor: Colors.blue.shade50.withOpacity(0.5),
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(7),
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
                    // Add subtle glow effect when selected
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
                  padding: const EdgeInsets.all(14),
                  child: widget.hasMoreDisplay ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with index and code (like core_list_item) - only when hasMoreDisplay
                      Row(
                        children: [
                          // Index circle
                          Container(
                            width: 32,
                            height: 32,
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
                                  blurRadius: 8,
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          // Code container
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.isSelected 
                                      ? [Colors.blue.shade400, Colors.blue.shade500]
                                      : [Colors.blue.shade500, Colors.blue.shade600],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.codeValue,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Additional fields as label: value pairs (like core_list_item)
                      if (widget.additionalFields.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        ...widget.additionalFields.map((field) => 
                          widget.buildInfoRow(field.key, field.value)),
                      ],
                    ],
                  ) : 
                  // Simple layout when no moreDisplay - compact and clean
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: widget.isSelected ? Colors.blue.shade600 : Colors.transparent,
                          border: Border.all(
                            color: widget.isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: widget.isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 8,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
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
                            size: 16,
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
