import 'package:flutter/material.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'core_tree_edit_dialog.dart';
part 'core_tree_permissions.dart';
part 'core_tree_initialization.dart';
part 'core_tree_navigation.dart';
part 'core_tree_operations.dart';
part 'core_tree_ui.dart';

/// Core Tree Widget for hierarchical tree data structure
/// Supports navigation through levels and CRUD operations
/// Inspired by CoreCollection but with tree navigation capabilities
class CoreTree extends StatefulWidget {
  final String dataKey;
  final Map<String, dynamic> itemDetail;
  final String label;
  final String? hintText;
  final List<Map<String, dynamic>>
  children; // Field configurations for tree items
  final String? itemLabel; // Label for each item
  final String? addButtonText; // Custom text for add button
  final bool allowAdd;
  final bool allowEdit;
  final bool allowDelete;
  final Function(dynamic) onChanged;
  final bool required;
  final Map<String, dynamic>? summary; // Dynamic summary configuration
  final String? headerTemplate; // Template for header, e.g. "{itemNo} - {name}"
  final bool
  isUseUpdateAction; // When true, mark updates and collect removedRows
  final bool
  isOnItemDetailValue; // Storage mode: true => itemDetail.value[dataKey], false => itemDetail.tree
  final String?
  titleKey; // Which key to use as item title instead of 'name' (deprecated, use titleTemplate)
  final String?
  titleTemplate; // Template for item title, e.g. "{itemNo} - {name}"
  final List<Map<String, dynamic>>? footerActions; // Extra footer actions
  final void Function(
    BuildContext context,
    Map<String, dynamic> item,
    Map<String, dynamic> actionConfig,
  )?
  onFooterAction; // Callback for footer actions
  final List<String>?
  commonFields; // Fields that must always have a value (null if not provided)
  final Map<String, dynamic>?
  levelRestrictions; // Level-based action restrictions
  final Map<String, dynamic>? defaultValues; // Default values for tree fields
  final Map<String, dynamic>?
  permissions; // Permission-based action restrictions

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

  // Allow extracted part methods to safely update state
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
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
    initializeAnimations();
    initializeTreeData();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CoreTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemDetail != widget.itemDetail) {
      if (!_isSaving) {
        reloadDataPreserveNavigation();
      }
    }
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
      if (_currentParent != null &&
          (!headerCtx.containsKey('children') ||
              headerCtx['children'] is! List)) {
        // Get children from current parent context
        headerCtx['children'] = _currentItems;
      } else if (!headerCtx.containsKey('children') ||
          headerCtx['children'] is! List) {
        // Fallback to empty list if no children
        headerCtx['children'] = <Map<String, dynamic>>[];
      }

      headerTitle = renderTemplate(widget.headerTemplate!, headerCtx).trim();
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
                    colors: [
                      Color.fromARGB(255, 20, 65, 165),
                      Color.fromARGB(255, 20, 180, 230),
                    ], // green gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed: navigateBack,
                      tooltip: 'Back',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            softWrap: true,
                          ),
                          if (widget.hintText != null &&
                              widget.hintText!.isNotEmpty)
                            Text(
                              widget.hintText!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
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
                          Icon(
                            Icons.folder_open_rounded,
                            size: 56,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No items found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 50, top: 8),
                      itemCount: _currentItems.length,
                      itemBuilder: (context, index) =>
                          buildTreeItem(_currentItems[index], index),
                    ),
            ),
          ],
        ),

        // FAB on top of content
        if (widget.allowAdd && isActionAllowed('add'))
          Positioned(
            right: 8,
            bottom: 8,
            child: AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: FloatingAddButton(onPressed: addNewItem),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Dialog for editing tree items
