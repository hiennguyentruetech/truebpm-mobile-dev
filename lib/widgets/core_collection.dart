import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Core Collection Widget for dynamic arrays/lists
/// Allows adding, removing, and editing items with dynamic fields
/// Supports two edit modes: 'inline' (direct editing) and 'modal' (tap to open popup)
class CoreCollection extends StatefulWidget {
  final String dataKey;
  final Map<String, dynamic> itemDetail;
  final String label;
  final String? hintText;
  final List<Map<String, dynamic>> children; // Field configurations for each item
  final String? itemLabel; // Label for each item (e.g., "Reason")
  final String? addButtonText; // Custom text for add button
  final bool allowAdd;
  final bool allowRemove;
  final int? maxItems;
  final int? minItems;
  final Function(List<Map<String, dynamic>>) onChanged;
  final bool required;
  final String editMode; // 'inline' or 'modal'
  final Map<String, dynamic>? summary; // Dynamic summary configuration
  final bool useFloatingAddButton; // Use floating add button instead of regular button
  final bool useAddFirstList; // Add new items to the beginning of list instead of end
  final Map<String, dynamic>? totalSummary; // Configuration for total summary view

  const CoreCollection({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    required this.label,
    this.hintText,
    required this.children,
    this.itemLabel,
    this.addButtonText,
    this.allowAdd = true,
    this.allowRemove = true,
    this.maxItems,
    this.minItems,
    required this.onChanged,
    this.required = false,
    this.editMode = 'inline',
    this.summary,
    this.useFloatingAddButton = false,
    this.useAddFirstList = false,
    this.totalSummary,
  });

  @override
  State<CoreCollection> createState() => _CoreCollectionState();
}

