part of 'core_tree.dart';

/// Extension for tree data initialization and loading
extension _CoreTreeInitializationExt on _CoreTreeState {
  /// Apply default values for null fields when loading data
  void applyDefaultValues() {
    if (widget.defaultValues == null) return;

    for (var item in _treeData) {
      widget.defaultValues!.forEach((key, defaultValue) {
        if (item[key] == null) {
          item[key] = defaultValue;
        }
      });
    }
  }

  /// Apply default values when saving (for null fields in form data)
  Map<String, dynamic> applyDefaultValuesOnSave(Map<String, dynamic> formData) {
    if (widget.defaultValues == null) return formData;

    final result = Map<String, dynamic>.from(formData);
    widget.defaultValues!.forEach((key, defaultValue) {
      // Apply default if field is null, empty string, or missing
      if (result[key] == null ||
          (result[key] is String && (result[key] as String).isEmpty) ||
          (result[key] is num && result[key] == 0 && defaultValue != 0)) {
        result[key] = defaultValue;
      }
    });

    return result;
  }

  /// Apply default values to all existing data (comprehensive fix)
  void applyDefaultValuesComprehensive() {
    if (widget.defaultValues == null) return;

    for (var item in _treeData) {
      widget.defaultValues!.forEach((key, defaultValue) {
        // Apply default if field is null, empty, or invalid
        if (item[key] == null ||
            (item[key] is String && (item[key] as String).isEmpty) ||
            (item[key] is num && item[key] == 0 && defaultValue != 0)) {
          item[key] = defaultValue;
        }
      });
    }
  }

  void initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  void reloadDataPreserveNavigation() {
    // Load latest data and removedRows but keep current navigation and parent
    // Read according to storage mode
    dynamic treeData;
    dynamic removedRows;
    if (widget.isOnItemDetailValue) {
      dynamic valueData = widget.itemDetail['value']?[widget.dataKey];
      if (valueData is Map && valueData['data'] is List) {
        removedRows = valueData['removedRows'];
        valueData = valueData['data'];
      }
      treeData = valueData;
    } else {
      if (widget.itemDetail['tree'] is Map) {
        treeData = widget.itemDetail['tree']['data'];
        removedRows = widget.itemDetail['tree']['removedRows'];
      } else {
        treeData = widget.itemDetail['tree'];
      }
    }

    List<Map<String, dynamic>> newTreeData = [];
    if (treeData is List) {
      final List<Map<String, dynamic>> rawList =
          List<Map<String, dynamic>>.from(
            treeData.map((item) => Map<String, dynamic>.from(item ?? {})),
          );
      newTreeData = flattenTree(rawList);
    }

    List<Map<String, dynamic>> newRemoved = [];
    if (removedRows is List) {
      newRemoved = List<Map<String, dynamic>>.from(
        removedRows.map((item) => Map<String, dynamic>.from(item ?? {})),
      );
    }

    // Recompute root level
    int newRoot = 0;
    if (newTreeData.isNotEmpty) {
      final levels = newTreeData
          .map((e) => e['level'])
          .where((lv) => lv is int)
          .cast<int>()
          .toList();
      if (levels.isNotEmpty) {
        levels.sort();
        newRoot = levels.first;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _safeSetState(() {
        _treeData = newTreeData;
        _removedRows = newRemoved;
        _rootLevel = newRoot;
        // restore current items based on current parent
        if (!_isSaving) {
          if (_currentParent == null) {
            _currentItems = _treeData.where((item) {
              final itemLevel = item['level'];
              if (itemLevel is int) return itemLevel == _rootLevel;
              return (item['parentId'] == null) || (item['root'] == true);
            }).toList();
          } else {
            _currentItems = getChildren(_currentParent!['id']);
          }
          initializeItemAnimations();
        }
      });
    });
  }

