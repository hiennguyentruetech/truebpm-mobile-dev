import 'package:flutter/material.dart';
import '../core_select_utils.dart';

import '../components/option_card.dart';

/// Dropdown Popup Dialog
class DropdownDialog extends StatefulWidget {
  final List<dynamic> options;
  final dynamic selectedValue;
  final String? label;
  final List<Map<String, String>>? moreDisplay;
  final Function(dynamic) onValueSelected;
  final String Function(dynamic) getDisplayText;
  final dynamic Function(dynamic) getOptionValue;
  final bool Function(dynamic, dynamic) compareValues;
  final Widget Function(String, String) buildInfoRow;
  final String Function() getDefaultLabel;

  const DropdownDialog({
    super.key,
    required this.options,
    required this.selectedValue,
    this.label,
    this.moreDisplay,
    required this.onValueSelected,
    required this.getDisplayText,
    required this.getOptionValue,
    required this.compareValues,
    required this.buildInfoRow,
    required this.getDefaultLabel,
  });

  @override
  State<DropdownDialog> createState() => _DropdownDialogState();
}

class _DropdownDialogState extends State<DropdownDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterOptions(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        final searchLower = searchText.toLowerCase();
        final hasMoreDisplay = widget.moreDisplay != null && widget.moreDisplay!.isNotEmpty;

        _filteredOptions = widget.options.where((option) {
          final displayText = widget.getDisplayText(option).toLowerCase();

          // Search in main display text
          if (displayText.contains(searchLower)) {
            return true;
          }

          // Also search in moreDisplay fields
          if (hasMoreDisplay && option is Map) {
            for (final field in widget.moreDisplay!) {
              final key = field['key'] ?? '';
              final value = option[key]?.toString().toLowerCase() ?? '';
              if (value.contains(searchLower)) {
                return true;
              }
            }
          }

          return false;
        }).toList();
      }
    });
  }

  Widget _buildOptionCard(dynamic option, int index, bool isSelected, VoidCallback onTap, bool hasMoreDisplay) {
    // Get the main display value (code)
    String codeValue = widget.getDisplayText(option);

    // Build additional fields from moreDisplay
    List<MapEntry<String, String>> additionalFields = [];

    if (hasMoreDisplay && option is Map) {
      for (final field in widget.moreDisplay!) {
        final key = field['key'] ?? '';
        final label = field['label'] ?? key;
        final raw = CoreSelectUtils.getByPath(option, key);
        final value = (raw == null || raw.toString().isEmpty) ? '-' : raw.toString();
        additionalFields.add(MapEntry(label, value));
      }
    }

    return OptionCardWithAnimation(
      option: option,
      index: index,
      isSelected: isSelected,
      onTap: onTap,
      hasMoreDisplay: hasMoreDisplay,
      codeValue: codeValue,
      additionalFields: additionalFields,
      buildInfoRow: widget.buildInfoRow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMoreDisplay = widget.moreDisplay != null && widget.moreDisplay!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Listener(
        onPointerDown: (_) {
          // Unfocus search input when tapping anywhere on the popup
          _searchFocusNode.unfocus();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Beautiful header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.list_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select ${widget.label ?? widget.getDefaultLabel()}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.options.length} options available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search field with elegant design
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  onChanged: _filterOptions,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search options...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return value.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterOptions('');
                                },
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                  ),
                ),
              ),

              // Options list with core_list_item style
              Expanded(
                child: _filteredOptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No options found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _filteredOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final option = _filteredOptions[index];
                          final optionValue = widget.getOptionValue(option);
                          final isSelected = widget.compareValues(widget.selectedValue, optionValue);

                          return _buildOptionCard(option, index + 1, isSelected, () {
                            // Unfocus search input when selecting an option
                            _searchFocusNode.unfocus();
                            widget.onValueSelected(optionValue);
                            Navigator.of(context).pop();
                          }, hasMoreDisplay);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
