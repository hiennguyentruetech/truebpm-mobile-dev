import 'package:flutter/material.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Core Tree Widget for hierarchical tree data structure
/// Supports navigation through levels and CRUD operations
/// Inspired by CoreCollection but with tree navigation capabilities
class CoreTree extends StatefulWidget {
  final String dataKey;
  final Map<String, dynamic> itemDetail;
  final String label;
  final String? hintText;
  final List<Map<String, dynamic>> children; // Field configurations for tree items
  final String? itemLabel; // Label for each item
  final String? addButtonText; // Custom text for add button
  final bool allowAdd;
  final bool allowEdit;
  final bool allowDelete;
  final Function(dynamic) onChanged;
  final bool required;
  final Map<String, dynamic>? summary; // Dynamic summary configuration
  final String? headerTemplate; // Template for header, e.g. "{itemNo} - {name}"
  final bool isUseUpdateAction; // When true, mark updates and collect removedRows
  final bool isOnItemDetailValue; // Storage mode: true => itemDetail.value[dataKey], false => itemDetail.tree
  final String? titleKey; // Which key to use as item title instead of 'name' (deprecated, use titleTemplate)
  final String? titleTemplate; // Template for item title, e.g. "{itemNo} - {name}"
  final List<Map<String, dynamic>>? footerActions; // Extra footer actions
  final void Function(BuildContext context, Map<String, dynamic> item, Map<String, dynamic> actionConfig)? onFooterAction; // Callback for footer actions
  final List<String>? commonFields; // Fields that must always have a value (null if not provided)
  final Map<String, dynamic>? levelRestrictions; // Level-based action restrictions
  final Map<String, dynamic>? defaultValues; // Default values for tree fields
  final Map<String, dynamic>? permissions; // Permission-based action restrictions

  const CoreTree({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    required this.label,
    this.hintText,
    required this.children,
    this.itemLabel,
    this.addButtonText,
    this.allowAdd = true,
    this.allowEdit = true,
    this.allowDelete = true,
    required this.onChanged,
    this.required = false,
    this.summary,
    this.headerTemplate,
    this.isUseUpdateAction = false,
    this.isOnItemDetailValue = false,
    this.titleKey,
    this.titleTemplate,
    this.footerActions,
    this.onFooterAction,
    this.commonFields,
    this.levelRestrictions,
    this.defaultValues,
    this.permissions,
  });

  @override
  State<CoreTree> createState() => _CoreTreeState();
}

