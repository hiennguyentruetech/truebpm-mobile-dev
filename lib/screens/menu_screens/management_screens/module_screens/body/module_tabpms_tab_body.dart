import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'dart:async'; // Added for Timer

/// Tab body cho MODULE TABPMS (Table Application Permissions)
/// Xử lý phân quyền kết hợp table và application permissions
class ModuleTabpmsTabBody extends CoreTabBody {
  const ModuleTabpmsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleTabpmsTabBody> createState() => _ModuleTabpmsTabBodyState();
}

class _ModuleTabpmsTabBodyState extends CoreTabBodyState<ModuleTabpmsTabBody> {
  
  // Response data
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  
  // Caching mechanism to prevent widget recreation
  Widget? _cachedTreeWidget;
  
  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ModuleTabpmsTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update data when initialData changes (e.g., after save operation)
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
      // Clear cache when data changes
      _cachedTreeWidget = null;
    }
  }

  void _updateDataFromInitialData() {
    // Extract data from response dynamically
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    
    // Extract itemDetail dynamically
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    
    // Extract nested data from itemDetail dynamically
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    
    // Trigger rebuild if widget is already built
    if (mounted) {
      setState(() {});
    }
  }
  
  // Method to update module data
  void _onChanged(String key, dynamic value) {
    setState(() {
      if (key == 'tree' && value is Map<String, dynamic>) {
        // CoreTree sends complete itemDetail structure as value
        // Extract the tree data and update our structure correctly
        _itemDetail = Map<String, dynamic>.from(value);
        _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
        
        // Clear cache when tree data changes
        _cachedTreeWidget = null;
      } else if (key == 'grantPermission' && value is List) {
        // Special handling for grantPermission field with splitKey functionality
        // Check if values are already formatted (have userPermission wrapper)
        final formattedValue = value.map((item) {
          if (item is Map<String, dynamic>) {
            // Check if already formatted (has userPermission wrapper)
            if (item.containsKey('userPermission')) {
              return item; // Already formatted, return as-is
            }

            // Format raw option to userPermission wrapper
            return {
              'userPermission': {
                'id': item['id'] ?? item['userPermissionId'] ?? '',
                'name': item['name'] ?? item['permissionName'] ?? '',
                // Copy all other fields
                ...item.entries.where((entry) => 
                  entry.key != 'id' && 
                  entry.key != 'name' && 
                  entry.key != 'userPermissionId' && 
                  entry.key != 'permissionName'
                ).fold<Map<String, dynamic>>({}, (map, entry) {
                  map[entry.key] = entry.value;
                  return map;
                }),
              }
            };
          } else if (item is String) {
            // If item is string (ID), create userPermission object with ID
            return {
              'userPermission': {
                'id': item,
                'name': item, // Fallback name
              }
            };
          }
          return item;
        }).toList();
        
        // Update module data with formatted value
        _moduleData[key] = formattedValue;
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);

      } else {
        // Handle other field types normally
        _moduleData[key] = value;
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      }
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onDataChanged != null) {
        widget.onDataChanged!(_response);
      }
    });
  }
  
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
      future: _buildFieldConfig(),
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

  Future<Map<String, dynamic>> _buildFieldConfig() async {
    // Simulate async operation to match the pattern
    await Future.delayed(const Duration(milliseconds: 100));
    return _buildBaseFieldConfig();
  }

  Map<String, dynamic> _buildBaseFieldConfig() {
    return {
      'key': 'tree',
      'widget': 'tree',
      'label': 'Table Application Permissions Configuration',
      'headerTemplate': '{stt} - {actionMap.name}',
      'isUseUpdateAction': true,
      'isOnItemDetailValue': false, // Mode 2
      'titleTemplate': '{stt} - {tabModuleMap.name}',
      'allowAdd': true,
      'allowEdit': true,
      'allowDelete': true,
      
      // Giới hạn chỉ ở level 0 - không cho phép đi vào cấp con
      'levelRestrictions': {
        'minLevelForAdd': 0,           // Chỉ cho phép Add ở level 0
        'minLevelForEdit': 0,          // Chỉ cho phép Edit ở level 0
        'minLevelForDelete': 0,        // Chỉ cho phép Delete ở level 0
        'minLevelForFooterActions': 0, // Chỉ cho phép Footer Actions ở level 0
        'maxLevel': 0,                 // Giới hạn tối đa chỉ ở level 0
        'preventChildCreation': true,  // Không cho phép tạo cấp con
        'showNextLevelIcon': false,    // Không hiển thị icon next level
      },
      
      // Summary shows stt, actionMap, grantPermission, isDisabled, isHidden
      'summary': {
        'layout': 'row',
        'fields': [
          {'key': 'grantPermission', 'label': 'Grant Permission', 'collectionTemplate': '{userPermission.name}', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20'},
          {'key': 'isDisabled', 'label': 'Disabled', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20'},
          {'key': 'isHidden', 'label': 'Hidden', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20'},
        ]
      },
      
      // Editable fields in the dialog
      'children': [
        {'key': 'stt', 'label': 'STT', 'required': true, 'type': 'number'},
        {
          'key': 'grantPermission',
          'widget': 'select',
          'selectType': 'multiple',
          'label': 'Grant Permission',
          'data': 'DROPDOWN.USRPER',
          'display': 'userPermission.name', // For input field display
          'dropdownDisplay': 'name', // For dropdown/popup display
          'splitKey': true, // Enable split key functionality
          'required': false,
        },
        {
          'key': 'isDisabled',
          'widget': 'checkbox',
          'label': 'Disabled',
          'checkboxStyle': 'switch',
        },
        {
          'key': 'isHidden',
          'widget': 'checkbox',
          'label': 'Hidden',
          'checkboxStyle': 'switch',
        },
      ],
    };
  }

  @override
  bool validateData() {
    return CoreDynamicFields.validateData(
      context: context,
      moduleData: _moduleData,
      itemDetail: _itemDetail,
    );
  }

  Map<String, dynamic> prepareDataForSave() {
    return Map<String, dynamic>.from(_moduleData);
  }

  @override
  Future<Map<String, dynamic>> loadTabSpecificData() async {
    // No-op, data provided by provider initialData
    return {};
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement actual API call
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement actual API call
  }
}
