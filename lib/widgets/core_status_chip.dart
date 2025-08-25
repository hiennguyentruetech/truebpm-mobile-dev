import 'package:flutter/material.dart';

/// Status style configuration for CoreStatusChip
class StatusStyle {
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final String label;
  final IconData? icon;

  const StatusStyle({
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
    this.icon,
  });
}

/// Size variants for CoreStatusChip
enum CoreStatusChipSize {
  small,
  medium,
  large,
}

/// Professional status chip widget with dynamic styling based on status codes
/// 
/// Features:
/// - Dynamic color mapping based on status type codes  
/// - Dynamic data binding with itemDetail (like CoreInput, CoreSelect)
/// - Auto-hide/disable based on attributes
/// - Multiple size variants (small, medium, large)
/// - Professional Material Design 3.0 styling
/// - Consistent styling with list_core_screen logic
/// - Floating label support for form consistency
/// - Customizable appearance and behavior
/// - Modern design with gradients and shadows
class CoreStatusChip extends StatefulWidget {
  /// The key to bind value from itemDetail.value.dataKey
  final String dataKey;
  
  /// The complete item detail response containing value, attribute, etc.
  final Map<String, dynamic> itemDetail;
  
  /// Display label for the status chip (optional floating label)
  final String? label;
  
  /// Size variant of the chip
  final CoreStatusChipSize size;
  
  /// Custom text style override
  final TextStyle? textStyle;
  
  /// Whether to show status icon
  final bool showIcon;
  
  /// Custom padding override
  final EdgeInsets? padding;
  
  /// Whether the field is disabled (overrides API attribute)
  final bool disabled;
  
  /// Whether the field is hidden (overrides API attribute)
  final bool hidden;
  
  /// Callback when status changes (for interactive status chips)
  final ValueChanged<Map<String, dynamic>>? onChanged;

  const CoreStatusChip({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    this.label,
    this.size = CoreStatusChipSize.medium,
    this.textStyle,
    this.showIcon = true,
    this.padding,
    this.disabled = false,
    this.hidden = false,
    this.onChanged,
  });

  /// Factory constructor for simple status display (backward compatibility)
  factory CoreStatusChip.simple({
    required Map<String, dynamic> status,
    CoreStatusChipSize size = CoreStatusChipSize.medium,
    TextStyle? textStyle,
    bool showIcon = true,
    EdgeInsets? padding,
    String? label,
  }) {
    return CoreStatusChip(
      dataKey: 'status',
      itemDetail: {'value': {'status': status}},
      label: label,
      size: size,
      textStyle: textStyle,
      showIcon: showIcon,
      padding: padding,
    );
  }

  /// Factory constructor for integration with CoreDynamicFields
  factory CoreStatusChip.fromValue({
    required dynamic value,
    CoreStatusChipSize size = CoreStatusChipSize.medium,
    TextStyle? textStyle,
    bool showIcon = true,
    EdgeInsets? padding,
    String? label,
  }) {
    Map<String, dynamic> statusValue;
    if (value is Map<String, dynamic>) {
      statusValue = value;
    } else {
      // Fallback for simple string values
      statusValue = {'name': value?.toString() ?? 'Unknown'};
    }
    
    return CoreStatusChip.simple(
      status: statusValue,
      size: size,
      textStyle: textStyle,
      showIcon: showIcon,
      padding: padding,
      label: label,
    );
  }

  @override
  State<CoreStatusChip> createState() => _CoreStatusChipState();
}

class _CoreStatusChipState extends State<CoreStatusChip> {
  /// Get current status value from itemDetail
  Map<String, dynamic> get _statusValue {
    final value = widget.itemDetail['value']?[widget.dataKey];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return {'name': value?.toString() ?? 'Unknown'};
  }

  /// Check if field is disabled
  bool get _isDisabled {
    return widget.disabled || 
           widget.itemDetail['attribute']?['disabled']?[widget.dataKey] == true;
  }

