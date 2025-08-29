import 'package:flutter/material.dart';

/// A reusable card section widget with expand/collapse functionality
/// Features:
/// - Custom header title
/// - Expand/collapse animation
/// - Custom children widgets
/// - Beautiful and impressive UI design
/// - Optimized for UX
class CardSection extends StatefulWidget {
  /// The title displayed in the header
  final String title;
  
  /// The children widgets to display inside the card
  final List<Widget> children;
  
  /// Whether the card is initially expanded
  final bool initiallyExpanded;
  
  /// Custom icon for the header (optional)
  final IconData? headerIcon;
  
  /// Custom color for the header (optional)
  final Color? headerColor;
  
  /// Elevation of the card
  final double elevation;
  
  /// Padding inside the card content
  final EdgeInsets contentPadding;
  
  /// Margin around the card
  final EdgeInsets margin;
  
  /// Callback when expansion state changes
  final ValueChanged<bool>? onExpansionChanged;

  const CardSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.headerIcon,
    this.headerColor,
    this.elevation = 4,
    this.contentPadding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.onExpansionChanged,
  });

  @override
  State<CardSection> createState() => _CardSectionState();
}

class _CardSectionState extends State<CardSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotationAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Rotate icon to the right (90 degrees) when expanded
    _iconRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.25, // 0.25 * 2pi = pi/2 = 90 degrees
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerColor = widget.headerColor ?? colorScheme.primary;

    return Container(
      margin: widget.margin,
      child: Card(
        elevation: widget.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header with gradient background
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpansion,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        headerColor,
                        headerColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Header icon (if provided)
                        if (widget.headerIcon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.headerIcon,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // Title
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        
                        // Expand/collapse indicator with animation
                        AnimatedBuilder(
                          animation: _iconRotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _iconRotationAnimation.value * -2 * 3.14159, // 0 to 90 degrees
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content with slide animation
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: widget.contentPadding,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    top: BorderSide(
                      color: headerColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isExpanded ? 1.0 : 0.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
