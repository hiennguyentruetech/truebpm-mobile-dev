import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/popups/comment_popup.dart';
import 'package:truebpm/widgets/popups/document_popup.dart';

/// Tab body for PRJMGT PCMDRD (CMDR)
class ProjectManagementPcmdrdTabBody extends CoreTabBody {
  const ProjectManagementPcmdrdTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ProjectManagementPcmdrdTabBody> createState() => _ProjectManagementPcmdrdTabBodyState();
}

class _ProjectManagementPcmdrdTabBodyState extends CoreTabBodyState<ProjectManagementPcmdrdTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ProjectManagementPcmdrdTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    if (mounted) setState(() {});
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      if (key == 'tree' && value is Map<String, dynamic>) {
        // CoreTree sends complete itemDetail structure as value
        // Extract the tree data and update our structure correctly
        _itemDetail = Map<String, dynamic>.from(value);
        _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      } else {
        // Handle other field types normally
        _moduleData[key] = value;
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      }
    });
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildTabContent(context);
  }

  String? _lastUserIdForCache;
  Widget? _cachedTreeWidget;

  @override
  Widget buildTabContent(BuildContext context) {
    if (_itemDetail.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use cached widget if available to prevent recreation
    if (_cachedTreeWidget != null) {
      return _cachedTreeWidget!;
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _buildFieldConfigWithPermissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final fieldConfig = snapshot.data ?? _buildBaseFieldConfig();

        final fields = CoreDynamicFields.buildFields(
          fieldConfigs: [fieldConfig],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        );

        // Cache the tree widget to prevent recreation
        _cachedTreeWidget = Padding(
          padding: const EdgeInsets.all(8),
          child: fields.isNotEmpty ? fields.first : const SizedBox.shrink(),
        );

        return _cachedTreeWidget!;
      },
    );
  }

  Future<Map<String, dynamic>> _buildFieldConfigWithPermissions() async {
    final baseConfig = _buildBaseFieldConfig();

    try {
      final authService = AuthService();
      final userInfo = await authService.getSavedUserInfo();

      if (userInfo == null) {
        // No user info, use base config without permissions
        return baseConfig;
      }

      final currentUserId = userInfo.id;

      // Clear cached widget when user changes
      if (_lastUserIdForCache != currentUserId) {
        _cachedTreeWidget = null;
      }

      final itemValue = _itemDetail['value'] as Map<String, dynamic>? ?? {};

      // Check if user is in privileged roles
      final pmUserId = itemValue['pmUserId']?['id'];
      final projectSecretaryId = itemValue['projectSecretaryId']?['id'];
      final projectCoordinatorId = itemValue['projectCoordinatorId']?['id'];
      final adminUserId = itemValue['adminUserId']?['id'];

      final isPrivilegedUser = currentUserId == pmUserId ||
                              currentUserId == projectSecretaryId ||
                              currentUserId == projectCoordinatorId ||
                              currentUserId == adminUserId;



      // Build permissions config
      final permissions = {
        'currentUserId': currentUserId,
        'canAdd': isPrivilegedUser,
        'canEdit': isPrivilegedUser,
        'canDelete': isPrivilegedUser,
        'canAccessFooterActions': isPrivilegedUser,
      };

      // Add permissions to config
      baseConfig['permissions'] = permissions;

      // Cache the result
      _lastUserIdForCache = currentUserId;

      return baseConfig;
    } catch (e) {
      // Error getting user info, use base config without permissions
      debugPrint('Error getting user permissions: $e');
      return baseConfig;
    }
  }

  Map<String, dynamic> _buildBaseFieldConfig() {
    // Build via CoreDynamicFields; use Mode 2: store under itemDetail.tree
    return {
      'key': 'tree',
      'widget': 'tree',
      'label': 'Project CMDR Structure',
      'headerTemplate': '{itemNo} - ({name})',
      'isUseUpdateAction': true,
      'isOnItemDetailValue': false, // Mode 2
      'titleTemplate': 'No {itemNo} - {name}',
      'footerActions': [
        {'type': 'comment', 'tooltip': 'Comments', 'color': '#4545AF'}, // dark blue
        {'type': 'document', 'tooltip': 'Documents', 'color': '#7C4DFF'}, // deep purple
      ],

      // Level-based action restrictions
      'levelRestrictions': {
        'minLevelForAdd': 1,           // Only allow Add from level 1 onwards (not at root level 0)
        'minLevelForEdit': 1,          // Only allow Edit from level 1 onwards (not at root level 0)
        'minLevelForDelete': 1,        // Only allow Delete from level 1 onwards (not at root level 0)
        'minLevelForFooterActions': 1, // Only allow Footer Actions from level 1 onwards (not at root level 0)
      },

      // Default values for tree fields
      'defaultValues': {
        'completeness': 0.0,           // Default completeness to 0 instead of null
      },
      'onFooterAction': (BuildContext ctx, Map<String, dynamic> item, Map<String, dynamic> action) async {
        final type = (action['type'] ?? '').toString();

        // Get current user info
        final authService = AuthService();
        final userInfo = await authService.getSavedUserInfo();

        if (userInfo == null) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('User information not available'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Create listItem from the selected item's value
        final listItem = Map<String, dynamic>.from(item);

        try {
          if (type == 'comment') {
            // Show comment popup directly
            if (ctx.mounted) {
              showDialog(
                context: ctx,
                builder: (context) => CommentPopup(
                  moduleCode: 'PRJMGT',
                  tabModuleCode: 'CMDRMD.CMT',
                  listItem: listItem,
                  userInfo: userInfo,
                ),
              );
            }
          } else if (type == 'document') {
            // Show document popup directly
            if (ctx.mounted) {
              showDialog(
                context: ctx,
                builder: (context) => DocumentPopup(
                  moduleCode: 'PRJMGT',
                  tabModuleCode: 'CMDRMD',
                  listItem: listItem,
                  userInfo: userInfo,
                ),
              );
            }
          }
        } catch (e) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      'allowAdd': true,
      'allowEdit': true,
      'allowDelete': true,
      // Common fields that must always have a value (null if not provided)
      'commonFields': [
        'itemNo',
        'name',
        'finishDate',
        'statusMap',
        'completeness',
        'isPaymentMilestone',
        'paymentStatusMap',
        'paymentGroup',
        'inChargePerson',
        'isGenerateTask',
        'isGenerateFolder',
      ],
      // Summary shows itemNo, name, completeness first
      'summary': {
        'layout': 'row',
        'fields': [
              // {'key': 'itemNo', 'label': 'No', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12'},
              {'key': 'finishDate', 'label': 'Finish Date', 'widget': 'datetime', 'datetimeType': 'date', 'displayFormat': 'dd/MM/yyyy', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20'},
              {'key': 'completeness', 'label': 'Completeness', 'suffix': '%', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20', 'layout': 'row'},
              {'key': 'statusMap.name', 'label': 'Work Status', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20', 'layout': 'row'},
              {'key': 'paymentStatusMap.name', 'label': 'Payment Status', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20', 'layout': 'row'},
              {'key': 'inChargePerson', 'label': 'Person in charge', 'collectionTemplate': '{person.fullName}', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20', 'layout': 'row'},
            ]
          },
          // Editable fields in the dialog
          'children': [
            {'key': 'itemNo', 'label': 'No', 'required': true},
            {'key': 'name', 'label': 'Item', 'required': true},
            {'key': 'finishDate', 'widget': 'datetime', 'label': 'Finish Date', 'datetimeType': 'date', 'displayFormat': 'ddMMyyyy'},
            {'key': 'statusMap', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Work Status', 'data': 'DROPDOWN.PRJMGT/WORKSTATUS', 'display': 'name'},
            {'key': 'completeness', 'widget': 'input', 'label': 'Completeness', 'type': 'number', 'suffix': '%', 'decimalPlaces': 2, 'minValue': 0, 'maxValue': 100},
            {'key': 'isPaymentMilestone', 'widget': 'checkbox', 'label': 'Payment Milestone', 'checkboxStyle': 'switch'},
            {'key': 'paymentStatusMap', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Payment Status', 'data': 'DROPDOWN.PRJMGT/PAYMENTSTATUS', 'display': 'name'},
            {'key': 'paymentGroup', 'widget': 'input', 'label': 'Payment Group', 'type': 'number'},
            {
              'key': 'inChargePerson',
              'widget': 'collection',
              'label': 'In Charge Person',
              'children': [
                {
                  'key': 'isOwner',
                  'widget': 'checkbox',
                  'label': 'Is Owner',
                  'checkboxStyle': 'switch'
                },
                {
                  'key': 'person',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Person',
                  'data': 'DROPDOWN.PRJMGT/USER',
                  'display': 'fullName',
                  'required': true,
                },
                {
                  'key': 'role',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Role',
                  'data': 'DROPDOWN.PRJMGT/ROLE',
                  'display': 'name',
                  'required': true,
                },
              ],
            },
            // {'key': 'isGenerateTask', 'widget': 'checkbox', 'label': 'Generate Task'},
            // {'key': 'isGenerateFolder', 'widget': 'checkbox', 'label': 'Generate Folder'},
          ],
    };
  }
}