class _CoreCollectionState extends State<CoreCollection> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _items;
  Map<int, AnimationController> _scaleControllers = {};
  Map<int, Animation<double>> _scaleAnimations = {};
  // Removed unused FAB animation since we moved to screen-level FAB
  
  @override
  void initState() {
    super.initState();
    _initializeItems();
  }
  
  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  void didUpdateWidget(CoreCollection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemDetail != widget.itemDetail) {
      _initializeItems();
    }
  }
  
  void _initializeItems() {
    // Get current data from itemDetail
    final moduleData = widget.itemDetail['value'] ?? {};
    final currentData = moduleData[widget.dataKey];
    
    if (currentData is List) {
      _items = List<Map<String, dynamic>>.from(
        currentData.map((item) => Map<String, dynamic>.from(item ?? {}))
      );
    } else {
      _items = [];
    }
    
    // Ensure minimum items if specified
    if (widget.minItems != null && _items.length < widget.minItems!) {
      final neededItems = widget.minItems! - _items.length;
      for (int i = 0; i < neededItems; i++) {
        _items.add(<String, dynamic>{});
      }
    }
    
    // Initialize animation controllers for each item
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Dispose existing controllers
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    _scaleControllers.clear();
    _scaleAnimations.clear();
    
    // Create new controllers for current items
    for (int i = 0; i < _items.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      final animation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      _scaleControllers[i] = controller;
      _scaleAnimations[i] = animation;
    }
  }
  
  void _addItem() {
    if (widget.maxItems != null && _items.length >= widget.maxItems!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxItems} items allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      if (widget.useAddFirstList) {
        _items.insert(0, <String, dynamic>{});
      } else {
        _items.add(<String, dynamic>{});
      }
      _initializeAnimations(); // Reinitialize animations for new item count
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }
  
  void _removeItem(int index) {
    if (widget.minItems != null && _items.length <= widget.minItems!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum ${widget.minItems} items required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _items.removeAt(index);
      _initializeAnimations(); // Reinitialize animations for new item count
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }
  
  void _updateItem(int index, String key, dynamic value) {
    setState(() {
      _items[index][key] = value;
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }
  
  void _notifyChange() {
    widget.onChanged(_items);
  }

  /// Check if field is disabled
  bool get _isDisabled {
    return widget.itemDetail['attribute']?['disabled']?[widget.dataKey] == true;
  }

  /// Check if field is hidden
  bool get _isHidden {
    return widget.itemDetail['attribute']?['hidden']?[widget.dataKey] == true;
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if hidden
    if (_isHidden) {
      return const SizedBox.shrink();
    }

    if (widget.useFloatingAddButton) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection Header
          _buildCollectionHeader(),
          const SizedBox(height: 0),

          // Total Summary (if configured)
          if (widget.totalSummary != null)
            _buildTotalSummary(),

          // Items List
          if (_items.isEmpty)
            _buildEmptyState()
          else
            ...(_items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildCollectionItem(index, item);
            })),

          // Add some bottom padding to avoid FAB overlap
          const SizedBox(height: 80),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collection Header
        _buildCollectionHeader(),
        const SizedBox(height: 8),

        // Total Summary (if configured)
        if (widget.totalSummary != null)
          _buildTotalSummary(),

        // Items List
        if (_items.isEmpty)
          _buildEmptyState()
        else
          ...(_items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildCollectionItem(index, item);
          })),

        // Add Button
        if (widget.allowAdd && !_isDisabled && (widget.maxItems == null || _items.length < widget.maxItems!))
          _buildAddButton(),
      ],
    );
  }
  
  Widget _buildCollectionHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade500],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.view_list_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label + (widget.required ? ' *' : ''),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_items.length} items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            widget.hintText ?? 'No ${widget.itemLabel?.toLowerCase() ?? 'items'} added yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCollectionItem(int index, Map<String, dynamic> item) {
    if (widget.editMode == 'modal') {
      return _buildModalCollectionItem(index, item);
    } else {
      return _buildInlineCollectionItem(index, item);
    }
  }
  
  Widget _buildInlineCollectionItem(int index, Map<String, dynamic> item) {
    final isLastItem = index == _items.length - 1;
    return Container(
      margin: EdgeInsets.only(bottom: isLastItem ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: _isDisabled ? null : () => _onItemTap(index),
          child: AnimatedBuilder(
            animation: _scaleAnimations[index] ?? const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index]?.value ?? 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Header
                    _buildItemHeader(index),
                    
                    // Item Fields
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                      child: Column(
                        children: _buildItemFields(index, item),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  void _onItemTap(int index) {
    // Only use scale animation for inline mode since modal mode uses TouchableOpacity
    if (widget.editMode == 'inline') {
      final controller = _scaleControllers[index];
      if (controller != null) {
        controller.forward().then((_) {
          controller.reverse();
        });
      }
    }
  }

  Widget _buildModalCollectionItem(int index, Map<String, dynamic> item) {
    final isLastItem = index == _items.length - 1;
    return Container(
      margin: EdgeInsets.only(bottom: isLastItem ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TouchableOpacity(
        onTap: _isDisabled ? null : () {
          _onItemTap(index);
          _showEditModal(index, item);
        },
        opacity: 0.4, // Touch animation opacity
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Header
              _buildItemHeader(index, showEditIcon: true),
              
              // Item Summary
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                child: _buildItemSummary(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildItemHeader(int index, {bool showEditIcon = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.itemLabel ?? 'Item ${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          // Fixed width container for icons to ensure alignment
          SizedBox(
            width: 80, // Fixed width for icon area
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showEditIcon)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _isDisabled ? Colors.grey.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.edit_outlined,
                        color: _isDisabled ? Colors.grey.shade400 : Colors.blue.shade700,
                        size: 16,
                      ),
                    ),
                  ),
                if (widget.allowRemove)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isDisabled ? Colors.grey.shade100 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _isDisabled ? null : () => _removeItem(index),
                      icon: const Icon(Icons.delete_outline),
                      color: _isDisabled ? Colors.grey.shade400 : Colors.red.shade600,
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildItemFields(int index, Map<String, dynamic> item) {
    // Create a temporary itemDetail for this specific item
    final itemItemDetail = {
      'value': item,
      'attribute': widget.itemDetail['attribute'] ?? {},
    };

    // Merge parent context (current collection's parent item/module) with this item
    final parentCtx = widget.itemDetail['value'];
    final Map<String, dynamic> mergedCtx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ...item,
    };
    
    // Use children as-is; dynamic visibility and data templates are handled in CoreDynamicFields
    final List<Map<String, dynamic>> fieldConfigs = List<Map<String, dynamic>>.from(widget.children);
    
    final fields = CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) => _updateItem(index, key, value),
    );
    
    // Add margin to first field and remove margin from last field
    final List<Widget> wrappedFields = [];
    for (int i = 0; i < fields.length; i++) {
      if (i == 0) {
        // First field with top margin
        wrappedFields.add(
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: fields[i],
          ),
        );
      } else if (i == fields.length - 1) {
        // Last field without bottom margin
        wrappedFields.add(
          Container(
            margin: const EdgeInsets.only(bottom: 0), // Negative margin to compensate default field margin
            child: fields[i],
          ),
        );
      } else {
        // Middle fields as-is
        wrappedFields.add(fields[i]);
      }
    }
    
    return wrappedFields;
  }
  
  Widget _buildItemSummary(Map<String, dynamic> item) {
    final summaryCfg = widget.summary;
    if (item.isEmpty) return _buildTapToEditHint();

    // Build context map: parent + item
    final parentCtx = widget.itemDetail['value'];
    final Map<String, dynamic> ctx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ...item,
    };

    final List<Widget> rows = [];

    final List fields = (summaryCfg != null && summaryCfg['fields'] is List)
        ? (summaryCfg['fields'] as List)
        : widget.children.take(2).toList();

    // Get layout from summary config, default to 'row'
    final String defaultLayout = summaryCfg?['layout']?.toString() ?? 'row';

    for (final f in fields) {
      final Map<String, dynamic> conf = Map<String, dynamic>.from(f as Map);
      if (conf.containsKey('visibleWhen') && !_evaluateVisibility(conf['visibleWhen'], ctx)) continue;
      final String keyPath = conf['key']?.toString() ?? '';
      if (keyPath.isEmpty) continue;

      dynamic raw = _getByPath(ctx, keyPath);
      if (raw == null) continue;
      if (raw is Map && conf['display'] != null) raw = raw[conf['display']];
      String value = raw?.toString() ?? '';
      if (value.isEmpty || value == 'null') continue;
      
      // Check if this is a datetime field and format accordingly
      final String? widget = conf['widget']?.toString();
      final String? type = conf['type']?.toString();
      final String? datetimeType = conf['datetimeType']?.toString();
      if ((widget == 'datetime' || type == 'date') && value.isNotEmpty) {
        value = _formatDateTimeValue(value, datetimeType ?? 'date', conf['displayFormat']?.toString());
      }

      // Check if this is a number field and format accordingly
      if ((type == 'number' || type == 'currency') && value.isNotEmpty) {
        final decimalPlaces = conf['decimalPlaces'] as int? ?? 0;
        value = _formatNumberDisplay(value, decimalPlaces: decimalPlaces);
      }
      
      final String label = conf['label']?.toString() ?? keyPath.split('.').last;
      final String? suffix = conf['suffix']?.toString();
      if (suffix != null && suffix.isNotEmpty && widget != 'datetime') {
        value = '$value$suffix';
      }

      // Get layout from individual field config, fallback to summary default, then 'row'
      final String fieldLayout = conf['layout']?.toString() ?? defaultLayout;

      rows.add(_buildStackedRow(
        label,
        value,
        labelColor: _parseColor(conf['labelColor']) ?? Colors.grey.shade700,
        valueColor: _parseColor(conf['valueColor']) ?? Colors.black87,
        bgColor: _parseColor(conf['bgColor']) ?? Colors.white,
        borderColor: _parseColor(conf['borderColor']) ?? Colors.grey.shade200,
        layout: fieldLayout, // Use field-specific layout
      ));
    }

    return rows.isEmpty
        ? _buildTapToEditHint()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          );
  }

  // Hint shown when an item has no data yet in modal mode
  Widget _buildTapToEditHint() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.touch_app_outlined,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to add details',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Click here to fill in the information',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.blue.shade400,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildStackedRow(String label, String value, {Color? labelColor, Color? valueColor, Color? bgColor, Color? borderColor, String? layout}) {
    // Support both 'stacked' (default) and 'row' layouts
    if (layout == 'row') {
      return _buildHorizontalRow(label, value, 
        labelColor: labelColor, 
        valueColor: valueColor, 
        bgColor: bgColor, 
        borderColor: borderColor
      );
    }
    
    // Default stacked layout
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label section with full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              border: Border.all(color: borderColor ?? Colors.grey.shade300),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: labelColor ?? Colors.grey.shade700,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          // Value section with full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              border: Border(
                left: BorderSide(color: borderColor ?? Colors.grey.shade300),
                right: BorderSide(color: borderColor ?? Colors.grey.shade300),
                bottom: BorderSide(color: borderColor ?? Colors.grey.shade300),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRow(String label, String value, {Color? labelColor, Color? valueColor, Color? bgColor, Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: IntrinsicHeight( // Make both containers have same height
        child: Row(
          children: [
            // Label section with 30% width
            Expanded(
              flex: 37, // 30% width (3/10)
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    bottomLeft: Radius.circular(0),
                  ),
                  border: Border.all(color: borderColor ?? Colors.grey.shade300),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: labelColor ?? Colors.grey.shade700,
                      letterSpacing: 0.2,
                      height: 1.3, // Match value text height
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3, // Allow same maxLines as value
                  ),
                ),
              ),
            ),
            // Value section with 70% width
            Expanded(
              flex: 63, // 70% width (7/10)
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                  border: Border(
                    top: BorderSide(color: borderColor ?? Colors.grey.shade300),
                    right: BorderSide(color: borderColor ?? Colors.grey.shade300),
                    bottom: BorderSide(color: borderColor ?? Colors.grey.shade300),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format datetime value for display in collection summary
  String _formatDateTimeValue(String value, String? datetimeType, String? displayFormat) {
    try {
      DateTime? dateTime;
      
      // Try to parse the datetime string and force UTC handling
      if (value.contains('T')) {
        // ISO format: 2023-12-25T10:30:00.000Z
        dateTime = DateTime.tryParse(value);
        if (dateTime != null) {
          // If it's not already UTC, treat it as UTC to avoid timezone conversion
          if (!dateTime.isUtc) {
            dateTime = DateTime.utc(
              dateTime.year,
              dateTime.month, 
              dateTime.day,
              dateTime.hour,
              dateTime.minute,
              dateTime.second,
              dateTime.millisecond,
            );
          }
        }
      } else if (value.contains('/')) {
        // Format: 25/12/2023 or 25/12/2023 10:30
        final parts = value.split(' ');
        final datePart = parts[0];
        final timePart = parts.length > 1 ? parts[1] : null;
        
        final dateComponents = datePart.split('/');
        if (dateComponents.length == 3) {
          final day = int.tryParse(dateComponents[0]);
          final month = int.tryParse(dateComponents[1]);
          final year = int.tryParse(dateComponents[2]);
          
          if (day != null && month != null && year != null) {
            if (timePart != null) {
              final timeComponents = timePart.split(':');
              final hour = int.tryParse(timeComponents[0]) ?? 0;
              final minute = timeComponents.length > 1 ? (int.tryParse(timeComponents[1]) ?? 0) : 0;
              // Create as UTC to avoid timezone issues
              dateTime = DateTime.utc(year, month, day, hour, minute);
            } else {
              // Create as UTC to avoid timezone issues  
              dateTime = DateTime.utc(year, month, day);
            }
          }
        }
      } else {
        // Try direct parsing and force UTC
        dateTime = DateTime.tryParse(value);
        if (dateTime != null && !dateTime.isUtc) {
          dateTime = DateTime.utc(
            dateTime.year,
            dateTime.month, 
            dateTime.day,
            dateTime.hour,
            dateTime.minute,
            dateTime.second,
            dateTime.millisecond,
          );
        }
      }
      
      if (dateTime == null) return value; // Return original if parsing fails
      
      // Format based on datetime type - always display as intended UTC time
      switch (datetimeType) {
        case 'time':
          return DateFormat('HH:mm').format(dateTime.toUtc());
        case 'date':
          return displayFormat != null && displayFormat == 'ddMMyyyy'
              ? DateFormat('dd/MM/yyyy').format(dateTime.toUtc())
              : DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        case 'datetime':
          return displayFormat != null && displayFormat == 'ddMMyyyy'
              ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc())
              : DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
        case 'daterange':
          // For daterange, this would be handled differently
          return DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        default:
          // Default datetime format - display UTC time
          return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
      }
    } catch (e) {
      // If any error occurs, return original value
      return value;
    }
  }

  // Helpers
  static dynamic _getByPath(Map<String, dynamic> map, String path) {
    dynamic curr = map;
    for (final segment in path.split('.')) {
      if (segment == 'length' && curr is List) {
        return curr.length;
      }
      if (curr is Map && curr.containsKey(segment)) {
        curr = curr[segment];
      } else {
        return null;
      }
    }
    return curr;
  }

  static bool _evaluateVisibility(dynamic visibleWhen, Map<String, dynamic> context) {
    final List conditions = visibleWhen is List ? visibleWhen : [visibleWhen];
    for (final cond in conditions) {
      if (cond is! Map) continue;
      final String key = cond['key']?.toString() ?? '';
      final String op = (cond['operator'] ?? cond['op'] ?? 'eq').toString();
      final dynamic expected = cond['value'];
      final dynamic actual = _getByPath(context, key);
      switch (op) {
        case 'eq':
          if (actual != expected) return false;
          break;
        case 'ne':
          if (actual == expected) return false;
          break;
        case 'in':
          if (expected is List) {
            if (!expected.contains(actual)) return false;
          } else {
            return false;
          }
          break;
        case 'notEmpty':
          if (actual == null || (actual is String && actual.trim().isEmpty)) return false;
          break;
        case 'empty':
          if (!(actual == null || (actual is String && actual.trim().isEmpty))) return false;
          break;
        case 'exists':
          if (actual == null) return false;
          break;
        case 'notExists':
          if (actual != null) return false;
          break;
        default:
          break;
      }
    }
    return true;
  }

  Color? _parseColor(dynamic color) {
    if (color == null) return null;
    if (color is Color) return color;
    if (color is int) return Color(color);
    if (color is String) {
      String hex = color.trim();
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      final intVal = int.tryParse(hex, radix: 16);
      if (intVal != null) return Color(intVal);
    }
    return null;
  }

  void _showEditModal(int index, Map<String, dynamic> item) {
    // Create a copy of the item for editing
    final editingItem = Map<String, dynamic>.from(item);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside input fields
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.85,
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
                    // Beautiful header with gradient (like CoreSelect)
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
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
                                  'Edit ${widget.itemLabel ?? 'Item'} ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.children.length} fields to edit',
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
                    
                    // Modal Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: _buildModalItemFields(editingItem, setModalState),
                        ),
                      ),
                    ),
                    
                    // Action toolbar at bottom (like CoreSelect)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _items[index] = editingItem;
                                });
                                _notifyChange();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  List<Widget> _buildModalItemFields(Map<String, dynamic> item, StateSetter setModalState) {
    // Create a temporary itemDetail for this specific item
    final itemItemDetail = {
      'value': item,
      'attribute': widget.itemDetail['attribute'] ?? {},
    };
    
    // Merge parent context (current collection's parent item/module) with this item
    final parentCtx = widget.itemDetail['value'];
    final Map<String, dynamic> mergedCtx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ...item,
    };
    
    // Use children as-is; dynamic visibility and data templates are handled in CoreDynamicFields
    final List<Map<String, dynamic>> fieldConfigs = List<Map<String, dynamic>>.from(widget.children);
    
    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) {
        setModalState(() {
          item[key] = value;
        });
      },
    );
  }
  
  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      child: OutlinedButton.icon(
        onPressed: _isDisabled ? null : _addItem,
        icon: Icon(
          Icons.add,
          color: _isDisabled ? Colors.grey.shade400 : Colors.blue.shade700,
        ),
        label: Text(
          widget.addButtonText ?? 'Add ${widget.itemLabel ?? 'Item'}',
          style: TextStyle(
            color: _isDisabled ? Colors.grey.shade400 : Colors.blue.shade700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _isDisabled ? Colors.grey.shade400 : Colors.blue.shade700,
          side: BorderSide(
            color: _isDisabled ? Colors.grey.shade300 : Colors.blue.shade300,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }



  Widget _buildTotalSummary() {
    if (widget.totalSummary == null || _items.isEmpty) {
      return const SizedBox.shrink();
    }

    final config = widget.totalSummary!;
    final totalKey = config['key'] as String? ?? 'total';
    final label = config['label'] as String? ?? 'Total';
    // format not needed since we use _formatNumberDisplay
    final suffix = config['suffix'] as String? ?? '';
    final bgColor = config['bgColor'] as String? ?? '#E8F5E8';
    final borderColor = config['borderColor'] as String? ?? '#A5D6A7';
    final labelColor = config['labelColor'] as String? ?? '#2E7D32';
    final valueColor = config['valueColor'] as String? ?? '#1B5E20';

    // Calculate total from all items
    double total = 0.0;
    for (final item in _items) {
      final value = item[totalKey];
      if (value is num) {
        total += value.toDouble();
      } else if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          total += parsed;
        }
      }
    }

    // Format the total using our custom EU-style formatter with decimalPlaces = 0
    String formattedTotal = _formatNumberDisplay(total, decimalPlaces: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _hexToColor(bgColor),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hexToColor(borderColor),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _hexToColor(labelColor),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$formattedTotal$suffix',
            style: TextStyle(
              color: _hexToColor(valueColor),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Format number for display (EU style: thousand '.' and decimal ',')
  String _formatNumberDisplay(dynamic value, {int decimalPlaces = -1}) {
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
    } else if (s.contains('.') && !s.contains(',') && s.split('.').length == 2) {
      // Treat single dot as decimal separator (common machine format like 342432.0)
      final parts = s.split('.');
      intRaw = parts[0];
      decRaw = parts[1];
    } else {
      // Pure integer or treat dots as thousand separators
      intRaw = s.replaceAll('.', '');
      decRaw = '';
    }

    // Keep digits only
    intRaw = intRaw.replaceAll(RegExp(r'[^0-9]'), '');
    decRaw = decRaw.replaceAll(RegExp(r'[^0-9]'), '');

    if (intRaw.isEmpty) return '';

    // Handle decimal places
    if (decimalPlaces >= 0) {
      if (decimalPlaces == 0 && decRaw.isNotEmpty) {
        // Round based on first decimal digit then drop decimals
        final first = int.tryParse(decRaw[0]) ?? 0;
        if (first >= 5) {
          final intVal = int.parse(intRaw) + 1;
          intRaw = intVal.toString();
        }
        decRaw = '';
      } else if (decimalPlaces > 0) {
        if (decRaw.length > decimalPlaces) {
          decRaw = decRaw.substring(0, decimalPlaces);
        } else if (decRaw.length < decimalPlaces) {
          decRaw = decRaw.padRight(decimalPlaces, '0');
        }
      }
    }

    final grouped = _groupThousands(intRaw);

    if (decimalPlaces > 0 || (decimalPlaces == -1 && decRaw.isNotEmpty)) {
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
}
