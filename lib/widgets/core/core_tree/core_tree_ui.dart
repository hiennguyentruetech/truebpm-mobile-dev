part of 'core_tree.dart';

/// Extension for tree UI building and rendering
extension _CoreTreeUIExt on _CoreTreeState {
  Widget buildTreeItem(Map<String, dynamic> item, int index) {
    final summaryWidget = buildCollectionStyleSummary(item);

    // Title for item header, using titleTemplate or titleKey
    String? title;

    // Priority: titleTemplate > titleKey > default fields
    if (widget.titleTemplate != null && widget.titleTemplate!.isNotEmpty) {
      // Enhance item context with children count for template rendering
      final Map<String, dynamic> enhancedItem = Map<String, dynamic>.from(item);

      // Get actual children count from tree data
      final String itemId = item['id']?.toString() ?? '';
      final actualChildren = _treeData
          .where((treeItem) => treeItem['parentId']?.toString() == itemId)
          .toList();

      // Set the actual children for template rendering
      enhancedItem['children'] = actualChildren;

      // Use template rendering with enhanced context
      title = renderTemplate(widget.titleTemplate!, enhancedItem).trim();
      if (title.isEmpty)
        title = null; // Fall back to default if template returns empty
    }

    if (title == null || title.isEmpty) {
      // Fall back to titleKey if provided
      final keyPref = widget.titleKey;
      if (keyPref != null && keyPref.isNotEmpty) {
        title = item[keyPref]?.toString();
      }
    }

    // Final fallback to default fields
    title ??=
        item['name']?.toString() ??
        item['displayText']?.toString() ??
        'Unnamed';

    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gradient header with navigate icon - tap to edit
        InkWell(
          onTap: (widget.allowEdit && isActionAllowed('edit', item))
              ? () => editItem(item, index)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 145, 17, 54),
                  const Color.fromARGB(255, 22, 140, 185),
                ], // purple-blue
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    softWrap: true,
                  ),
                ),
                // Navigate to children icon
                if (shouldShowNextLevelIcon())
                  InkWell(
                    onTap: isNavigationAllowed()
                        ? () => navigateToChildren(item)
                        : null,
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
          onTap: (widget.allowEdit && isActionAllowed('edit', item))
              ? () => editItem(item, index)
              : null,
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
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Extra actions from config
              if ((widget.footerActions ?? const []).isNotEmpty &&
                  isActionAllowed('footerActions', item))
                ...buildFooterActionButtons(item),
              // Spacer
              const Spacer(),
              // Delete isolated at far right
              if (widget.allowDelete && isActionAllowed('delete', item))
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  color: Colors.red[400],
                  onPressed: () => performDelete(item),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return Dismissible(
      key: Key(item['id']?.toString() ?? ''),
      direction: widget.allowDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: widget.allowDelete ? (_) => performDelete(item) : null,
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

  List<Widget> buildFooterActionButtons(Map<String, dynamic> item) {
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

  /// CoreCollection-style summary rendering
  Widget buildCollectionStyleSummary(Map<String, dynamic> item) {
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
      if (conf.containsKey('visibleWhen') &&
          !evaluateVisibility(conf['visibleWhen'], ctx))
        continue;
      final String keyPath = conf['key']?.toString() ?? '';
      if (keyPath.isEmpty) continue;

      dynamic raw = getByPath(ctx, keyPath);
      if (raw == null) continue;

      String value = '';

      // Handle collection with template
      if (raw is List && conf['collectionTemplate'] != null) {
        final String template = conf['collectionTemplate'].toString();
        final List<String> renderedItems = [];
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            final rendered = renderTemplate(template, item).trim();
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
      final String? widgetType = conf['widget']?.toString();
      final String? datetimeType = conf['datetimeType']?.toString();
      if (widgetType == 'datetime' && value.isNotEmpty) {
        value = formatDateTimeValue(
          value,
          datetimeType,
          conf['displayFormat']?.toString(),
        );
      }

      final String label = conf['label']?.toString() ?? keyPath.split('.').last;
      final String? suffix = conf['suffix']?.toString();
      if (suffix != null && suffix.isNotEmpty && widgetType != 'datetime') {
        value = '$value$suffix';
      }

      final String fieldLayout = conf['layout']?.toString() ?? defaultLayout;

      rows.add(
        buildStackedRow(
          label,
          value,
          labelColor: parseColor(conf['labelColor']) ?? Colors.grey.shade700,
          valueColor: parseColor(conf['valueColor']) ?? Colors.black87,
          bgColor: parseColor(conf['bgColor']) ?? Colors.white,
          borderColor: parseColor(conf['borderColor']) ?? Colors.grey.shade200,
          layout: fieldLayout,
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  /// Format datetime values for display
  String formatDateTimeValue(
    String value,
    String? datetimeType,
    String? displayFormat,
  ) {
    return Functions().formatDateTimeValue(value, datetimeType, displayFormat);
  }

  /// Get value from nested object using dot notation
  static dynamic getByPath(Map<String, dynamic> map, String path) {
    return Functions().getByPath(map, path);
  }

  /// Evaluate visibility condition
  static bool evaluateVisibility(
    dynamic visibleWhen,
    Map<String, dynamic> context,
  ) {
    return Functions().evaluateVisibility(visibleWhen, context);
  }

  /// Render a simple template like "{itemNo} - {name}" using dot-paths from context
  String renderTemplate(String template, Map<String, dynamic> context) {
    return Functions().renderTemplate(template, context);
  }

  /// Parse color from various formats
  Color? parseColor(dynamic color) {
    return Functions().parseColor(color);
  }

  /// Build a stacked or horizontal row for summary display
  Widget buildStackedRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    Color? bgColor,
    Color? borderColor,
    String? layout,
  }) {
    if (layout == 'row') {
      return buildHorizontalRow(
        label,
        value,
        labelColor: labelColor,
        valueColor: valueColor,
        bgColor: bgColor,
        borderColor: borderColor,
      );
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

  /// Build a horizontal row layout for summary display
  Widget buildHorizontalRow(
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
}
