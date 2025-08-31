import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/loading_overlay.dart';

/// Tab body cho MODULE TBPMS (Table Permissions)
/// Xử lý phân quyền table-level permissions sử dụng CoreTree
class ModuleTbpmsTabBody extends CoreTabBody {
  const ModuleTbpmsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleTbpmsTabBody> createState() => _ModuleTbpmsTabBodyState();
}

class _ModuleTbpmsTabBodyState extends CoreTabBodyState<ModuleTbpmsTabBody> {
  
  // Response data
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  
  // Caching mechanism to prevent widget recreation
  Widget? _cachedTreeWidget;
  
  // Local state for dropdowns (to avoid re-rendering)
  dynamic _currentStatusId;
  dynamic _currentTabModuleId;
  
  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ModuleTbpmsTabBody oldWidget) {
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
    
    // Initialize local dropdown state
    final Map<String, dynamic>? dataSelect = _itemDetail['value']?['dataSelect'];
    _currentStatusId = dataSelect?['statusId'];
    _currentTabModuleId = dataSelect?['tabModuleId'];
    
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
        
        // Debug: print('🔄 Formatted grantPermission with splitKey: $formattedValue');
        // Debug: print('  • Input value: $value');
        // Debug: print('  • Formatted value: $formattedValue');
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

        return Column(
          children: [
            // Filter dropdowns section
            _buildFilterDropdowns(),
            const SizedBox(height: 16),
            
                    // Debug button for testing grantPermission logic with splitKey
        if (widget.moduleCode == 'MODULE') // Only show in debug mode
          _buildDebugTestButton(),
            
            // Tree content
            Expanded(child: _cachedTreeWidget!),
          ],
        );
      },
    );
  }

  /// Debug test button để kiểm tra logic grantPermission với splitKey
  Widget _buildDebugTestButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Test data structure
              final testData = [
                {
                  'id': '4E346B64-947E-4094-8A30-E6AF8CAA9ECB',
                  'name': 'All Permissions'
                },
                {
                  'id': '1923CD49-472C-4F57-A477-F6879EFA0CA1',
                  'name': 'All Permission Except HR & Accountant'
                }
              ];
              
              // Debug: print('🧪 Testing grantPermission logic with splitKey:');
              // Debug: print('  • Test data: $testData');
              
              // Test format với userPermission wrapper
              _onChanged('grantPermission', testData);
              
              // Debug: print('  • After format: ${_moduleData['grantPermission']}');
            },
            child: const Text('🧪 Test GrantPermission Logic with SplitKey'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Test clear data
              _onChanged('grantPermission', []);
              
              // Debug: print('🧹 Cleared grantPermission data');
            },
            child: const Text('🧹 Clear GrantPermission Data'),
          ),
        ],
      ),
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
      'label': 'Table Permissions Configuration',
      'headerTemplate': '{stt} - {actionMap.name}',
      'isUseUpdateAction': true,
      'isOnItemDetailValue': false, // Mode 2
      'titleTemplate': '{stt} - {actionMap.name}',
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
          'key': 'actionMap',
          'widget': 'select',
          'selectType': 'dropdown',
          'label': 'Action',
          'data': 'DROPDOWN.MODULE.TOOLBAR.ACTION',
          'display': 'name',
          'required': true,
        },
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

  Widget _buildFilterDropdowns() {
    // Get current moduleId from itemDetail.value.id
    final String? moduleId = _itemDetail['value']?['id']?.toString();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status dropdown - 1 dòng
          _buildStatusDropdown(moduleId, _currentStatusId),
          const SizedBox(height: 12),
          
          // Tab Module dropdown - 1 dòng
          _buildTabModuleDropdown(moduleId, _currentTabModuleId),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(String? moduleId, dynamic defaultStatusId) {
    final List<Map<String, dynamic>> fieldConfigs = [
      {
        'key': 'statusId',
        'widget': 'select',
        'selectType': 'dropdown',
        'label': 'Status',
        'data': 'DROPDOWN.MODULE.TOOLBAR.STATUS?moduleId=$moduleId',
        'display': 'name',
        'required': false,
      }
    ];

    final itemDetail = {
      'value': {'statusId': defaultStatusId},
      'attribute': {},
    };

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemDetail,
      moduleData: {'statusId': defaultStatusId},
      onChanged: (key, value) => _onFilterChanged('statusId', value),
    ).first;
  }

  Widget _buildTabModuleDropdown(String? moduleId, dynamic defaultTabModuleId) {
    final List<Map<String, dynamic>> fieldConfigs = [
      {
        'key': 'tabModuleId',
        'widget': 'select',
        'selectType': 'dropdown',
        'label': 'Tab Module',
        'data': 'DROPDOWN.MODULE.TOOLBAR.TABMODULE?moduleId=$moduleId',
        'display': 'name',
        'required': false,
      }
    ];

    final itemDetail = {
      'value': {'tabModuleId': defaultTabModuleId},
      'attribute': {},
    };

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemDetail,
      moduleData: {'tabModuleId': defaultTabModuleId},
      onChanged: (key, value) => _onFilterChanged('tabModuleId', value),
    ).first;
  }

  void _onFilterChanged(String key, dynamic value) {
    // Update local state immediately (no setState to avoid re-render)
    if (key == 'statusId') {
      _currentStatusId = value;
    } else if (key == 'tabModuleId') {
      _currentTabModuleId = value;
    }

    // Trigger API call to reload data
    _triggerDataReload();
  }

  void _triggerDataReload() {
    // Get current values from local state
    final String? moduleId = _itemDetail['value']?['id']?.toString();
    final dynamic statusId = _currentStatusId;
    final dynamic tabModuleId = _currentTabModuleId;

    if (moduleId == null) return;

    // Prepare payload for API call
    final Map<String, dynamic> payload = {
      "user": {
        "id": "4EDCE3A5-898E-46E1-9812-11FE5B8A16BC",
        "code": "admintest_1",
        "fullName": "System Administrator",
        "phone": "909682278",
        "email": "admintest@mailinator.com",
        "personalEmail": null,
        "position": "CEO",
        "createdDate": "2023-03-17T15:17:45Z",
        "managerFullName": null,
        "roles": []
      },
      "moduleCode": "MODULE",
      "tabModuleCode": "TBPMS",
      "listItem": {
        "dataSelect": {
          "statusId": statusId,
          "tabModuleId": tabModuleId,
        },
        "id": moduleId,
        "code": _itemDetail['value']?['code'] ?? "MODULE",
        "name": _itemDetail['value']?['name'] ?? "Module",
        "moduleId": moduleId
      }
    };

    // Show loading overlay using existing LoadingOverlay
    context.showLoading(message: 'Reloading data...');

    // TODO: Implement actual API call here
    // Example:
    // await _apiService.reloadModuleData(payload);
    
    // For now, simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Hide loading overlay
        context.hideLoading();
        
        // Update itemDetail with new values
        setState(() {
          if (_itemDetail['value'] == null) {
            _itemDetail['value'] = {};
          }
          if (_itemDetail['value']['dataSelect'] == null) {
            _itemDetail['value']['dataSelect'] = {};
          }
          _itemDetail['value']['dataSelect']['statusId'] = _currentStatusId;
          _itemDetail['value']['dataSelect']['tabModuleId'] = _currentTabModuleId;
          
          // Update response
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data reloaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Clear cache to force rebuild tree
        _cachedTreeWidget = null;
        
        // Notify parent about data change
        if (widget.onDataChanged != null) {
          widget.onDataChanged!(_response);
        }
      }
    });
  }
}
