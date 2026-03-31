part of 'core_tree.dart';

/// Extension for tree navigation operations
extension _CoreTreeNavigationExt on _CoreTreeState {
  void navigateToChildren(Map<String, dynamic> parent) {
    final children = getChildren(parent['id']);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _safeSetState(() {
        _navigationStack.add({
          'parent': _currentParent,
          'items': List.from(_currentItems),
        });
        _currentParent = parent;
        _currentItems =
            children; // may be empty; shows empty state of this node

        // Apply permission filtering
        _currentItems = filterItemsByPermissions(_currentItems);

        initializeItemAnimations();
      });
    });
  }

  void navigateBack() {
    if (_navigationStack.isNotEmpty) {
      final previous = _navigationStack.removeLast();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _safeSetState(() {
          _currentParent = previous['parent'];
          _currentItems = List.from(previous['items']);

          // Apply permission filtering
          _currentItems = filterItemsByPermissions(_currentItems);

          initializeItemAnimations();
        });
      });
    }
  }
}
