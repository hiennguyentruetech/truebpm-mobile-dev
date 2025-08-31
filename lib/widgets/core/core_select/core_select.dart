import 'package:flutter/material.dart';
import 'core_select_types.dart';
import 'core_select_utils.dart';
import 'components/floating_label.dart';
import 'components/info_row.dart';
import 'types/select_type.dart';
import 'types/dropdown_type.dart';
import 'types/multiple_type.dart';
import 'dialogs/dropdown_dialog.dart';
import 'dialogs/multiple_selection_dialog.dart';

/*
 * CoreSelect Widget - Beautiful & Professional Dropdown Solution
 * 
 * ✨ Features:
 * - Floating overlapping labels (just like CoreInput)
 * - Modern Material Design 3.0 styling
 * - Smooth animations and hover effects
 * - Professional gradient designs
 * - Beautiful shadows and borders
 * 
 * 🎨 Three Stunning Types:
 * 
 * 1. SELECT - Elegant dropdown with floating label:
 *    CoreSelect(
 *      data: ['Option 1', 'Option 2'],
 *      type: CoreSelectType.select,
 *      label: 'Choose Option',
 *    )
 * 
 * 2. DROPDOWN - Searchable with real-time filtering:
 *    CoreSelect(
 *      data: 'DROPDOWN.MODULE.ALLSCHEMA',
 *      display: 'name',
 *      type: CoreSelectType.dropdown, // Beautiful search UI
 *      label: 'Search & Select',
 *    )
 * 
 * 3. MULTIPLE - Multiple selection with checkboxes:
 *    CoreSelect(
 *      data: 'DROPDOWN.USERS.ALL',
 *      display: 'userName',
 *      type: CoreSelectType.multiple, // Stunning multiple selection
 *      label: 'Advanced Selection',
 *    )
 * 
 * 🚀 Professional UI Elements:
 * - Gradient headers in popup
 * - Card-based option layouts
 * - Loading states with elegant spinners
 * - Empty states with helpful icons
 * - Smooth selection animations
 */

/// Reusable CoreSelect widget for dropdown/select functionality
class CoreSelect extends StatefulWidget {
  final String dataKey;
  final Map<String, dynamic> itemDetail;
  final String? label;
  final String? hintText;
  final CoreSelectType type;
  final bool required;
  final bool disabled;
  final bool hidden;
  final String? display; // Key to display when value is object
  final List<Map<String, String>>? moreDisplay; // Additional fields to show in popup: [{label: 'Description', key: 'description'}]
  final dynamic data; // Can be List<String>, List<Map>, or String (API endpoint)
  final Function(dynamic)? onChanged;
  final dynamic initialValue;
  
  // Special configuration for grantPermission and similar fields
  final String? specialDisplay; // For special display format like 'userPermission.name'
  final bool useUserPermissionWrapper; // Whether to wrap selected items in userPermission object
  
  // Split key functionality for different display in input vs dropdown
  final bool splitKey; // Whether to use different display keys for input and dropdown
  final String? dropdownDisplay; // Display key for dropdown options (when splitKey is true)

  const CoreSelect({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    this.label,
    this.hintText,
    this.type = CoreSelectType.select,
    this.required = false,
    this.disabled = false,
    this.hidden = false,
    this.display,
    this.moreDisplay,
    this.data,
    this.onChanged,
    this.initialValue,
    this.specialDisplay,
    this.useUserPermissionWrapper = false,
    this.splitKey = false,
    this.dropdownDisplay,
  });

  @override
  State<CoreSelect> createState() => _CoreSelectState();
}