class _CoreTreeState extends State<CoreTree> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _treeData = [];
  List<Map<String, dynamic>> _removedRows = [];
  List<Map<String, dynamic>> _navigationStack = [];
  Map<String, dynamic>? _currentParent;
  List<Map<String, dynamic>> _currentItems = [];
  int _rootLevel = 0;
  final _uuid = const Uuid();

  // Helper method to check if action is allowed at current level
  bool _isActionAllowedAtLevel(String actionType) {
    if (widget.levelRestrictions == null) return true;

    final currentLevel = _navigationStack.length;
    final restrictions = widget.levelRestrictions!;

    switch (actionType) {
      case 'add':
        final minLevel = restrictions['minLevelForAdd'] as int?;
        return minLevel == null || currentLevel >= minLevel;
      case 'edit':
        final minLevel = restrictions['minLevelForEdit'] as int?;
        return minLevel == null || currentLevel >= minLevel;
      case 'delete':
        final minLevel = restrictions['minLevelForDelete'] as int?;
        return minLevel == null || currentLevel >= minLevel;
      case 'footerActions':
        final minLevel = restrictions['minLevelForFooterActions'] as int?;
        return minLevel == null || currentLevel >= minLevel;
      default:
        return true;
    }
  }

  // Helper method to check if action is allowed based on permissions
  bool _isActionAllowedByPermission(String actionType, [Map<String, dynamic>? item]) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    switch (actionType) {
      case 'add':
        return permissions['canAdd'] ?? true;
      case 'edit':
        if (item != null) {
          return _canEditItem(item);
        }
        return permissions['canEdit'] ?? true;
      case 'delete':
        if (item != null) {
          return _canDeleteItem(item);
        }
        return permissions['canDelete'] ?? true;
      case 'footerActions':
        if (item != null) {
          return _canAccessFooterActions(item);
        }
        return permissions['canAccessFooterActions'] ?? true;
      default:
        return true;
    }
  }

  // Check if user can edit specific item
  bool _canEditItem(Map<String, dynamic> item) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    // If user has global edit permission, allow
    if (permissions['canEdit'] == true) return true;

    // If user has no global edit permission, check item-specific permission
    if (permissions['canEdit'] == false) {
      // Allow edit if user is in charge of this specific item
      return _isUserInChargeOfItem(item);
    }

    // Default fallback
    return _isUserInChargeOfItem(item);
  }

  // Check if user can delete specific item
  bool _canDeleteItem(Map<String, dynamic> item) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    // If user has global delete permission, allow
    if (permissions['canDelete'] == true) return true;

    // If user has no global delete permission, check item-specific permission
    if (permissions['canDelete'] == false) {
      // For delete, only allow if user is in charge AND is privileged
      // Regular users in inChargePerson cannot delete
      return false;
    }

    // Default fallback
    return _isUserInChargeOfItem(item);
  }

  // Check if user can access footer actions for specific item
  bool _canAccessFooterActions(Map<String, dynamic> item) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    // If user has global footer actions permission, allow
    if (permissions['canAccessFooterActions'] == true) return true;

    // If user has no global footer actions permission, check item-specific permission
    if (permissions['canAccessFooterActions'] == false) {
      // Allow footer actions if user is in charge of this specific item
      return _isUserInChargeOfItem(item);
    }

    // Default fallback
    return _isUserInChargeOfItem(item);
  }

  // Check if current user is in charge of the item
  bool _isUserInChargeOfItem(Map<String, dynamic> item) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;
    final currentUserId = permissions['currentUserId'];

    if (currentUserId == null) return true;

    // Check inChargePerson collection
    final inChargePerson = item['inChargePerson'];
    if (inChargePerson is List) {
      for (var person in inChargePerson) {
        if (person is Map && person['person'] is Map) {
          final personId = person['person']['id'];
          if (personId == currentUserId) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Combined check for both level and permission restrictions
  bool _isActionAllowed(String actionType, [Map<String, dynamic>? item]) {
    final levelAllowed = _isActionAllowedAtLevel(actionType);
    final permissionAllowed = _isActionAllowedByPermission(actionType, item);
    final result = levelAllowed && permissionAllowed;

    return result;
  }

  // Filter items based on permissions (hide items user can't access)
  List<Map<String, dynamic>> _filterItemsByPermissions(List<Map<String, dynamic>> items) {
    if (widget.permissions == null) {
      return items;
    }

    final permissions = widget.permissions!;

    // If user has global permissions, show all items
    if (permissions['canEdit'] == true ||
        permissions['canDelete'] == true ||
        permissions['canAccessFooterActions'] == true) {
      return items;
    }

    // For non-privileged users, show items they have access to + parent items needed for navigation
    return _getAccessibleItemsWithParents(items);
  }

  // Get items user can access plus their parent items for navigation
  List<Map<String, dynamic>> _getAccessibleItemsWithParents(List<Map<String, dynamic>> items) {
    final accessibleItems = <Map<String, dynamic>>[];
    final itemsUserCanAccess = <String>{};
    final parentIdsNeeded = <String>{};

    // First pass: Find ALL items in the entire tree that user has direct access to
    for (var item in _treeData) {  // Search entire tree, not just current level
      if (_isUserInChargeOfItem(item)) {
        itemsUserCanAccess.add(item['id'].toString());

        // Add all parent IDs needed to reach this item (traverse up the tree)
        String? parentId = item['parentId']?.toString();
        while (parentId != null && parentId.isNotEmpty && parentId != 'null') {
          parentIdsNeeded.add(parentId);
          // Find parent item to get its parent
          final parentItem = _treeData.firstWhere(
            (i) => i['id'].toString() == parentId,
            orElse: () => <String, dynamic>{},
          );
          if (parentItem.isEmpty) break;
          parentId = parentItem['parentId']?.toString();
        }
      }
    }

    // If no items found, show all items for navigation (but without action permissions)
    if (itemsUserCanAccess.isEmpty && parentIdsNeeded.isEmpty) {
      return items;
    }

    // Second pass: Include items from current level that user can access OR are needed for navigation
    for (var item in items) {
      final itemId = item['id'].toString();

      if (itemsUserCanAccess.contains(itemId) || parentIdsNeeded.contains(itemId)) {
        accessibleItems.add(item);
      }
    }

    return accessibleItems;
  }

  // Apply default values for null fields when loading data
  void _applyDefaultValues() {
    if (widget.defaultValues == null) return;

    for (var item in _treeData) {
      widget.defaultValues!.forEach((key, defaultValue) {
        if (item[key] == null) {
          item[key] = defaultValue;
        }
      });
    }
  }

  // Apply default values when saving (for null fields in form data)
  Map<String, dynamic> _applyDefaultValuesOnSave(Map<String, dynamic> formData) {
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

  // Apply default values to all existing data (comprehensive fix)
  void _applyDefaultValuesComprehensive() {
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

  // Animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  Map<int, AnimationController> _scaleControllers = {};
  Map<int, Animation<double>> _scaleAnimations = {};

  // Flag to prevent navigation reset during save
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTreeData();
  }
  
  @override
  void dispose() {
    _fabAnimationController.dispose();
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didUpdateWidget(CoreTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemDetail != widget.itemDetail) {
      if (!_isSaving) {
        _reloadDataPreserveNavigation();
      }
    }
  }

  void _reloadDataPreserveNavigation() {
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
      final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(
        treeData.map((item) => Map<String, dynamic>.from(item ?? {})),
      );
      newTreeData = _flattenTree(rawList);
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
      setState(() {
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
            _currentItems = _getChildren(_currentParent!['id']);
          }
          _initializeItemAnimations();
        }
      });
    });
  }
  
  void _initializeTreeData() {
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
      final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(
        treeData.map((item) => Map<String, dynamic>.from(item ?? {})),
      );
      _treeData = _flattenTree(rawList);

      // Apply default values for null fields
      _applyDefaultValues();
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
      _currentItems = _filterItemsByPermissions(_currentItems);
    }
    _navigationStack = [];
    _initializeItemAnimations();

    // Schedule UI update after current frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // Flatten tree structure if nested children exist to a single list
  List<Map<String, dynamic>> _flattenTree(List<Map<String, dynamic>> nodes) {
    final List<Map<String, dynamic>> flat = [];

    // If there is no nested 'children' structure, do NOT recompute levels.
    final bool hasNested = nodes.any((n) => n['children'] is List && (n['children'] as List).isNotEmpty);
    if (!hasNested) {
      for (final node in nodes) {
        final copy = Map<String, dynamic>.from(node);
        copy.remove('children');
        flat.add(copy);
            }
      return flat;
    }

    void traverse(Map<String, dynamic> node, {required int level, String? parentId}) {
      final Map<String, dynamic> copy = Map<String, dynamic>.from(node);
      // Avoid retaining heavy nested children in the flat representation
      final dynamic children = copy.remove('children');

      // Compute level/parent only when not present
      if (copy['level'] is! int) {
        copy['level'] = level;
      }
      if ((copy['parentId'] == null || (copy['parentId']?.toString().isEmpty ?? true)) && parentId != null) {
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

  // Build nested children structure from flat list using parentId
  List<Map<String, dynamic>> _buildNestedTreeFromFlat(List<Map<String, dynamic>> flat) {
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
      if (parentId != null && parentId.isNotEmpty && nodeById.containsKey(parentId)) {
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

  void _initializeItemAnimations() {
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
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      _scaleControllers[i] = controller;
      _scaleAnimations[i] = animation;
    }
  }
  
  // Removed unused _getItemsAtLevel; root items are computed dynamically
  
  List<Map<String, dynamic>> _getChildren(dynamic parentId) {
    final String pid = parentId?.toString() ?? '';
    final children = _treeData
        .where((item) => (item['parentId']?.toString() ?? '') == pid)
        .toList();
    return children;
  }
  
  void _navigateToChildren(Map<String, dynamic> parent) {
    final children = _getChildren(parent['id']);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _navigationStack.add({
          'parent': _currentParent,
          'items': List.from(_currentItems),
        });
        _currentParent = parent;
        _currentItems = children; // may be empty; shows empty state of this node

        // Apply permission filtering
        _currentItems = _filterItemsByPermissions(_currentItems);

        _initializeItemAnimations();
      });
    });
  }
  
  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      final previous = _navigationStack.removeLast();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentParent = previous['parent'];
          _currentItems = List.from(previous['items']);

          // Apply permission filtering
          _currentItems = _filterItemsByPermissions(_currentItems);

          _initializeItemAnimations();
        });
      });
    }
  }
  
  void _addNewItem() {
    if (!widget.allowAdd || !_isActionAllowed('add')) return;

    _fabAnimationController.forward().then((_) => _fabAnimationController.reverse());
    _showItemDialog(null, isAdd: true);
  }
  
  void _editItem(Map<String, dynamic> item, int index) {
    if (!widget.allowEdit || !_isActionAllowed('edit', item)) return;

    // Animate the tapped item
    _scaleControllers[index]?.forward().then((_) => _scaleControllers[index]?.reverse());

    _showItemDialog(item, isAdd: false);
  }
  
  void _showItemDialog(Map<String, dynamic>? item, {required bool isAdd}) {
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
            onSave: (savedItem) => _saveItem(savedItem, isAdd),
          ),
          ),
        ),
      ),
    );
  }
  
  void _saveItem(Map<String, dynamic> itemData, bool isAdd) {
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
      final processedItemData = _applyDefaultValuesOnSave(itemData);

      // Create new item with initialized fields and actual data
      final newItem = {
        ...initialData,  // Start with null values for all fields
        ...processedItemData,     // Override with actual values from form (with defaults applied)
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
      
      setState(() {
        _treeData.add(newItem);
        _currentItems.add(newItem);
        _initializeItemAnimations();
      });
    } else {
      // Update existing item
      setState(() {
        final index = _treeData.indexWhere((item) => item['id'] == itemData['id']);
        if (index >= 0) {
          final current = _treeData[index];

          // Apply default values for null fields in form data
          final processedItemData = _applyDefaultValuesOnSave(itemData);

          final merged = {
            ...current,
            ...processedItemData,
          };
          // Preserve structural fields to avoid losing hierarchy
          merged['id'] = current['id'];
          merged['level'] = current['level'];
          merged['parentId'] = current['parentId'];
          merged['root'] = current['root'];
          merged['leaf'] = current['leaf'];
          if (widget.isUseUpdateAction) merged['action'] = 'update';

          _treeData[index] = merged;

          // Update current items as well
          final currentIndex = _currentItems.indexWhere((item) => item['id'] == itemData['id']);
          if (currentIndex >= 0) {
            _currentItems[currentIndex] = merged;
          }
        }
      });
    }

    // Apply default values comprehensively after save
    _applyDefaultValuesComprehensive();

    // Update tree data but preserve current navigation state
    _updateTreeDataPreserveNavigation();

    // Clear saving flag after save is complete (longer delay to ensure all rebuilds are done)
    Future.delayed(const Duration(milliseconds: 500), () {
      _isSaving = false;
    });
  }
  
  void _performDelete(Map<String, dynamic> item) {
    setState(() {
      // Remove from tree data
      _treeData.removeWhere((treeItem) => treeItem['id'] == item['id']);
      
      // Conditionally add to removed rows
      if (widget.isUseUpdateAction) {
        _removedRows.add(item);
      }
      
      // Update current items
      _currentItems.removeWhere((currentItem) => currentItem['id'] == item['id']);
      
      // Also remove any children recursively
      _removeChildrenRecursively(item['id']);
      
      _initializeItemAnimations();
    });

    _updateTreeDataPreserveNavigation();
  }
  
  void _removeChildrenRecursively(String parentId) {
    final String pid = parentId.toString();
    final children = _treeData
        .where((item) => (item['parentId']?.toString() ?? '') == pid)
        .toList();
    for (final child in children) {
      if (widget.isUseUpdateAction) {
        _removedRows.add(child);
      }
      _treeData.removeWhere((item) => item['id'] == child['id']);
      _removeChildrenRecursively(child['id'].toString());
    }
  }
  

  void _updateTreeDataPreserveNavigation() {
    // Save current navigation state
    final savedCurrentParent = _currentParent;
    final savedNavigationStack = List<Map<String, dynamic>>.from(_navigationStack);

    // Update tree data WITHOUT triggering widget rebuild that resets navigation
    _updateTreeDataSilent();

    // Immediately restore navigation state
    setState(() {
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
        _currentItems = _treeData.where((item) => item['parentId'] == _currentParent!['id']).toList();
      }

      // Apply permission filtering
      _currentItems = _filterItemsByPermissions(_currentItems);

      // Refresh animations for current items
      _initializeItemAnimations();
    });
  }

  void _updateTreeDataSilent() {
    // Build nested structure: root level has children -> level1, level1 has children -> level2
    final List<Map<String, dynamic>> nestedRoots = _buildNestedTreeFromFlat(_treeData);

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

  // Breadcrumb was removed per latest UI spec

  Widget _buildTreeItem(Map<String, dynamic> item, int index) {
    final summaryWidget = _buildCollectionStyleSummary(item);

    // Title for item header, using titleTemplate or titleKey
    String? title;
    
    // Priority: titleTemplate > titleKey > default fields
    if (widget.titleTemplate != null && widget.titleTemplate!.isNotEmpty) {
      // Enhance item context with children count for template rendering
      final Map<String, dynamic> enhancedItem = Map<String, dynamic>.from(item);

      // Get actual children count from tree data
      final String itemId = item['id']?.toString() ?? '';
      final actualChildren = _treeData.where((treeItem) =>
        treeItem['parentId']?.toString() == itemId
      ).toList();

      // Set the actual children for template rendering
      enhancedItem['children'] = actualChildren;

      // Use template rendering with enhanced context
      title = _renderTemplate(widget.titleTemplate!, enhancedItem).trim();
      if (title.isEmpty) title = null; // Fall back to default if template returns empty
    }
    
    if (title == null || title.isEmpty) {
      // Fall back to titleKey if provided
      final keyPref = widget.titleKey;
      if (keyPref != null && keyPref.isNotEmpty) {
        title = item[keyPref]?.toString();
      }
    }
    
    // Final fallback to default fields
    title ??= item['name']?.toString() ?? item['displayText']?.toString() ?? 'Unnamed';

    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gradient header with navigate icon - tap to edit
        InkWell(
          onTap: (widget.allowEdit && _isActionAllowed('edit', item)) ? () => _editItem(item, index) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color.fromARGB(255, 145, 17, 54), const Color.fromARGB(255, 22, 140, 185)], // purple-blue
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                    softWrap: true,
                  ),
                ),
                // Navigate to children icon
                InkWell(
                  onTap: () => _navigateToChildren(item),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content area - tap to edit
        InkWell(
          onTap: (widget.allowEdit && _isActionAllowed('edit', item)) ? () => _editItem(item, index) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: summaryWidget,
          ),
        ),

        // Footer with icons (flexible)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 218, 218),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Extra actions from config
              if ((widget.footerActions ?? const []).isNotEmpty && _isActionAllowed('footerActions', item))
                ..._buildFooterActionButtons(item),
              // Spacer
              const Spacer(),
              // Delete isolated at far right
              if (widget.allowDelete && _isActionAllowed('delete', item))
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  color: Colors.red[400],
                  onPressed: () => _performDelete(item),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
        ),
      ],
    );

    return Dismissible(
      key: Key(item['id']?.toString() ?? ''),
      direction: widget.allowDelete ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: widget.allowDelete ? (_) => _performDelete(item) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: cardBody,
      ),
    );
  }

  List<Widget> _buildFooterActionButtons(Map<String, dynamic> item) {
    final actions = widget.footerActions ?? const [];
    return actions.map((cfg) {
      final String type = (cfg['type'] ?? '').toString();
      final String tooltip = (cfg['tooltip'] ?? '').toString();
      IconData icon;
      // Determine icon by type
      switch (type) {
        case 'comment':
          icon = Icons.comment_outlined;
          break;
        case 'document':
          icon = Icons.description_outlined;
          break;
        case 'download':
          icon = Icons.download_rounded;
          break;
        default:
          icon = Icons.extension_rounded;
      }
      // Color: use config['color'] if provided, else default icon color
      Color? color;
      final dynamic colorCfg = cfg['color'];
      if (colorCfg != null) {
        if (colorCfg is Color) {
          color = colorCfg;
        } else if (colorCfg is int) {
          color = Color(colorCfg);
        } else if (colorCfg is String) {
          String hex = colorCfg.trim();
          if (hex.startsWith('#')) hex = hex.substring(1);
          if (hex.length == 6) hex = 'FF$hex';
          final intVal = int.tryParse(hex, radix: 16);
          if (intVal != null) color = Color(intVal);
        }
      }
      color ??= null; // null means use default icon color
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: 18),
          color: color,
          onPressed: () {
            // Call the onFooterAction callback if provided
            if (widget.onFooterAction != null) {
              widget.onFooterAction!(context, item, cfg);
            }
          },
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      );
    }).toList();
  }

  // CoreCollection-style summary rendering
  Widget _buildCollectionStyleSummary(Map<String, dynamic> item) {
    final summaryCfg = widget.summary;

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
      
      String value = '';
      
      // Handle collection with template
      if (raw is List && conf['collectionTemplate'] != null) {
        final String template = conf['collectionTemplate'].toString();
        final List<String> renderedItems = [];
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            final rendered = _renderTemplate(template, item).trim();
            if (rendered.isNotEmpty && rendered != 'null - null') {
              renderedItems.add(rendered);
            }
          }
        }
        if (renderedItems.isEmpty) continue;
        value = renderedItems.join(', ');
      } else if (raw is Map && conf['display'] != null) {
        raw = raw[conf['display']];
        value = raw?.toString() ?? '';
      } else {
        value = raw?.toString() ?? '';
      }
      
      if (value.isEmpty || value == 'null') continue;

      // Check if this is a datetime field and format accordingly
      final String? widget = conf['widget']?.toString();
      final String? datetimeType = conf['datetimeType']?.toString();
      if (widget == 'datetime' && value.isNotEmpty) {
        value = _formatDateTimeValue(value, datetimeType, conf['displayFormat']?.toString());
      }

      final String label = conf['label']?.toString() ?? keyPath.split('.').last;
      final String? suffix = conf['suffix']?.toString();
      if (suffix != null && suffix.isNotEmpty && widget != 'datetime') {
        value = '$value$suffix';
      }

      final String fieldLayout = conf['layout']?.toString() ?? defaultLayout;

      rows.add(_buildStackedRow(
        label,
        value,
        labelColor: _parseColor(conf['labelColor']) ?? Colors.grey.shade700,
        valueColor: _parseColor(conf['valueColor']) ?? Colors.black87,
        bgColor: _parseColor(conf['bgColor']) ?? Colors.white,
        borderColor: _parseColor(conf['borderColor']) ?? Colors.grey.shade200,
        layout: fieldLayout,
      ));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  // Helpers copied from CoreCollection to support summary
  String _formatDateTimeValue(String value, String? datetimeType, String? displayFormat) {
    try {
      DateTime? dateTime;
      if (value.contains('T')) {
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
      } else if (value.contains('/')) {
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
              dateTime = DateTime.utc(year, month, day, hour, minute);
            } else {
              dateTime = DateTime.utc(year, month, day);
            }
          }
        }
      } else {
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
      if (dateTime == null) return value;
      switch (datetimeType) {
        case 'time':
          return DateFormat('HH:mm').format(dateTime.toUtc());
        case 'date':
          return DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        case 'datetime':
          return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
        case 'daterange':
          return DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        default:
          return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
      }
    } catch (e) {
      return value;
    }
  }

  static dynamic _getByPath(Map<String, dynamic> map, String path) {
    dynamic curr = map;
    final segments = path.split('.');

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];

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

  /// Render a simple template like "{itemNo} - {name}" using dot-paths from context
  String _renderTemplate(String template, Map<String, dynamic> context) {
    if (template.isEmpty) return '';
    final regex = RegExp(r'\{\s*([^}]+)\s*\}');
    return template.replaceAllMapped(regex, (match) {
      final path = match.group(1)!.trim();
      final value = _getByPath(context, path);
      return value == null ? '' : value.toString();
    });
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

  Widget _buildStackedRow(String label, String value, {Color? labelColor, Color? valueColor, Color? bgColor, Color? borderColor, String? layout}) {
    if (layout == 'row') {
      return _buildHorizontalRow(label, value,
          labelColor: labelColor, valueColor: valueColor, bgColor: bgColor, borderColor: borderColor);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 37,
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
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 63,
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

  @override
  Widget build(BuildContext context) {
    // Don't render if hidden
    if (widget.itemDetail['attribute']?['hidden']?[widget.dataKey] == true) {
      return const SizedBox.shrink();
    }
    // Build header label with optional template using current context (currentParent)
    String headerTitle = widget.label;
    if (widget.headerTemplate != null) {
      final Map<String, dynamic> headerCtx = {
        ...?widget.itemDetail['value'] as Map<String, dynamic>?,
        ...?_currentParent,
      };

      // Ensure children is available for .length to work in header template
      if (_currentParent != null && (!headerCtx.containsKey('children') || headerCtx['children'] is! List)) {
        // Get children from current parent context
        headerCtx['children'] = _currentItems;
      } else if (!headerCtx.containsKey('children') || headerCtx['children'] is! List) {
        // Fallback to empty list if no children
        headerCtx['children'] = <Map<String, dynamic>>[];
      }

      headerTitle = _renderTemplate(widget.headerTemplate!, headerCtx).trim();
      if (headerTitle.isEmpty) headerTitle = widget.label;
    }

    // Column layout; headerTemplate hidden on root level; breadcrumb removed
    return Stack(
      children: [
        Column(
          children: [
            // Top header (gradient), only show when not at root level
            if (_navigationStack.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color.fromARGB(255, 20, 65, 165), Color.fromARGB(255, 20, 180, 230)], // green gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: _navigateBack,
                      tooltip: 'Back',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                            softWrap: true,
                          ),
                          if (widget.hintText != null && widget.hintText!.isNotEmpty)
                            Text(
                              widget.hintText!,
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                              softWrap: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _currentItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No items found', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 50, top: 8),
                      itemCount: _currentItems.length,
                      itemBuilder: (context, index) => _buildTreeItem(_currentItems[index], index),
                    ),
            ),
          ],
        ),

        // FAB on top of content
        if (widget.allowAdd && _isActionAllowed('add'))
          Positioned(
            right: 4,
            bottom: 4,
            child: AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: FloatingActionButton(
                      onPressed: _addNewItem,
                      backgroundColor: const Color.fromARGB(255, 51, 86, 227), // beautiful gradient purple
                      foregroundColor: Colors.white,
                      heroTag: null,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add_rounded, size: 35),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Dialog for editing tree items
class _TreeItemEditDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final bool isAdd;
  final List<Map<String, dynamic>> children;
  final String itemLabel;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic> parentItemDetail;

  const _TreeItemEditDialog({
    required this.item,
    required this.isAdd,
    required this.children,
    required this.itemLabel,
    required this.onSave,
    required this.parentItemDetail,
  });

  @override
  State<_TreeItemEditDialog> createState() => _TreeItemEditDialogState();
}

class _TreeItemEditDialogState extends State<_TreeItemEditDialog> {
  Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeForm() {
  // Initialize form data; if the dialog opens mid-build, defer state updates
  _formData = Map<String, dynamic>.from(widget.item ?? {});
  }

  List<Widget> _buildFields() {
    final itemItemDetail = {
      'value': _formData,
      'attribute': widget.parentItemDetail['attribute'] ?? {},
    };

    final parentCtx = widget.parentItemDetail['value'];
    final Map<String, dynamic> mergedCtx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ..._formData,
    };

    final List<Map<String, dynamic>> fieldConfigs = List<Map<String, dynamic>>.from(widget.children);

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _formData[key] = value;
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with gradient (match CoreCollection)
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
                child: Icon(
                  widget.isAdd ? Icons.add_rounded : Icons.edit_outlined,
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
                      '${widget.isAdd ? 'Add' : 'Edit'} ${widget.itemLabel}',
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
              children: _buildFields(),
            ),
          ),
        ),

        // Bottom toolbar (match CoreCollection)
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
                  label: const Text('Cancel', style: TextStyle(fontSize: 13)),
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
                    // Close dialog first to avoid navigation issues
                    Navigator.of(context).pop();
                    // Delay save to ensure dialog is fully closed
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.onSave(_formData);
                    });
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(widget.isAdd ? 'Add' : 'Save', style: const TextStyle(fontSize: 13)),
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
    );
  }
}
