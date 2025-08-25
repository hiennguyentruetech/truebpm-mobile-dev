import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input types enum for CoreInput
enum CoreInputType {
  text,
  number,
  currency,
  textarea,
  email,
  phone,
  password,
  url,
}

/// Core input widget with dynamic data binding and professional design
/// 
/// Features:
/// - Overlapping text label animation
/// - Dynamic data binding with itemDetail
/// - Auto-hide/disable based on attributes
/// - Multiple input types (text, number, currency, textarea, etc.)
/// - Custom suffixes/symbols (currency, units, etc.)
/// - Professional and modern design
class CoreInput extends StatefulWidget {
  /// Manually specify if the field is required (overrides API if set)
  final bool? required;
  /// The key to bind value from itemDetail.value.<key>
  final String dataKey;
  
  /// The complete item detail response containing value, attribute, etc.
  final Map<String, dynamic> itemDetail;
  
  /// Display label for the input (defaults to dataKey if not provided)
  final String? label;
  
  /// Input type (text, number, currency, textarea, etc.)
  final CoreInputType type;
  
  /// Suffix symbol/text (e.g., "VND", "$", "L", "m", etc.)
  final String? suffix;
  
  /// Callback when value changes
  final ValueChanged<String>? onChanged;
  
  /// Custom validation function
  final String? Function(String?)? validator;
  
  /// Hint text for the input
  final String? hintText;
  
  /// Maximum number of lines (for textarea type)
  final int? maxLines;
  
  /// Custom text style
  final TextStyle? textStyle;
  
  /// Custom input decoration
  final InputDecoration? decoration;
  
  /// Focus node for the input
  final FocusNode? focusNode;
  
  /// Whether to show character counter
  final bool showCounter;
  
  /// Maximum length of input
  final int? maxLength;
  
  /// Number of decimal places for number type (default: 0 for integer display)
  final int decimalPlaces;

  /// Minimum value for number type
  final double? minValue;

  /// Maximum value for number type
  final double? maxValue;

  /// Force-disable override. When set, takes precedence over attribute.disabled.
  final bool? disabled;

  /// Force-hidden override. When set, takes precedence over attribute.hidden.
  final bool? hidden;

  /// View-only mode: show value but never send it via onChanged to payload.
  /// When true, the field behaves as disabled for editing and won't emit changes.
  final bool onlyView;

  const CoreInput({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    this.label,
    this.type = CoreInputType.text,
    this.suffix,
    this.onChanged,
    this.validator,
    this.hintText,
    this.maxLines,
    this.textStyle,
    this.decoration,
    this.focusNode,
    this.showCounter = false,
    this.maxLength,
    this.required,
    this.decimalPlaces = 0,
    this.minValue,
    this.maxValue,
    this.disabled,
    this.hidden,
    this.onlyView = false,
  });

  @override
  State<CoreInput> createState() => _CoreInputState();
}

class _CoreInputState extends State<CoreInput> {
  bool get _isRequired {
    if (widget.required != null) return widget.required!;
    // Fallback to API attribute if available
    final requiredAttr = widget.itemDetail['attribute']?['required']?[widget.dataKey];
    return requiredAttr == true;
  }
  late TextEditingController _controller;
  late FocusNode _focusNode;
  
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _controller = TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Setup listeners
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
    