class _CoreSelectState extends State<CoreSelect> {
  dynamic _selectedValue;
  List<dynamic> _options = [];
  bool _isInitialized = false;
  List<dynamic> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue ?? _getValueFromItemDetail();
    _initializeOptions();
  }

  @override
  void didUpdateWidget(CoreSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always re-read value from itemDetail; its reference may be same even when inner value changed
    final newValue = _getValueFromItemDetail();
    if (!_compareValues(_selectedValue, newValue)) {
      setState(() {
        _selectedValue = newValue;
      });
    }
  }

  /// Get current value from itemDetail
  dynamic _getValueFromItemDetail() {
    final value = widget.itemDetail['value']?[widget.dataKey];
    // For splitKey, we need to handle the nested structure properly
    if (widget.splitKey && value is List) {
      // Return the list as-is for splitKey cases (e.g., grantPermission with userPermission wrapper)
      // The list contains items with userPermission wrapper structure
      return value;
    } else if (value is Map && widget.display != null) {
      final displayValue = value[widget.display];
      if (displayValue == null) {
        return null;
      }
    }
    return value;
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

  /// Initialize options based on data type
  Future<void> _initializeOptions() async {
    if (widget.data == null) return;

    if (widget.data is List) {
      // Static data
      setState(() {
        _options = List.from(widget.data);
        _filteredOptions = List.from(_options);
        _isInitialized = true;
      });
    } else if (widget.data is String) {
      // API endpoint - load on first focus
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Load data from API
  Future<void> _loadOptionsFromAPI() async {
    if (widget.data is! String || _options.isNotEmpty) return;

    final options = await CoreSelectUtils.loadOptionsFromAPI(
      widget.data as String,
      context,
    );

    if (mounted) {
      setState(() {
        _options = options;
        _filteredOptions = List.from(_options);
      });
    }
  }

  /// Get display text for an option (for dropdown/popup)
  String _getDisplayText(dynamic option) {
    // Use dropdownDisplay when splitKey is true, otherwise use display
    // This ensures that in dropdown/popup, we show the dropdownDisplay key (e.g., 'name')
    // The option here is the raw option from API/data source
    final String? displayKey = widget.splitKey ? widget.dropdownDisplay : widget.display;
    return CoreSelectUtils.getDisplayText(option, displayKey);
  }

  /// Get the actual value from an option
  dynamic _getOptionValue(dynamic option) {
    // For splitKey, we need to return the raw option as-is for comparison
    // This ensures that when comparing, we can extract the ID correctly
    if (widget.splitKey) {
      return option; // Return raw option for splitKey cases
    }
    
    // For non-splitKey cases, use normal logic
    final String? displayKey = widget.dropdownDisplay ?? widget.display;
    return CoreSelectUtils.getOptionValue(option, displayKey);
  }

  /// Compare two values for equality (handles objects and primitives)
  bool _compareValues(dynamic value1, dynamic value2) {
    if (widget.splitKey) {
      // For splitKey, we need special comparison logic
      // value1 is the selected item (with userPermission wrapper)
      // value2 is the raw option from API/data source
      if (value1 is Map && value2 is Map) {
        // Extract the actual ID from userPermission wrapper
        final selectedId = value1['userPermission']?['id'] ?? value1['id'];
        final optionId = value2['id'];
        return selectedId == optionId;
      }
      
      // Handle case where value1 is not a Map (e.g., string ID)
      if (value1 is String && value2 is Map) {
        return value1 == value2['id'];
      }
      
      // Handle case where value2 is not a Map (e.g., string ID)
      if (value1 is Map && value2 is String) {
        final selectedId = value1['userPermission']?['id'] ?? value1['id'];
        return selectedId == value2;
      }
      
      // Handle case where both are strings
      if (value1 is String && value2 is String) {
        return value1 == value2;
      }
    }
    
    // For non-splitKey cases, use normal comparison
    final String? displayKey = widget.splitKey ? widget.dropdownDisplay : widget.display;
    return CoreSelectUtils.compareValues(value1, value2, displayKey);
  }

  /// Get default label from dataKey
  String _getDefaultLabel() {
    return CoreSelectUtils.getDefaultLabel(widget.dataKey);
  }

  /// Get display text for input field (when splitKey is true, use display instead of dropdownDisplay)
  String _getInputDisplayText(dynamic option) {
    // Always use display for input field, even when splitKey is true
    // This ensures that for grantPermission, we show userPermission.name in the input
    // The option here is the item with userPermission wrapper structure
    if (widget.splitKey && option is Map) {
      // For splitKey, extract the name from userPermission wrapper
      final userPermission = option['userPermission'];
      if (userPermission is Map) {
        final displayText = userPermission['name']?.toString() ?? '';
        // Debug: print('🔄 Input display (userPermission): $option -> $displayText');
        return displayText;
      }
      
      // Fallback: if no userPermission wrapper, try to get name directly
      if (option.containsKey('name')) {
        final displayText = option['name']?.toString() ?? '';
        // Debug: print('🔄 Input display (direct name): $option -> $displayText');
        return displayText;
      }
    }
    
    final displayText = CoreSelectUtils.getDisplayText(option, widget.display);
    // Debug: print('🔄 Input display (fallback): $option -> $displayText');
    return displayText;
  }

  /// Format selected values for splitKey cases
  dynamic _formatSelectedValues(dynamic selectedValues) {
    if (!widget.splitKey) {
      return selectedValues;
    }

    if (selectedValues is List) {
      final formatted = selectedValues.map((item) => _formatSingleValue(item)).toList();
      // Debug: print('🔄 CoreSelect formatted list: $formatted');
      return formatted;
    } else if (selectedValues != null) {
      final formatted = _formatSingleValue(selectedValues);
      // Debug: print('🔄 CoreSelect formatted single: $formatted');
      return formatted;
    }

    return selectedValues;
  }

  /// Format a single value for splitKey cases
  dynamic _formatSingleValue(dynamic value) {
    if (!widget.splitKey) {
      return value;
    }

    if (value is Map) {
      // Check if already formatted (has userPermission wrapper)
      if (value.containsKey('userPermission')) {
        // Debug: print('🔄 Already formatted: $value');
        return value; // Already formatted, return as-is
      }

      // Format raw option to userPermission wrapper
      final formatted = {
        'userPermission': {
          'id': value['id'] ?? value['userPermissionId'] ?? '',
          'name': value['name'] ?? value['permissionName'] ?? '',
          // Copy all other fields
          ...value.entries.where((entry) => 
            entry.key != 'id' && 
            entry.key != 'name' && 
            entry.key != 'userPermissionId' && 
            entry.key != 'permissionName'
          ).fold<Map<String, dynamic>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        }
      };
      // Debug: print('🔄 Formatted raw option: $value -> $formatted');
      return formatted;
    } else if (value is String) {
      // If value is string (ID), create userPermission object with ID
      final formatted = {
        'userPermission': {
          'id': value,
          'name': value, // Fallback name
        }
      };
      // Debug: print('🔄 Formatted string: $value -> $formatted');
      return formatted;
    }

    return value;
  }



  /// Build the floating label with required indicator
  Widget? _buildFloatingLabel() {
    String labelText = widget.label ?? _getDefaultLabel();
    if (labelText.isEmpty) return null;

    return FloatingLabel(
      labelText: labelText,
      isRequired: widget.required,
      isDisabled: _isDisabled,
    );
  }

  /// Build info row similar to _CoreInfoRow in core_list_item_card
  Widget _buildInfoRow(String label, String value) {
    return InfoRowWidget(
      label: label,
      value: value,
    );
  }

  /// Show multiple selection popup with checkboxes
  void _showMultipleSelectionPopup() {
    // Convert current selection to List if not already
    List<dynamic> currentSelection = [];
    if (_selectedValue is List) {
      currentSelection = List.from(_selectedValue);
    } else if (_selectedValue != null) {
      currentSelection = [_selectedValue];
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return MultipleSelectionDialog(
          options: _options,
          selectedValues: currentSelection,
          label: widget.label,
          moreDisplay: widget.moreDisplay,
          onValuesSelected: (selectedValues) {
            final formattedValues = _formatSelectedValues(selectedValues);
            setState(() {
              _selectedValue = formattedValues;
            });
            widget.onChanged?.call(formattedValues);
          },
          getDisplayText: _getDisplayText, // Use dropdownDisplay for popup options
          getOptionValue: _getOptionValue,
          compareValues: _compareValues,
          buildInfoRow: _buildInfoRow,
          getDefaultLabel: _getDefaultLabel,
        );
      },
    );
  }

  void _showDropdownPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return DropdownDialog(
          options: _options,
          selectedValue: _selectedValue,
          label: widget.label,
          moreDisplay: widget.moreDisplay,
          onValueSelected: (value) {
            final formattedValue = _formatSelectedValues(value);
            setState(() {
              _selectedValue = formattedValue;
            });
            widget.onChanged?.call(formattedValue);
          },
          getDisplayText: _getDisplayText, // Use dropdownDisplay for popup options
          getOptionValue: _getOptionValue,
          compareValues: _compareValues,
          buildInfoRow: _buildInfoRow,
          getDefaultLabel: _getDefaultLabel,
        );
      },
    );
  }

  void _handleValueChange(dynamic value) {
    final formattedValue = _formatSelectedValues(value);
    setState(() {
      _selectedValue = formattedValue;
    });
    widget.onChanged?.call(formattedValue);
  }

  void _handleClear() {
    setState(() {
      _selectedValue = widget.type == CoreSelectType.multiple ? [] : null;
    });
    widget.onChanged?.call(widget.type == CoreSelectType.multiple ? [] : null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14), // Match CoreInput margin
      child: !_isInitialized
          ? Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : switch (widget.type) {
              CoreSelectType.select => SelectTypeBuilder(
                selectedValue: _selectedValue,
                filteredOptions: _filteredOptions,
                isDisabled: _isDisabled,
                hintText: widget.hintText,
                floatingLabel: _buildFloatingLabel(),
                getDisplayText: _getInputDisplayText, // Always use input display for selected values
                getOptionValue: _getOptionValue,
                onChanged: _handleValueChange,
                loadOptionsFromAPI: _loadOptionsFromAPI,
              ),
              CoreSelectType.dropdown => DropdownTypeBuilder(
                selectedValue: _selectedValue,
                isDisabled: _isDisabled,
                hintText: widget.hintText,
                floatingLabel: _buildFloatingLabel(),
                getDisplayText: _getInputDisplayText, // Always use input display for selected values
                onTap: () async {
                  if (widget.data is String && _options.isEmpty) {
                    await _loadOptionsFromAPI();
                  }
                  _showDropdownPopup();
                },
                onClear: _handleClear,
              ),
              CoreSelectType.multiple => MultipleTypeBuilder(
                selectedValue: _selectedValue,
                isDisabled: _isDisabled,
                hintText: widget.hintText,
                floatingLabel: _buildFloatingLabel(),
                getDisplayText: _getInputDisplayText, // Always use input display for selected values
                onTap: () async {
                  if (widget.data is String && _options.isEmpty) {
                    await _loadOptionsFromAPI();
                  }
                  _showMultipleSelectionPopup();
                },
                onClear: _handleClear,
              ),
            },
    );
  }
}