  void initializeTreeData() {
    // Read according to storage mode
    dynamic treeData;
    dynamic removedRows;

    if (widget.isOnItemDetailValue) {
      dynamic valueData = widget.itemDetail['value']?[widget.dataKey];
      if (valueData is Map && valueData['data'] is List) {
        removedRows = valueData['removedRows'];
        valueData = valueData['data'];
      }
      treeData = valueData;
    } else {
      if (widget.itemDetail['tree'] is Map) {
        treeData = widget.itemDetail['tree']['data'];
        removedRows = widget.itemDetail['tree']['removedRows'];
      } else {
        treeData = widget.itemDetail['tree'];
      }
    }

    if (treeData is List) {
      // Normalize to flat list even if nested children are present
      final List<Map<String, dynamic>> rawList =
          List<Map<String, dynamic>>.from(
            treeData.map((item) => Map<String, dynamic>.from(item ?? {})),
          );
      _treeData = flattenTree(rawList);

      // Apply default values for null fields
      applyDefaultValues();
    } else {
      _treeData = [];
    }

    if (removedRows is List) {
      _removedRows = List<Map<String, dynamic>>.from(
        removedRows.map((item) => Map<String, dynamic>.from(item ?? {})),
      );
    } else {
      _removedRows = [];
    }

    // Determine root level dynamically (min level in data), fallback to 0
    _rootLevel = 0;
    if (_treeData.isNotEmpty) {
      final levels = _treeData
          .map((e) => e['level'])
          .where((lv) => lv is int)
          .cast<int>()
          .toList();
      if (levels.isNotEmpty) {
        levels.sort();
        _rootLevel = levels.first;
      }
    }

    // Don't reset navigation if we're in the middle of saving
    if (!_isSaving) {
      // Initialize with top-level items (by computed root level)
      _currentParent = null;
      _currentItems = _treeData.where((item) {
        final itemLevel = item['level'];
        if (itemLevel is int) return itemLevel == _rootLevel;
        // Fallback: treat items without level as root
        return (item['parentId'] == null) || (item['root'] == true);
      }).toList();

      // Filter items based on permissions
      _currentItems = filterItemsByPermissions(_currentItems);
    }
    _navigationStack = [];
    initializeItemAnimations();

    // Schedule UI update after current frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _safeSetState(() {});
    });
  }

  /// Flatten tree structure if nested children exist to a single list
  List<Map<String, dynamic>> flattenTree(List<Map<String, dynamic>> nodes) {
    final List<Map<String, dynamic>> flat = [];

    // If there is no nested 'children' structure, do NOT recompute levels.
    final bool hasNested = nodes.any(
      (n) => n['children'] is List && (n['children'] as List).isNotEmpty,
    );
    if (!hasNested) {
      for (final node in nodes) {
        final copy = Map<String, dynamic>.from(node);
        copy.remove('children');
        flat.add(copy);
      }
      return flat;
    }

    void traverse(
      Map<String, dynamic> node, {
      required int level,
      String? parentId,
    }) {
      final Map<String, dynamic> copy = Map<String, dynamic>.from(node);
      // Avoid retaining heavy nested children in the flat representation
      final dynamic children = copy.remove('children');

      // Compute level/parent only when not present
      if (copy['level'] is! int) {
        copy['level'] = level;
      }
      if ((copy['parentId'] == null ||
              (copy['parentId']?.toString().isEmpty ?? true)) &&
          parentId != null) {
        copy['parentId'] = parentId;
      }

      flat.add(copy);

      if (children is List) {
        final String? thisId = copy['id']?.toString();
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            traverse(child, level: level + 1, parentId: thisId);
          }
        }
      }
    }

    for (final node in nodes) {
      traverse(node, level: 0, parentId: null);
    }
    return flat;
  }

  /// Build nested children structure from flat list using parentId
  List<Map<String, dynamic>> buildNestedTreeFromFlat(
    List<Map<String, dynamic>> flat,
  ) {
    final Map<String, Map<String, dynamic>> nodeById = {};
    for (final item in flat) {
      if (item['id'] == null) continue;
      final copy = Map<String, dynamic>.from(item);
      copy.remove('children');
      copy['children'] = <Map<String, dynamic>>[];
      nodeById[copy['id'].toString()] = copy;
    }

    final List<Map<String, dynamic>> roots = [];
    for (final item in flat) {
      final id = item['id']?.toString();
      if (id == null) continue;
      final copy = nodeById[id]!;
      final parentId = copy['parentId']?.toString();
      if (parentId != null &&
          parentId.isNotEmpty &&
          nodeById.containsKey(parentId)) {
        final parent = nodeById[parentId]!;
        (parent['children'] as List).add(copy);
      } else {
        roots.add(copy);
      }
    }

    void assignLevels(Map<String, dynamic> node, int level) {
      node['level'] = level;
      node['root'] = level == 0;
      final children = (node['children'] as List).cast<Map<String, dynamic>>();
      node['leaf'] = children.isEmpty;
      for (final child in children) {
        child['parentId'] = node['id'];
        assignLevels(child, level + 1);
      }
    }

    for (final root in roots) {
      assignLevels(root, 0);
    }

    return roots;
  }

  void initializeItemAnimations() {
    // Dispose existing controllers
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    _scaleControllers.clear();
    _scaleAnimations.clear();

    // Create new controllers for current items
    for (int i = 0; i < _currentItems.length; i++) {
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

  List<Map<String, dynamic>> getChildren(dynamic parentId) {
    final String pid = parentId?.toString() ?? '';
    final children = _treeData
        .where((item) => (item['parentId']?.toString() ?? '') == pid)
        .toList();
    return children;
  }
}
