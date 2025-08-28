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
    if (value is Map && widget.display != null) {
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

  /// Get display text for an option
  String _getDisplayText(dynamic option) {
    return CoreSelectUtils.getDisplayText(option, widget.display);
  }

  /// Get the actual value from an option
  dynamic _getOptionValue(dynamic option) {
    return CoreSelectUtils.getOptionValue(option, widget.display);
  }

  /// Compare two values for equality (handles objects and primitives)
  bool _compareValues(dynamic value1, dynamic value2) {
    return CoreSelectUtils.compareValues(value1, value2, widget.display);
  }

  /// Get default label from dataKey
  String _getDefaultLabel() {
    return CoreSelectUtils.getDefaultLabel(widget.dataKey);
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
            setState(() {
              _selectedValue = selectedValues;
            });
            widget.onChanged?.call(selectedValues);
          },
          getDisplayText: _getDisplayText,
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
            setState(() {
              _selectedValue = value;
            });
            widget.onChanged?.call(value);
          },
          getDisplayText: _getDisplayText,
          getOptionValue: _getOptionValue,
          compareValues: _compareValues,
          buildInfoRow: _buildInfoRow,
          getDefaultLabel: _getDefaultLabel,
        );
      },
    );
  }

  void _handleValueChange(dynamic value) {
    setState(() {
      _selectedValue = value;
    });
    widget.onChanged?.call(value);
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
                getDisplayText: _getDisplayText,
                getOptionValue: _getOptionValue,
                onChanged: _handleValueChange,
                loadOptionsFromAPI: _loadOptionsFromAPI,
              ),
              CoreSelectType.dropdown => DropdownTypeBuilder(
                selectedValue: _selectedValue,
                isDisabled: _isDisabled,
                hintText: widget.hintText,
                floatingLabel: _buildFloatingLabel(),
                getDisplayText: _getDisplayText,
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
                getDisplayText: _getDisplayText,
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
