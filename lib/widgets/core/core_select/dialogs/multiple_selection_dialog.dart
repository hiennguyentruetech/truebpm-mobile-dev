import 'package:flutter/material.dart';
import '../components/multiple_option_card.dart';

/// Multiple Selection Popup Dialog
class MultipleSelectionDialog extends StatefulWidget {
  final List<dynamic> options;
  final List<dynamic> selectedValues;
  final String? label;
  final List<Map<String, String>>? moreDisplay;
  final Function(List<dynamic>) onValuesSelected;
  final String Function(dynamic) getDisplayText;
  final dynamic Function(dynamic) getOptionValue;
  final bool Function(dynamic, dynamic) compareValues;
  final Widget Function(String, String) buildInfoRow;
  final String Function() getDefaultLabel;

  const MultipleSelectionDialog({
    super.key,
    required this.options,
    required this.selectedValues,
    this.label,
    this.moreDisplay,
    required this.onValuesSelected,
    required this.getDisplayText,
    required this.getOptionValue,
    required this.compareValues,
    required this.buildInfoRow,
    required this.getDefaultLabel,
  });

  @override
  State<MultipleSelectionDialog> createState() => _MultipleSelectionDialogState();
}

class _MultipleSelectionDialogState extends State<MultipleSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _filteredOptions = [];
  List<dynamic> _currentSelection = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);
    _currentSelection = List.from(widget.selectedValues);
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
          
          if (displayText.contains(searchLower)) {
            return true;
          }
          
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

  bool _isSelected(dynamic option) {
    final optionValue = widget.getOptionValue(option);
    return _currentSelection.any((selected) => widget.compareValues(selected, optionValue));
  }

  void _toggleSelection(dynamic option) {
    final optionValue = widget.getOptionValue(option);
    setState(() {
      if (_isSelected(option)) {
        _currentSelection.removeWhere((selected) => widget.compareValues(selected, optionValue));
      } else {
        _currentSelection.add(optionValue);
      }
    });
    // Unfocus search input when selecting an option
    _searchFocusNode.unfocus();
  }

  void _selectAll() {
    setState(() {
      _currentSelection = _filteredOptions.map((option) => widget.getOptionValue(option)).toList();
    });
  }

  void _clearAll() {
    setState(() {
      _currentSelection.clear();
    });
  }

  Widget _buildMultipleOptionCard(dynamic option, int index, bool isSelected, VoidCallback onToggle, bool hasMoreDisplay) {
    // Get the main display value (code)
    String codeValue = widget.getDisplayText(option);
    
    // Build additional fields from moreDisplay
    List<MapEntry<String, String>> additionalFields = [];
    
    if (hasMoreDisplay && option is Map) {
      for (final field in widget.moreDisplay!) {
        final key = field['key'] ?? '';
        final label = field['label'] ?? key;
        final value = option[key]?.toString() ?? '-';
        additionalFields.add(MapEntry(label, value));
      }
    }

    return MultipleOptionCard(
      option: option,
      index: index,
      isSelected: isSelected,
      onToggle: onToggle,
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
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.checklist_rounded,
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
                            '${_currentSelection.length} of ${widget.options.length} selected',
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
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 80),
                        child: ElevatedButton.icon(
                          onPressed: _selectAll,
                          icon: const Icon(Icons.select_all, size: 14),
                          label: const Text(
                            'Select All',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 80),
                        child: ElevatedButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.close_rounded, size: 14),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 80),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onValuesSelected(_currentSelection);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text(
                            'Done',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search field
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
              
              // Options list
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
                            const SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final option = _filteredOptions[index];
                          final isSelected = _isSelected(option);
                          
                          return _buildMultipleOptionCard(option, index + 1, isSelected, () {
                            _toggleSelection(option);
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
