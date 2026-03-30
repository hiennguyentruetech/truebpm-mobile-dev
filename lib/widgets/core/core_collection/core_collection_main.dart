part of 'core_collection.dart';

class CoreCollection extends StatefulWidget {
  final String dataKey;
  final Map<String, dynamic> itemDetail;
  final String label;
  final String? hintText;
  final List<Map<String, dynamic>>
  children; // Field configurations for each item
  final String? itemLabel; // Label for each item (e.g., "Reason")
  final String?
  titleTemplate; // Dynamic template for item header e.g. '{travelRequest.code}'
  final String? addButtonText; // Custom text for add button
  final bool allowAdd;
  final bool allowRemove;
  final int? maxItems;
  final int? minItems;
  final Function(List<Map<String, dynamic>>) onChanged;
  final bool required;
  final String editMode; // 'inline' or 'modal'
  final Map<String, dynamic>? summary; // Dynamic summary configuration
  final bool
  useFloatingAddButton; // Use floating add button instead of regular button
  final bool
  useAddFirstList; // Add new items to the beginning of list instead of end
  final Map<String, dynamic>?
  totalSummary; // Configuration for total summary view

  const CoreCollection({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    required this.label,
    this.hintText,
    required this.children,
    this.itemLabel,
    this.titleTemplate,
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

class _CoreCollectionState extends State<CoreCollection>
    with TickerProviderStateMixin {
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
        currentData.map((item) => Map<String, dynamic>.from(item ?? {})),
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
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

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
          if (widget.totalSummary != null) _buildTotalSummary(),

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
        if (widget.totalSummary != null) _buildTotalSummary(),

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
        if (widget.allowAdd &&
            !_isDisabled &&
            (widget.maxItems == null || _items.length < widget.maxItems!))
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            widget.hintText ??
                'No ${widget.itemLabel?.toLowerCase() ?? 'items'} added yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
            animation:
                _scaleAnimations[index] ?? const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index]?.value ?? 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Header
                    _buildItemHeader(index, item, showEditIcon: true),

                    // Item Fields
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                      child: Column(children: _buildItemFields(index, item)),
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
        onTap: _isDisabled
            ? null
            : () {
                _onItemTap(index);
                _showEditModal(index, item);
              },
        opacity: 0.4, // Touch animation opacity
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Header
              _buildItemHeader(index, item, showEditIcon: true),

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

  Widget _buildItemHeader(
    int index,
    Map<String, dynamic> item, {
    bool showEditIcon = false,
  }) {
    String resolvedTitle = widget.itemLabel ?? 'Item ${index + 1}';
    if (widget.titleTemplate != null &&
        widget.titleTemplate!.trim().isNotEmpty) {
      resolvedTitle =
          _resolveTemplate(widget.titleTemplate!, item) ?? resolvedTitle;
    }
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
              resolvedTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                      color: _isDisabled
                          ? Colors.grey.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.edit_outlined,
                        color: _isDisabled
                            ? Colors.grey.shade400
                            : Colors.blue.shade700,
                        size: 16,
                      ),
                    ),
                  ),
                if (widget.allowRemove)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isDisabled
                          ? Colors.grey.shade100
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _isDisabled ? null : () => _removeItem(index),
                      icon: const Icon(Icons.delete_outline),
                      color: _isDisabled
                          ? Colors.grey.shade400
                          : Colors.red.shade600,
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
    final List<Map<String, dynamic>> fieldConfigs =
        List<Map<String, dynamic>>.from(widget.children);

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
          Padding(padding: const EdgeInsets.only(top: 11), child: fields[i]),
        );
      } else if (i == fields.length - 1) {
        // Last field without bottom margin
        wrappedFields.add(
          Container(
            margin: const EdgeInsets.only(
              bottom: 0,
            ), // Negative margin to compensate default field margin
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
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400,
                            ],
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
                            children: _buildModalItemFields(
                              editingItem,
                              setModalState,
                            ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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

  List<Widget> _buildModalItemFields(
    Map<String, dynamic> item,
    StateSetter setModalState,
  ) {
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
    final List<Map<String, dynamic>> fieldConfigs =
        List<Map<String, dynamic>>.from(widget.children);

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) {
        setModalState(() {
          item[key] = value;
          // Track manual override for total when user edits directly
          if (key == 'total') {
            item['_manualTotal'] = true;
          }
          // Inline auto-fill logic for specific dependencies
          if (key == 'travelRequest' && value is Map) {
            // Do NOT auto-set date field anymore.
            // Instead, store a helper defaultDate for the date picker to use on open.
            final startDate = value['startDate'];
            if (startDate != null) {
              DateTime? parsed;
              if (startDate is DateTime)
                parsed = startDate;
              else if (startDate is String)
                parsed =
                    DateTime.tryParse(startDate) ?? _tryParseDate(startDate);
              if (parsed != null) {
                item['_defaultDate_date'] = parsed.toIso8601String();
              } else {
                item['_defaultDate_date'] = startDate.toString();
              }
            }
          }
          if (key == 'locationObject' || key == 'expenseType') {
            final expenseType = item['expenseType'];
            final locationObj = item['locationObject'];
            if (expenseType is Map && locationObj is Map) {
              final expenseTypeId = expenseType['id'];
              final perDiemAmount = locationObj['perDiemAmount'];
              if (perDiemAmount != null &&
                  expenseTypeId == '225F3E9E-16CC-460D-B0F6-42167AC41EA8') {
                // Expense type or location changed: re-auto-fill and reset manual flag
                item['total'] = perDiemAmount;
                item.remove('_manualTotal');
              }
            }
          }
        });
      },
    );
  }

  /// Resolve template placeholders like '{travelRequest.code}' from item map
  String? _resolveTemplate(String template, Map<String, dynamic> item) {
    String result = template;
    final regex = RegExp(r'\{([^}]+)\}');
    return result.replaceAllMapped(regex, (m) {
      final path = m.group(1)!.trim();
      final value = _tplGetByPath(item, path);
      return value?.toString() ?? '';
    });
  }

  dynamic _tplGetByPath(Map<String, dynamic> source, String path) {
    dynamic cur = source;
    for (final part in path.split('.')) {
      if (cur is Map && cur.containsKey(part)) {
        cur = cur[part];
      } else {
        return null;
      }
    }
    return cur;
  }

  /// Try parsing date from common patterns like yyyy-MM-dd, dd/MM/yyyy, ddMMyyyy
  DateTime? _tryParseDate(String input) {
    // Already tried DateTime.parse before calling this
    // Try yyyy-MM-dd manually (in case of invalid timezone appended)
    final isoBasic = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoBasic.hasMatch(input)) {
      final parts = input.split('-');
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    // dd/MM/yyyy
    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final slashMatch = slash.firstMatch(input);
    if (slashMatch != null) {
      final d = int.tryParse(slashMatch.group(1)!);
      final m = int.tryParse(slashMatch.group(2)!);
      final y = int.tryParse(slashMatch.group(3)!);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    // ddMMyyyy
    final compact = RegExp(r'^(\d{2})(\d{2})(\d{4})$');
    final compactMatch = compact.firstMatch(input);
    if (compactMatch != null) {
      final d = int.tryParse(compactMatch.group(1)!);
      final m = int.tryParse(compactMatch.group(2)!);
      final y = int.tryParse(compactMatch.group(3)!);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
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
          foregroundColor: _isDisabled
              ? Colors.grey.shade400
              : Colors.blue.shade700,
          side: BorderSide(
            color: _isDisabled ? Colors.grey.shade300 : Colors.blue.shade300,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }
}
