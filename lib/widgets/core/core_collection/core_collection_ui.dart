part of 'core_collection.dart';

extension _CoreCollectionUiExt on _CoreCollectionState {
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
                    _buildItemHeader(index, item, showEditIcon: true),
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
        opacity: 0.4,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemHeader(index, item, showEditIcon: true),
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
          SizedBox(
            width: 80,
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
    final itemItemDetail = {
      'value': item,
      'attribute': widget.itemDetail['attribute'] ?? {},
    };

    final parentCtx = widget.itemDetail['value'];
    final Map<String, dynamic> mergedCtx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ...item,
    };

    final List<Map<String, dynamic>> fieldConfigs =
        List<Map<String, dynamic>>.from(widget.children);

    final fields = CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) => _updateItem(index, key, value),
    );

    final List<Widget> wrappedFields = [];
    for (int i = 0; i < fields.length; i++) {
      if (i == 0) {
        wrappedFields.add(
          Padding(padding: const EdgeInsets.only(top: 11), child: fields[i]),
        );
      } else if (i == fields.length - 1) {
        wrappedFields.add(
          Container(margin: const EdgeInsets.only(bottom: 0), child: fields[i]),
        );
      } else {
        wrappedFields.add(fields[i]);
      }
    }

    return wrappedFields;
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
