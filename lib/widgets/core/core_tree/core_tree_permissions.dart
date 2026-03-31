part of 'core_tree.dart';

/// Extension for permission and level-based action restrictions
extension _CoreTreePermissionsExt on _CoreTreeState {
  /// Helper method to check if action is allowed at current level
  bool isActionAllowedAtLevel(String actionType) {
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

  /// Helper method to check if navigation to children is allowed
  bool isNavigationAllowed() {
    if (widget.levelRestrictions == null) return true;

    final restrictions = widget.levelRestrictions!;
    final currentLevel = _navigationStack.length;

    // Check maxLevel restriction
    final maxLevel = restrictions['maxLevel'] as int?;
    if (maxLevel != null && currentLevel >= maxLevel) {
      return false;
    }

    // Check preventChildCreation restriction
    final preventChildCreation = restrictions['preventChildCreation'] as bool?;
    if (preventChildCreation == true) {
      return false;
    }

    return true;
  }

  /// Helper method to check if next level icon should be shown
  bool shouldShowNextLevelIcon() {
    if (widget.levelRestrictions == null) return true;

    final restrictions = widget.levelRestrictions!;
    final showNextLevelIcon = restrictions['showNextLevelIcon'] as bool?;

    // If explicitly set to false, don't show
    if (showNextLevelIcon == false) {
      return false;
    }

    // If preventChildCreation is true, don't show
    final preventChildCreation = restrictions['preventChildCreation'] as bool?;
    if (preventChildCreation == true) {
      return false;
    }

    // Check maxLevel restriction
    final currentLevel = _navigationStack.length;
    final maxLevel = restrictions['maxLevel'] as int?;
    if (maxLevel != null && currentLevel >= maxLevel) {
      return false;
    }

    return true;
  }

  /// Helper method to check if action is allowed based on permissions
  bool isActionAllowedByPermission(
    String actionType, [
    Map<String, dynamic>? item,
  ]) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    switch (actionType) {
      case 'add':
        return permissions['canAdd'] ?? true;
      case 'edit':
        if (item != null) {
          return canEditItem(item);
        }
        return permissions['canEdit'] ?? true;
      case 'delete':
        if (item != null) {
          return canDeleteItem(item);
        }
        return permissions['canDelete'] ?? true;
      case 'footerActions':
        if (item != null) {
          return canAccessFooterActions(item);
        }
        return permissions['canAccessFooterActions'] ?? true;
      default:
        return true;
    }
  }

  /// Check if user can edit specific item
  bool canEditItem(Map<String, dynamic> item) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    // If user has global edit permission, allow
    if (permissions['canEdit'] == true) return true;

    // If user has no global edit permission, check item-specific permission
    if (permissions['canEdit'] == false) {
      // Allow edit if user is in charge of this specific item
      return isUserInChargeOfItem(item);
    }

    // Default fallback
    return isUserInChargeOfItem(item);
  }

  /// Check if user can delete specific item
  bool canDeleteItem(Map<String, dynamic> item) {
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
    return isUserInChargeOfItem(item);
  }

  /// Check if user can access footer actions for specific item
  bool canAccessFooterActions(Map<String, dynamic> item) {
    if (widget.permissions == null) return true;

    final permissions = widget.permissions!;

    // If user has global footer actions permission, allow
    if (permissions['canAccessFooterActions'] == true) return true;

    // If user has no global footer actions permission, check item-specific permission
    if (permissions['canAccessFooterActions'] == false) {
      // Allow footer actions if user is in charge of this specific item
      return isUserInChargeOfItem(item);
    }

    // Default fallback
    return isUserInChargeOfItem(item);
  }

  /// Check if current user is in charge of the item
  bool isUserInChargeOfItem(Map<String, dynamic> item) {
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

  /// Combined check for both level and permission restrictions
  bool isActionAllowed(String actionType, [Map<String, dynamic>? item]) {
    final levelAllowed = isActionAllowedAtLevel(actionType);
    final permissionAllowed = isActionAllowedByPermission(actionType, item);
    final result = levelAllowed && permissionAllowed;

    return result;
  }

  /// Filter items based on permissions (hide items user can't access)
  List<Map<String, dynamic>> filterItemsByPermissions(
    List<Map<String, dynamic>> items,
  ) {
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
    return getAccessibleItemsWithParents(items);
  }

  /// Get items user can access plus their parent items for navigation
  List<Map<String, dynamic>> getAccessibleItemsWithParents(
    List<Map<String, dynamic>> items,
  ) {
    final accessibleItems = <Map<String, dynamic>>[];
    final itemsUserCanAccess = <String>{};
    final parentIdsNeeded = <String>{};

    // First pass: Find ALL items in the entire tree that user has direct access to
    for (var item in _treeData) {
      // Search entire tree, not just current level
      if (isUserInChargeOfItem(item)) {
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

      if (itemsUserCanAccess.contains(itemId) ||
          parentIdsNeeded.contains(itemId)) {
        accessibleItems.add(item);
      }
    }

    return accessibleItems;
  }
}
