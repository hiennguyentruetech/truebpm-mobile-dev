part of 'core_collection.dart';

/// Summary rendering and display helpers for CoreCollection items
extension _CoreCollectionSummaryExt on _CoreCollectionState {
  /// Build summary display for a collection item in modal mode
  Widget _buildItemSummary(Map<String, dynamic> item) {
    final summaryCfg = widget.summary;
    if (item.isEmpty) return _buildTapToEditHint();

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
      if (conf.containsKey('visibleWhen') &&
          !_evaluateVisibility(conf['visibleWhen'], ctx))
        continue;
      final String keyPath = conf['key']?.toString() ?? '';
      if (keyPath.isEmpty) continue;

      dynamic raw = _getByPath(ctx, keyPath);
      if (raw == null) continue;
      if (raw is Map && conf['display'] != null) raw = raw[conf['display']];
      String value = raw?.toString() ?? '';
      if (value.isEmpty || value == 'null') continue;

      // Check if this is a datetime field and format accordingly
      final String? widget = conf['widget']?.toString();
      final String? type = conf['type']?.toString();
      final String? datetimeType = conf['datetimeType']?.toString();
      if ((widget == 'datetime' || type == 'date') && value.isNotEmpty) {
        value = _formatDateTimeValue(
          value,
          datetimeType ?? 'date',
          conf['displayFormat']?.toString(),
        );
      }

      // Check if this is a number field and format accordingly
      if ((type == 'number' || type == 'currency') && value.isNotEmpty) {
        final decimalPlaces = conf['decimalPlaces'] as int? ?? 0;
        value = _formatNumberDisplay(value, decimalPlaces: decimalPlaces);
      }

      final String label = conf['label']?.toString() ?? keyPath.split('.').last;
      final String? suffix = conf['suffix']?.toString();
      if (suffix != null && suffix.isNotEmpty && widget != 'datetime') {
        value = '$value$suffix';
      }

      // Get layout from individual field config, fallback to summary default, then 'row'
      final String fieldLayout = conf['layout']?.toString() ?? defaultLayout;

      rows.add(
        _buildStackedRow(
          label,
          value,
          labelColor: _parseColor(conf['labelColor']) ?? Colors.grey.shade700,
          valueColor: _parseColor(conf['valueColor']) ?? Colors.black87,
          bgColor: _parseColor(conf['bgColor']) ?? Colors.white,
          borderColor: _parseColor(conf['borderColor']) ?? Colors.grey.shade200,
          layout: fieldLayout, // Use field-specific layout
        ),
      );
    }

    return rows.isEmpty
        ? _buildTapToEditHint()
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  /// Hint shown when an item has no data yet in modal mode
  Widget _buildTapToEditHint() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.touch_app_outlined,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to add details',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Click here to fill in the information',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.blue.shade400,
            size: 16,
          ),
        ],
      ),
    );
  }

  /// Build stacked or horizontal row for summary item display
  Widget _buildStackedRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    Color? bgColor,
    Color? borderColor,
    String? layout,
  }) {
    // Support both 'stacked' (default) and 'row' layouts
    if (layout == 'row') {
      return _buildHorizontalRow(
        label,
        value,
        labelColor: labelColor,
        valueColor: valueColor,
        bgColor: bgColor,
        borderColor: borderColor,
      );
    }

    // Default stacked layout
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label section with full width
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
          // Value section with full width
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

  /// Build horizontal (side-by-side) row for summary item display
  Widget _buildHorizontalRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: IntrinsicHeight(
        // Make both containers have same height
        child: Row(
          children: [
            // Label section with 30% width
            Expanded(
              flex: 37, // 30% width (3/10)
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    bottomLeft: Radius.circular(0),
                  ),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.shade300,
                  ),
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
                      height: 1.3, // Match value text height
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3, // Allow same maxLines as value
                  ),
                ),
              ),
            ),
            // Value section with 70% width
            Expanded(
              flex: 63, // 70% width (7/10)
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                  border: Border(
                    top: BorderSide(color: borderColor ?? Colors.grey.shade300),
                    right: BorderSide(
                      color: borderColor ?? Colors.grey.shade300,
                    ),
                    bottom: BorderSide(
                      color: borderColor ?? Colors.grey.shade300,
                    ),
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

  /// Build total summary display for entire collection
  Widget _buildTotalSummary() {
    if (widget.totalSummary == null || _items.isEmpty) {
      return const SizedBox.shrink();
    }

    final config = widget.totalSummary!;
    final totalKey = config['key'] as String? ?? 'total';
    final label = config['label'] as String? ?? 'Total';
    // format not needed since we use _formatNumberDisplay
    final suffix = config['suffix'] as String? ?? '';
    final bgColor = config['bgColor'] as String? ?? '#E8F5E8';
    final borderColor = config['borderColor'] as String? ?? '#A5D6A7';
    final labelColor = config['labelColor'] as String? ?? '#2E7D32';
    final valueColor = config['valueColor'] as String? ?? '#1B5E20';

    // Calculate total from all items
    double total = 0.0;
    for (final item in _items) {
      final value = item[totalKey];
      if (value is num) {
        total += value.toDouble();
      } else if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          total += parsed;
        }
      }
    }

    // Format the total using our custom EU-style formatter with decimalPlaces = 0
    String formattedTotal = _formatNumberDisplay(total, decimalPlaces: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _hexToColor(bgColor),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _hexToColor(borderColor), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _hexToColor(labelColor),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$formattedTotal$suffix',
            style: TextStyle(
              color: _hexToColor(valueColor),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Convert hex color string to Color object
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
