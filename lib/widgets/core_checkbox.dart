import 'package:flutter/material.dart';

/// Core Checkbox Widget for boolean values with professional design
/// Supports itemDetail integration, attributes, and customization
class CoreCheckbox extends StatefulWidget {
  /// The key to access data in itemDetail
  final String dataKey;
  
  /// Item detail containing value and attribute data
  final Map<String, dynamic> itemDetail;
  
  /// Label text displayed next to checkbox
  final String? label;
  
  /// Hint text displayed below the checkbox
  final String? hintText;
  
  /// Custom text styling
  final TextStyle? textStyle;
  
  /// Custom checkbox decoration
  final InputDecoration? decoration;
  
  /// Focus node for the checkbox
  final FocusNode? focusNode;
  
  /// Whether this field is required
  final bool? required;
  
  /// Callback when value changes
  final Function(bool)? onChanged;
  
  /// Initial value if not found in itemDetail
  final bool? initialValue;
  
  /// Custom checkbox color
  final Color? checkboxColor;
  
  /// Checkbox position relative to label
  final CheckboxPosition position;
  
  /// Checkbox style variant
  final CheckboxStyle style;
  
  /// Custom icon when checked (for custom style)
  final IconData? customCheckedIcon;
  
  /// Custom icon when unchecked (for custom style)
  final IconData? customUncheckedIcon;
  
  /// Force-disable override. When set, takes precedence over attribute.disabled.
  final bool? disabled;
  
  /// Force-hidden override. When set, takes precedence over attribute.hidden.
  final bool? hidden;

  const CoreCheckbox({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    this.label,
    this.hintText,
    this.textStyle,
    this.decoration,
    this.focusNode,
    this.required,
    this.onChanged,
    this.initialValue,
    this.checkboxColor,
    this.position = CheckboxPosition.leading,
    this.style = CheckboxStyle.material,
    this.customCheckedIcon,
    this.customUncheckedIcon,
    this.disabled,
    this.hidden,
  });

  @override
  State<CoreCheckbox> createState() => _CoreCheckboxState();
}

class _CoreCheckboxState extends State<CoreCheckbox> with TickerProviderStateMixin {
  bool _value = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeValue();
    _setupBasicAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupColorAnimation();
    if (_value) {
      _animationController.forward();
    }
  }

  void _initializeValue() {
    // Get value from itemDetail or use initialValue
    final data = widget.itemDetail['value'] ?? {};
    final value = data[widget.dataKey];
    
    if (value is bool) {
      _value = value;
    } else if (value is String) {
      _value = value.toLowerCase() == 'true' || value == '1';
    } else if (value is int) {
      _value = value == 1;
    } else {
      _value = widget.initialValue ?? false;
    }
  }

  void _setupBasicAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize color animation with default colors first
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: Colors.blue, // Default color, will be updated in didChangeDependencies
    ).animate(_animationController);
  }

  void _setupColorAnimation() {
    // Update color animation with proper theme colors
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: _getCheckboxColor(),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper methods for field attributes
  bool get _isDisabled {
    if (widget.disabled != null) return widget.disabled!;
    final attributes = widget.itemDetail['attribute'] ?? {};
    return attributes['disabled']?[widget.dataKey] == true;
  }

  bool get _isHidden {
    if (widget.hidden != null) return widget.hidden!;
    final attributes = widget.itemDetail['attribute'] ?? {};
    return attributes['hidden']?[widget.dataKey] == true;
  }

  bool get _isRequired {
    if (widget.required != null) return widget.required!;
    final attributes = widget.itemDetail['attribute'] ?? {};
    return attributes['required']?[widget.dataKey] == true;
  }

  Color _getCheckboxColor() {
    if (widget.checkboxColor != null) return widget.checkboxColor!;
    return Theme.of(context).primaryColor;
  }

  void _handleValueChange(bool newValue) {
    if (_isDisabled) return;
    
    setState(() {
      _value = newValue;
    });
    
    // Update color animation to reflect current theme
    _setupColorAnimation();
    
    if (newValue) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    widget.onChanged?.call(newValue);
  }

  Widget _buildMaterialCheckbox() {
    return SizedBox(
      width: 24,
      height: 32,
      child: Checkbox(
        value: _value,
        onChanged: _isDisabled ? null : (bool? value) => _handleValueChange(value ?? false),
        activeColor: _getCheckboxColor(),
        checkColor: Colors.white,
        focusNode: widget.focusNode,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity(horizontal: 0, vertical: 0),
        splashRadius: 12,
      ),
    );
  }

  Widget _buildCustomCheckbox() {
    return SizedBox(
      width: 24,
      height: 32,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _isDisabled ? null : () => _handleValueChange(!_value),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _value ? _colorAnimation.value : Colors.transparent,
                  border: Border.all(
                    color: _value ? _colorAnimation.value! : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _value ? [
                    BoxShadow(
                      color: _colorAnimation.value!.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ] : null,
                ),
                child: _value
                    ? Icon(
                        widget.customCheckedIcon ?? Icons.check,
                        size: 18,
                        color: Colors.white,
                      )
                    : widget.customUncheckedIcon != null
                        ? Icon(
                            widget.customUncheckedIcon,
                            size: 18,
                            color: Colors.grey.shade400,
                          )
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchStyle() {
    return SizedBox(
      width: 40,
      height: 32, //
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: _value ? _getCheckboxColor() : Colors.grey.shade300,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: _value ? 18 : 2,
            top: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: _value
                  ? Icon(
                      Icons.check,
                      size: 10,
                      color: _getCheckboxColor(),
                    )
                  : null,
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildCheckboxWidget() {
    switch (widget.style) {
      case CheckboxStyle.material:
        return _buildMaterialCheckbox();
      case CheckboxStyle.custom:
        return _buildCustomCheckbox();
      case CheckboxStyle.switchStyle:
        return GestureDetector(
          onTap: _isDisabled ? null : () => _handleValueChange(!_value),
          child: _buildSwitchStyle(),
        );
    }
  }

  Widget _buildLabel() {
    if (widget.label == null) return const SizedBox.shrink();
    
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.label!,
                  style: (widget.textStyle ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(
                    color: _isDisabled ? Colors.grey.shade500 : null,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                if (_isRequired) ...[
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.hintText != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.hintText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 14),
      child: InkWell(
        onTap: _isDisabled ? null : () => _handleValueChange(!_value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: _value 
                  ? _getCheckboxColor().withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _value 
                ? _getCheckboxColor().withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widget.position == CheckboxPosition.leading
                ? [
                    Align(
                      alignment: Alignment.center,
                      child: _buildCheckboxWidget(),
                    ),
                    const SizedBox(width: 10),
                    _buildLabel(),
                  ]
                : [
                    _buildLabel(),
                    const SizedBox(width: 10),
                    Align(
                      alignment: Alignment.center,
                      child: _buildCheckboxWidget(),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Enum for checkbox position relative to label
enum CheckboxPosition {
  leading,
  trailing,
}

/// Enum for checkbox style variants
enum CheckboxStyle {
  material,
  custom,
  switchStyle,
}
