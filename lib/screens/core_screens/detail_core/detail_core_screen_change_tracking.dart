part of 'detail_core_screen.dart';

/// Extension for change tracking functionality
extension _DetailCoreScreenChangeTrackingExt on _DetailCoreScreenState {
  /// Initialize change tracking with current data
  void initializeChangeTracking() {
    if (_provider.rawResponse != null) {
      // Legacy fallback snapshots (kept for compatibility)
      _originalData = Map<String, dynamic>.from(_provider.rawResponse!);
      _currentData = Map<String, dynamic>.from(_provider.rawResponse!);

      // New sanitized editable snapshot
      _originalEditableSnapshot = buildEditableSnapshot(_provider);
      _screenInitTime ??= DateTime.now(); // set only first time
      _hasUnsavedChanges = false;
      if (_debugDirtyTracking) {
        debugPrint(
          '[DirtyTrack] Baseline initialized. Keys=${_originalEditableSnapshot.keys.length}',
        );
      }
    }
  }

  /// Check if there are unsaved changes by comparing current data with original data
  bool checkForUnsavedChanges() {
    if (_provider.rawResponse == null) return false;

    // Suppression windows (initial load or shortly after tab switch)
    final now = DateTime.now();
    if (_screenInitTime != null &&
        now.difference(_screenInitTime!) < _initialSuppression) {
      if (_debugDirtyTracking)
        debugPrint('[DirtyTrack] Suppressed (initial load window)');
      return false;
    }
    if (_lastTabChangeTime != null &&
        now.difference(_lastTabChangeTime!) < _tabSwitchSuppression) {
      if (_debugDirtyTracking)
        debugPrint('[DirtyTrack] Suppressed (tab switch window)');
      return false;
    }

    final currentSnapshot = buildEditableSnapshot(_provider);
    final changed = deepCompareData(_originalEditableSnapshot, currentSnapshot);
    if (_debugDirtyTracking && changed) {
      debugPrint('[DirtyTrack] Detected change.');
    }
    return changed;
  }

  /// Deep comparison of two data maps
  bool deepCompareData(dynamic data1, dynamic data2) {
    if (data1.runtimeType != data2.runtimeType) return true;

    if (data1 is Map) {
      if (data2 is! Map) return true;
      if (data1.length != data2.length) return true;

      for (final key in data1.keys) {
        if (!data2.containsKey(key)) return true;
        if (deepCompareData(data1[key], data2[key])) return true;
      }
      return false;
    } else if (data1 is List) {
      if (data2 is! List) return true;
      if (data1.length != data2.length) return true;

      for (int i = 0; i < data1.length; i++) {
        if (deepCompareData(data1[i], data2[i])) return true;
      }
      return false;
    } else {
      return data1 != data2;
    }
  }

  /// Build a sanitized snapshot focusing on editable content only
  Map<String, dynamic> buildEditableSnapshot(CoreDetailProvider provider) {
    final raw = provider.rawResponse;
    if (raw == null) return {};

    // Prefer nested itemDetail.value if present
    dynamic itemDetail = raw['itemDetail'];
    if (itemDetail is Map<String, dynamic>) {
      if (itemDetail.containsKey('value') &&
          itemDetail['value'] is Map<String, dynamic>) {
        itemDetail = itemDetail['value'];
      } else if (itemDetail.containsKey('itemDetail') &&
          itemDetail['itemDetail'] is Map<String, dynamic>) {
        // Some responses nest deeper
        final nested = itemDetail['itemDetail'];
        if (nested is Map<String, dynamic> && nested.containsKey('value')) {
          itemDetail = nested['value'];
        }
      }
    }

    if (itemDetail is! Map<String, dynamic>) {
      return {};
    }

    final volatileKeys = {
      'lastModifiedDate',
      'lastModified',
      'lastUpdate',
      'updatedAt',
      'updatedTime',
      'status',
      'statusHistory',
      'logs',
      'attachments',
      'comments',
      '_timestamp',
    };

    dynamic sanitize(dynamic input) {
      if (input is Map<String, dynamic>) {
        final result = <String, dynamic>{};
        input.forEach((k, v) {
          if (volatileKeys.contains(k)) return; // skip volatile
          result[k] = sanitize(v);
        });
        return result;
      } else if (input is List) {
        return input.map(sanitize).toList();
      } else {
        return input; // primitive
      }
    }

    final sanitized = sanitize(itemDetail);
    if (sanitized is Map<String, dynamic>) {
      return sanitized;
    }
    return {};
  }

  /// Handle data changes from widgets
  void handleDataChanged(
    CoreDetailProvider provider,
    Map<String, dynamic> updatedData,
  ) {
    provider.updateRawResponse(updatedData);

    // Check for unsaved changes
    _hasUnsavedChanges = checkForUnsavedChanges();
  }

  /// Reset change tracking after successful save
  void resetChangeTracking() {
    if (_provider.rawResponse != null) {
      _originalData = Map<String, dynamic>.from(_provider.rawResponse!);
      _currentData = Map<String, dynamic>.from(_provider.rawResponse!);
      _originalEditableSnapshot = buildEditableSnapshot(_provider);
      _hasUnsavedChanges = false;
      if (_debugDirtyTracking) debugPrint('[DirtyTrack] Baseline reset.');
    }
  }
}
