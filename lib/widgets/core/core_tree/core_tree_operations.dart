part of 'core_tree.dart';

/// Extension for CRUD operations on tree items
extension _CoreTreeOperationsExt on _CoreTreeState {
  void addNewItem() {
    if (!widget.allowAdd || !isActionAllowed('add')) return;

    _fabAnimationController.forward().then(
      (_) => _fabAnimationController.reverse(),
    );
    showItemDialog(null, isAdd: true);
  }

  void editItem(Map<String, dynamic> item, int index) {
    if (!widget.allowEdit || !isActionAllowed('edit', item)) return;

    // Animate the tapped item
    _scaleControllers[index]?.forward().then(
      (_) => _scaleControllers[index]?.reverse(),
    );

    showItemDialog(item, isAdd: false);
  }

  void showItemDialog(Map<String, dynamic>? item, {required bool isAdd}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _TreeItemEditDialog(
              item: item,
              isAdd: isAdd,
              children: widget.children,
              itemLabel: widget.itemLabel ?? 'Item',
              parentItemDetail: widget.itemDetail,
              onSave: (savedItem) => saveItem(savedItem, isAdd),
            ),
          ),
        ),
      ),
    );
  }

  void saveItem(Map<String, dynamic> itemData, bool isAdd) {
    // Set saving flag to prevent navigation reset
    _isSaving = true;

    if (isAdd) {
      // Generate new UUID in uppercase format
      final newId = _uuid.v4().toUpperCase();

      // Determine level and parentId
      final level = _currentParent == null
          ? _rootLevel
          : ((_currentParent!['level'] ?? _rootLevel) + 1);
      final parentId = _currentParent?['id'];

      // Initialize with common fields set to null if not provided
      final Map<String, dynamic> initialData = {};

      // First, ensure all common fields exist with null value
      if (widget.commonFields != null) {
        for (final field in widget.commonFields!) {
          initialData[field] = null;
        }
      }

      // Then, ensure all fields from children config have null value if not provided
      for (final childConfig in widget.children) {
        final String? key = childConfig['key']?.toString();
        if (key != null && !initialData.containsKey(key)) {
          initialData[key] = null;
        }
      }

      // Apply default values for null fields in form data
      final processedItemData = applyDefaultValuesOnSave(itemData);

      // Create new item with initialized fields and actual data
      final newItem = {
        ...initialData, // Start with null values for all fields
        ...processedItemData, // Override with actual values from form (with defaults applied)
        'id': newId,
        'level': level,
        'parentId': parentId,
        'leaf': true,
        'root': level == _rootLevel,
        'children': <Map<String, dynamic>>[],
      };
      if (widget.isUseUpdateAction) {
        newItem['action'] = 'update';
      }

      _safeSetState(() {
        _treeData.add(newItem);
        _currentItems.add(newItem);
        initializeItemAnimations();
      });
    } else {
      // Update existing item

      _safeSetState(() {
        final index = _treeData.indexWhere(
          (item) => item['id'] == itemData['id'],
        );
        if (index >= 0) {
          final current = _treeData[index];

          // Apply default values for null fields in form data
          final processedItemData = applyDefaultValuesOnSave(itemData);

          final merged = {...current, ...processedItemData};
          // Preserve structural fields to avoid losing hierarchy
          merged['id'] = current['id'];
          merged['level'] = current['level'];
          merged['parentId'] = current['parentId'];
          merged['root'] = current['root'];
          merged['leaf'] = current['leaf'];
          if (widget.isUseUpdateAction) merged['action'] = 'update';

          _treeData[index] = merged;

          // Update current items as well
          final currentIndex = _currentItems.indexWhere(
            (item) => item['id'] == itemData['id'],
          );
          if (currentIndex >= 0) {
            _currentItems[currentIndex] = merged;
          }
        }
      });
    }

    // Apply default values comprehensively after save
    applyDefaultValuesComprehensive();

    // Update tree data but preserve current navigation state
    updateTreeDataPreserveNavigation();

    // Clear saving flag after save is complete (longer delay to ensure all rebuilds are done)
    Future.delayed(const Duration(milliseconds: 500), () {
      _isSaving = false;
    });
  }

  void performDelete(Map<String, dynamic> item) {
    _safeSetState(() {
      // Remove from tree data
      _treeData.removeWhere((treeItem) => treeItem['id'] == item['id']);

      // Conditionally add to removed rows
      if (widget.isUseUpdateAction) {
        _removedRows.add(item);
      }

      // Update current items
      _currentItems.removeWhere(
        (currentItem) => currentItem['id'] == item['id'],
      );

      // Also remove any children recursively
      removeChildrenRecursively(item['id']);

      initializeItemAnimations();
    });

    updateTreeDataPreserveNavigation();
  }

  void removeChildrenRecursively(String parentId) {
    final String pid = parentId.toString();
    final children = _treeData
        .where((item) => (item['parentId']?.toString() ?? '') == pid)
        .toList();
    for (final child in children) {
      if (widget.isUseUpdateAction) {
        _removedRows.add(child);
      }
      _treeData.removeWhere((item) => item['id'] == child['id']);
      removeChildrenRecursively(child['id'].toString());
    }
  }

  void updateTreeDataPreserveNavigation() {
    // Save current navigation state
    final savedCurrentParent = _currentParent;
    final savedNavigationStack = List<Map<String, dynamic>>.from(
      _navigationStack,
    );

    // Update tree data WITHOUT triggering widget rebuild that resets navigation
    updateTreeDataSilent();

    // Immediately restore navigation state

    _safeSetState(() {
      _currentParent = savedCurrentParent;
      _navigationStack = savedNavigationStack;

      // Refresh current items based on current parent
      if (_currentParent == null) {
        // At root level
        _currentItems = _treeData.where((item) {
          final itemLevel = item['level'];
          if (itemLevel is int) return itemLevel == _rootLevel;
          return (item['parentId'] == null) || (item['root'] == true);
        }).toList();
      } else {
        // At child level
        _currentItems = _treeData
            .where((item) => item['parentId'] == _currentParent!['id'])
            .toList();
      }

      // Apply permission filtering
      _currentItems = filterItemsByPermissions(_currentItems);

      // Refresh animations for current items
      initializeItemAnimations();
    });
  }

  void updateTreeDataSilent() {
    // Build nested structure: root level has children -> level1, level1 has children -> level2
    final List<Map<String, dynamic>> nestedRoots = buildNestedTreeFromFlat(
      _treeData,
    );

    // Update itemDetail with new tree data based on storage mode
    final updatedItemDetail = Map<String, dynamic>.from(widget.itemDetail);
    if (widget.isOnItemDetailValue) {
      if (updatedItemDetail['value'] == null) {
        updatedItemDetail['value'] = <String, dynamic>{};
      }
      if (widget.isUseUpdateAction) {
        updatedItemDetail['value'][widget.dataKey] = {
          'data': nestedRoots,
          'removedRows': _removedRows,
        };
      } else {
        updatedItemDetail['value'][widget.dataKey] = nestedRoots;
      }
    } else {
      if (widget.isUseUpdateAction) {
        updatedItemDetail['tree'] = {
          'data': nestedRoots,
          'removedRows': _removedRows,
        };
      } else {
        updatedItemDetail['tree'] = nestedRoots;
      }
    }

    // Notify parent about the change WITHOUT triggering setState
    widget.onChanged(updatedItemDetail);
  }
}
