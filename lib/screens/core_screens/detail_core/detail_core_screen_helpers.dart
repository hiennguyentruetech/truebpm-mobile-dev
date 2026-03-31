part of 'detail_core_screen.dart';

/// Extension for helper utility methods
extension _DetailCoreScreenHelpersExt on _DetailCoreScreenState {
  /// Check if the current record is new (no ID)
  bool isNewRecord(CoreDetailProvider provider) {
    final itemDetail = provider.itemDetail?.value;
    if (itemDetail == null) return widget.listItem['action'] == 'NEW';

    final id = itemDetail['id'];
    return id == null || id.toString().isEmpty;
  }

  /// Check if the current record was created from "New" action in list
  bool isFromNewAction() {
    return widget.listItem['action'] == 'NEW';
  }

  /// Check if this operation should trigger list refresh (NEW or COPY -> SAVE)
  bool shouldRefreshListOnSave() {
    return isFromNewAction() || wasCopyOperation();
  }

  /// Check if this was originally a COPY operation that should refresh list on save
  bool wasCopyOperation() {
    // Check if we have cached COPY response in provider, indicating this was a COPY operation
    // Use the local provider instance to avoid depending on context lookup during lifecycle transitions
    return _provider.currentCachedAction == 'COPY';
  }
}