  /// Check if field is hidden
  bool get _isHidden {
    return widget.hidden || 
           widget.itemDetail['attribute']?['hidden']?[widget.dataKey] == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14), // Match CoreInput margin
      child: _buildStatusChipWithLabel(),
    );
  }

  /// Build status chip with floating label (similar to CoreInput/CoreSelect)
  Widget _buildStatusChipWithLabel() {
    return Stack(
      children: [
        // Main status chip container
        _buildStatusChipContainer(),
        // Floating label positioned like CoreInput
        if (widget.label != null) _buildFloatingLabel(),
      ],
    );
  }

  /// Build floating label (positioned like CoreInput/CoreSelect)
  Widget _buildFloatingLabel() {
    final style = _buildStatusStyle();
    final Color labelColor = _isDisabled
        ? const Color.fromARGB(255, 165, 165, 165)
        : style.color; // Use status color for label
    final Color labelBgColor = _isDisabled 
        ? Colors.grey.shade50 
        : style.backgroundColor; // Use status background color

    return Positioned(
      left: 12,
      top: -10, // Adjusted to prevent overflow
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200, // Prevent overflow with max width
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: labelBgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: style.borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          widget.label!,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
          overflow: TextOverflow.ellipsis, // Handle overflow
          maxLines: 1,
        ),
      ),
    );
  }

  /// Build the main status chip container (full width like other widgets)
  Widget _buildStatusChipContainer() {
    final style = _buildStatusStyle();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, // Full width like CoreInput/CoreSelect
      padding: const EdgeInsets.symmetric(
        horizontal: 12, // Reduced from 16 to match CoreInput
        vertical: 7,   // Match CoreInput height (~56px total)
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            style.backgroundColor,
            style.backgroundColor.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // Match CoreInput border radius
        border: Border.all(
          color: style.borderColor,
          width: 1.5, // Slightly thicker border for prominence
        ),
        boxShadow: _isDisabled ? null : [
          BoxShadow(
            color: style.color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left icon container with enhanced styling
          if (widget.showIcon && style.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8), // Reduced from 10
                border: Border.all(
                  color: style.color.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(
                style.icon,
                color: _isDisabled ? Colors.grey.shade400 : style.color,
                size: 18, // Fixed size for consistency
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12
          ],
          // Status text with enhanced styling
          Expanded(
            child: Text(
              style.label,
              style: widget.textStyle ?? TextStyle(
                color: _isDisabled ? Colors.grey.shade500 : style.color,
                fontSize: 14, // Fixed consistent size
                fontWeight: FontWeight.w700, // Đậm hơn (tăng từ w600 lên w700)
                letterSpacing: 0.2,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Right indicator (optional visual enhancement)
          Container(
            width: 3,  // Reduced from 4
            height: 20, // Reduced from 24
            decoration: BoxDecoration(
              color: _isDisabled ? Colors.grey.shade300 : style.color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Build status style based on status type code (same logic as list_core_screen)
  StatusStyle _buildStatusStyle() {
    try {
      final statusType = (_statusValue['statusType'] ?? {}) as Map<String, dynamic>;
      final code = (statusType['code']?.toString() ?? '').toLowerCase();
      
      // Always prioritize status.name from API for label
      final String dynamicLabel = _statusValue['name']?.toString() ?? '';
      
      if (code.isEmpty) {
        return _buildFallbackStyle();
      }

      Color color;
      String label;
      IconData? icon;

      switch (code) {
        case 'pending':
          color = Colors.blue.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Pending';
          icon = Icons.pending_outlined;
          break;
        case 'completed':
          color = Colors.green.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Completed';
          icon = Icons.check_circle;
          break;
        case 'rejected':
          color = Colors.red.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Rejected';
          icon = Icons.cancel;
          break;
        case 'canceled':
        case 'cancelled':
          color = Colors.blueGrey.shade800; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Canceled';
          icon = Icons.not_interested;
          break;
        case 'progress':
        case 'inprogress':
        case 'in-progress':
          color = Colors.orange.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'In Progress';
          icon = Icons.sync;
          break;
        case 'approved':
          color = Colors.teal.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Approved';
          icon = Icons.verified;
          break;
        case 'draft':
          color = Colors.grey.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Draft';
          icon = Icons.edit_document;
          break;
        case 'submitted':
          color = Colors.indigo.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Submitted';
          icon = Icons.upload;
          break;
        case 'active':
          color = Colors.green.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Active';
          icon = Icons.check_circle;
          break;
        case 'inactive':
          color = Colors.grey.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Inactive';
          icon = Icons.pause_circle;
          break;
        case 'expired':
          color = Colors.red.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Expired';
          icon = Icons.access_time_filled;
          break;
        case 'processing':
          color = Colors.blue.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty ? dynamicLabel : 'Processing';
          icon = Icons.hourglass_top;
          break;
        default:
          // Fallback: use status name if available
          color = Colors.indigo.shade700; // Đậm hơn cho text
          label = dynamicLabel.isNotEmpty 
              ? dynamicLabel
              : (code.isNotEmpty ? code[0].toUpperCase() + code.substring(1) : 'Unknown');
          icon = Icons.info;
      }

      return StatusStyle(
        color: color,
        backgroundColor: color.withValues(alpha: 0.06), // Nền nhạt hơn (giảm từ 0.10 xuống 0.06)
        borderColor: color.withValues(alpha: 0.25), // Border nhạt hơn (giảm từ 0.30 xuống 0.25)
        label: label,
        icon: icon,
      );
    } catch (_) {
      return _buildFallbackStyle();
    }
  }

  /// Fallback style when status parsing fails
  StatusStyle _buildFallbackStyle() {
    final label = _statusValue['name']?.toString() ?? 'Unknown';
    final color = Colors.grey.shade700; // Đậm hơn cho text
    
    return StatusStyle(
      color: color,
      backgroundColor: color.withValues(alpha: 0.06), // Nền nhạt hơn
      borderColor: color.withValues(alpha: 0.25), // Border nhạt hơn
      label: label,
      icon: Icons.help_outline,
    );
  }
}
