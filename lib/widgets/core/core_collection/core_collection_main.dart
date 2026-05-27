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
  final List<Map<String, dynamic>>? footerActions; // Extra item actions
  final void Function(
    BuildContext context,
    Map<String, dynamic> item,
    Map<String, dynamic> actionConfig,
  )?
  onFooterAction; // Callback for item actions

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
    this.footerActions,
    this.onFooterAction,
  });

  @override
  State<CoreCollection> createState() => _CoreCollectionState();
}

class _CoreCollectionState extends State<CoreCollection>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _items;
  final Map<int, AnimationController> _scaleControllers = {};
  final Map<int, Animation<double>> _scaleAnimations = {};
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

  void _replaceItem(int index, Map<String, dynamic> item) {
    setState(() {
      _items[index] = item;
    });
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
}