    // Set initial value
    _setInitialValue();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CoreInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if itemDetail or dataKey changed
    if (oldWidget.itemDetail != widget.itemDetail || oldWidget.dataKey != widget.dataKey) {
      final newValue = _getCurrentValue();
      if (!_focusNode.hasFocus) {
        if (widget.type == CoreInputType.number) {
          _controller.text = newValue == null || newValue.toString().isEmpty
              ? ''
              : _formatNumberDisplay(newValue);
        } else {
          _controller.text = newValue?.toString() ?? '';
        }
      }
    }
  }

  void _setInitialValue() {
    final value = _getCurrentValue();
    if (value != null && value.toString().isNotEmpty) {
      if (widget.type == CoreInputType.number) {
        _controller.text = _formatNumberDisplay(value);
      } else {
        _controller.text = value.toString();
      }
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    // When unfocusing, sync with latest value from itemDetail
    _handleUnfocus();
  }

  void _onTextChange() {
    if (widget.onChanged == null) return;
    if (widget.onlyView) return; // Do not propagate any value changes

    if (widget.type == CoreInputType.number || widget.type == CoreInputType.currency) {
      // Real-time auto-adjust for min/max values
      final adjustedText = _autoAdjustMinMaxValueRealTime(_controller.text);
      if (adjustedText != _controller.text) {
        // Update controller without triggering another onChanged
        _controller.removeListener(_onTextChange);
        _controller.text = adjustedText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: adjustedText.length),
        );
        _controller.addListener(_onTextChange);
      }

      final normalized = _normalizeNumberValue(_controller.text);
      widget.onChanged!(normalized);
    } else {
      widget.onChanged!(_controller.text);
    }
  }

  void _handleUnfocus() {
    if (!_focusNode.hasFocus) {
      final latestValue = _getCurrentValue();
      if (widget.type == CoreInputType.number || widget.type == CoreInputType.currency) {
        // Auto-adjust min/max values before formatting
        final adjustedValue = _autoAdjustMinMaxValue(_controller.text);

        // Always format to EU style on unfocus for consistency
        final source = adjustedValue.isNotEmpty
            ? adjustedValue
            : (latestValue?.toString() ?? '');
        final formatted = _formatNumberDisplay(source);
        if (_controller.text != formatted) {
          _controller.text = formatted;
          // Trigger onChanged with adjusted value
          if (widget.onChanged != null && !widget.onlyView) {
            final normalized = _normalizeNumberValue(formatted);
            widget.onChanged!(normalized);
          }
        }
      } else {
        if (_controller.text != (latestValue?.toString() ?? '')) {
          _controller.text = latestValue?.toString() ?? '';
        }
      }
    }
  }

  // Auto-adjust value to min/max bounds
  String _autoAdjustMinMaxValue(String input) {
    if (input.isEmpty) return input;
    if (widget.minValue == null && widget.maxValue == null) return input;

    // Parse the value (handle EU format with dots and commas)
    String cleanValue = input.replaceAll('.', '').replaceAll(',', '.');
    final double? numValue = double.tryParse(cleanValue);

    if (numValue == null) return input;

    double adjustedValue = numValue;

    // Apply min constraint
    if (widget.minValue != null && adjustedValue < widget.minValue!) {
      adjustedValue = widget.minValue!;
    }

    // Apply max constraint
    if (widget.maxValue != null && adjustedValue > widget.maxValue!) {
      adjustedValue = widget.maxValue!;
    }

    // If value was adjusted, return the adjusted value as string
    if (adjustedValue != numValue) {
      // Format back to EU style (use comma as decimal separator)
      if (widget.decimalPlaces > 0) {
        return adjustedValue.toStringAsFixed(widget.decimalPlaces).replaceAll('.', ',');
      } else {
        return adjustedValue.toInt().toString();
      }
    }

    return input; // No adjustment needed
  }

  // Real-time auto-adjust value to min/max bounds (more aggressive)
  String _autoAdjustMinMaxValueRealTime(String input) {
    if (input.isEmpty) return input;
    if (widget.minValue == null && widget.maxValue == null) return input;

    // Only adjust if user has finished typing a complete number
    // Check if input ends with a digit (not in the middle of typing)
    if (!RegExp(r'\d$').hasMatch(input)) return input;

    // Parse the value (handle EU format with dots and commas)
    String cleanValue = input.replaceAll('.', '').replaceAll(',', '.');
    final double? numValue = double.tryParse(cleanValue);

    if (numValue == null) return input;

    double adjustedValue = numValue;
    bool wasAdjusted = false;

    // Apply min constraint
    if (widget.minValue != null && adjustedValue < widget.minValue!) {
      adjustedValue = widget.minValue!;
      wasAdjusted = true;
    }

    // Apply max constraint
    if (widget.maxValue != null && adjustedValue > widget.maxValue!) {
      adjustedValue = widget.maxValue!;
      wasAdjusted = true;
    }

    // If value was adjusted, return the adjusted value as string
    if (wasAdjusted) {
      // Format back to EU style (use comma as decimal separator)
      if (widget.decimalPlaces > 0) {
        return adjustedValue.toStringAsFixed(widget.decimalPlaces).replaceAll('.', ',');
      } else {
        return adjustedValue.toInt().toString();
      }
    }

    return input; // No adjustment needed
  }

  bool get _isDisabled {
  if (widget.onlyView) return true;
  if (widget.disabled != null) return widget.disabled!;
    final disabled = widget.itemDetail['attribute']?['disabled']?[widget.dataKey];
    return disabled == true;
  }

  bool get _isHidden {
    if (widget.hidden != null) return widget.hidden!;
    final hidden = widget.itemDetail['attribute']?['hidden']?[widget.dataKey];
    return hidden == true;
  }

  String get _displayLabel {
    if (widget.label != null) return widget.label!;
    
    // Convert camelCase to Title Case
    return widget.dataKey.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  Widget get _buildLabel {
    final labelText = _displayLabel;
    if (_isRequired) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: labelText,
              style: TextStyle(
                color: _isDisabled 
                  ? const Color.fromARGB(255, 180, 180, 180)
                  : (_isFocused 
                    ? Colors.blue.shade600 
                    : const Color.fromARGB(255, 91, 91, 91)),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        labelText,
        style: TextStyle(
          color: _isDisabled 
            ? const Color.fromARGB(255, 180, 180, 180)
            : (_isFocused 
              ? Colors.blue.shade600 
              : const Color.fromARGB(255, 91, 91, 91)),
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  TextInputType get _keyboardType {
    switch (widget.type) {
      case CoreInputType.number:
        return TextInputType.numberWithOptions(decimal: widget.decimalPlaces > 0, signed: false);
      case CoreInputType.currency:
        return const TextInputType.numberWithOptions(decimal: true, signed: false);
      case CoreInputType.email:
        return TextInputType.emailAddress;
      case CoreInputType.phone:
        return TextInputType.phone;
      case CoreInputType.url:
        return TextInputType.url;
      case CoreInputType.textarea:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> get _inputFormatters {
    switch (widget.type) {
      case CoreInputType.number:
        return [
          // Allow only digits when no decimals; allow comma when decimals are enabled
          FilteringTextInputFormatter.allow(
            widget.decimalPlaces > 0 ? RegExp(r'[0-9,]') : RegExp(r'[0-9]'),
          ),
          _NumberEuInputFormatter(decimalPlaces: widget.decimalPlaces),
        ];
      case CoreInputType.currency:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          _CurrencyInputFormatter(),
        ];
      case CoreInputType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return [];
    }
  }

  int get _maxLines {
    if (widget.maxLines != null) return widget.maxLines!;
    switch (widget.type) {
      case CoreInputType.textarea:
        return 4;
      case CoreInputType.password:
        return 1;
      default:
        return 1;
    }
  }

  bool get _obscureText {
    return widget.type == CoreInputType.password;
  }

  // Helper: normalize display text (e.g., "1.500,5") to machine value ("1500.5")
  String _normalizeNumberValue(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    // Always remove thousand group separators '.' from display
    final noThousands = trimmed.replaceAll('.', '');
    // If contains comma, treat comma as decimal. Convert to dot decimal for machine value.
    if (noThousands.contains(',')) {
      return noThousands.replaceAll(',', '.');
    }
    // Pure integer
    return noThousands;
  }

  // Helper: format number for display (EU style: thousand '.' and decimal ',')
  String _formatNumberDisplay(dynamic value) {
    if (value == null) return '';
    String s = value is num ? value.toString() : value.toString().trim();
    if (s.isEmpty) return '';

    String intRaw = '';
    String decRaw = '';

    if (s.contains(',')) {
      // EU-style input: remove thousand dots, comma is decimal
      final cleaned = s.replaceAll('.', '');
      final idx = cleaned.indexOf(',');
      intRaw = (idx >= 0 ? cleaned.substring(0, idx) : cleaned);
      decRaw = (idx >= 0 ? cleaned.substring(idx + 1) : '');
    } else if (s.contains('.') && value is num) {
      // Machine value (num) with dot decimals: keep decimal
      final parts = s.split('.');
      intRaw = parts[0];
      decRaw = parts.length > 1 ? parts[1] : '';
    } else {
      // Treat dots as thousand separators: remove them and keep as integer
      intRaw = s.replaceAll('.', '');
    }

    // Keep digits only
    intRaw = intRaw.replaceAll(RegExp(r'[^0-9]'), '');
    decRaw = decRaw.replaceAll(RegExp(r'[^0-9]'), '');

    if (intRaw.isEmpty) return '';

    // Handle decimal places = 0: round based on first decimal digit then drop decimals
    if (widget.decimalPlaces == 0 && decRaw.isNotEmpty) {
      final first = int.tryParse(decRaw[0]) ?? 0;
      if (first >= 5) {
        final intVal = int.parse(intRaw) + 1;
        intRaw = intVal.toString();
      }
      decRaw = '';
    }

    final grouped = _groupThousands(intRaw);

    if (widget.decimalPlaces > 0 && decRaw.isNotEmpty) {
      if (decRaw.length > widget.decimalPlaces) {
        decRaw = decRaw.substring(0, widget.decimalPlaces);
      }
      return '$grouped,$decRaw';
    }
    return grouped;
  }

  String _groupThousands(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if hidden
    if (_isHidden) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !_isDisabled,
        keyboardType: _keyboardType,
        inputFormatters: _inputFormatters,
        maxLines: _maxLines,
        maxLength: widget.maxLength,
        obscureText: _obscureText,
        style: widget.textStyle ?? TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _isDisabled ? Colors.grey.shade400 : Colors.grey.shade800,
        ),
        validator: widget.validator ?? _buildValidator(),
        decoration: _buildInputDecoration(),
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      // Floating label with red asterisk for required fields
      label: _buildLabel,
      floatingLabelStyle: TextStyle(
        color: _isDisabled 
          ? const Color.fromARGB(255, 165, 165, 165)
          : Colors.blue.shade600,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      
      hintText: _isDisabled ? null : widget.hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13,
      ),
      
      // Suffix for symbols/units - positioned at right corner only
      suffixIcon: widget.suffix != null && widget.suffix!.isNotEmpty
          ? Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Light grey background
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(
                  left: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.suffix!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isFocused ? Colors.blue.shade600 : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      
      // Border styling - more compact
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.blue.shade600,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.red.shade600,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      
      // Fill and colors
      filled: true,
      fillColor: _isDisabled 
        ? Colors.grey.shade50 
        : Colors.white,
      
      // Content padding - more compact
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      
      // Counter styling
      counterStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
      ),
      
      // Error styling
      errorStyle: TextStyle(
        color: Colors.red.shade600,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      
      // Always show label in floating/overlapping position
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }

  /// Resolve current value from itemDetail using dot-paths (e.g., "customerId.name").
  dynamic _getCurrentValue() {
    final valueMap = widget.itemDetail['value'];
    if (valueMap is Map<String, dynamic>) {
      if (widget.dataKey.contains('.')) {
        return _getByPath(valueMap, widget.dataKey);
      }
      return valueMap[widget.dataKey];
    }
    return null;
  }

  /// Get nested value by path like 'a.b.c'
  dynamic _getByPath(Map<String, dynamic> map, String path) {
    dynamic curr = map;
    for (final part in path.split('.')) {
      if (curr is Map && curr.containsKey(part)) {
        curr = curr[part];
      } else {
        return null;
      }
    }
    return curr;
  }

  /// Build validator function with min/max value validation for number types
  String? Function(String?)? _buildValidator() {
    return (value) {
      // Required validation
      if (_isRequired && (value == null || value.isEmpty)) {
        return 'This field is required';
      }

      // Min/Max validation for number types
      if ((widget.type == CoreInputType.number || widget.type == CoreInputType.currency) &&
          value != null && value.isNotEmpty) {

        // Parse the value (handle EU format with dots and commas)
        String cleanValue = value.replaceAll('.', '').replaceAll(',', '.');
        final double? numValue = double.tryParse(cleanValue);

        if (numValue != null) {
          if (widget.minValue != null && numValue < widget.minValue!) {
            return 'Value must be at least ${widget.minValue}';
          }
          if (widget.maxValue != null && numValue > widget.maxValue!) {
            return 'Value must not exceed ${widget.maxValue}';
          }
        }
      }

      return null;
    };
  }
}

/// Custom formatter for EU-style number inputs (thousand '.' and decimal ',')
class _NumberEuInputFormatter extends TextInputFormatter {
  _NumberEuInputFormatter({this.decimalPlaces = 0});
  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String raw = newValue.text;
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Allow only digits and comma. Ignore dots typed by user.
    raw = raw.replaceAll(RegExp(r'[^0-9,]'), '');

    // Split by comma (decimal separator). Only keep first comma.
    final firstComma = raw.indexOf(',');
    String intRaw;
    String decRaw = '';
    if (firstComma >= 0) {
      intRaw = raw.substring(0, firstComma);
      decRaw = raw.substring(firstComma + 1).replaceAll(',', '');
      if (decimalPlaces > 0 && decRaw.length > decimalPlaces) {
        decRaw = decRaw.substring(0, decimalPlaces);
      }
    } else {
      intRaw = raw;
    }

    // Remove any leading zeros except when the value is exactly '0'
    intRaw = intRaw.replaceAll(RegExp(r'^0+(?=\d)'), '');

    // Group thousands for integer part
    final grouped = _groupThousands(intRaw);

    // Rebuild display text
    String display = grouped;
    if (firstComma >= 0) {
      display = '$grouped,$decRaw';
    }

    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }

  String _groupThousands(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

/// Custom formatter for currency inputs
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters except decimal point
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Ensure only one decimal point
    final parts = newText.split('.');
    if (parts.length > 2) {
      newText = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    
    // Limit decimal places to 2
    if (parts.length == 2 && parts[1].length > 2) {
      newText = '${parts[0]}.${parts[1].substring(0, 2)}';
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Extension for Colors to add shade25
extension ColorsExtension on MaterialColor {
  Color get shade25 => Color.lerp(this[50], Colors.white, 0.5)!;
}
