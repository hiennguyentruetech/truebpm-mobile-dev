import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body cho MODULE DTLS (Details)
/// Xử lý dữ liệu từ Response_MODULE.DTLS.json
class ModuleDtlsTabBody extends CoreTabBody {
  const ModuleDtlsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleDtlsTabBody> createState() => _ModuleDtlsTabBodyState();
}

class _ModuleDtlsTabBodyState extends CoreTabBodyState<ModuleDtlsTabBody> {
  
  // Response data
  Map<String, dynamic> _response = {};
  bool _success = false;
  String _messageType = '';
  String _message = '';
  
  // ItemDetail data
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  Map<String, dynamic> _toolbar = {};
  Map<String, dynamic> _tree = {};
  Map<String, dynamic> _grid = {};
  
  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ModuleDtlsTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update data when initialData changes (e.g., after save operation)
    if (oldWidget.initialData != widget.initialData) {
//       print('🔄 [MODULE DTLS TAB] InitialData changed, updating tab body data');
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    // Extract data from response dynamically
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    
    // Safely extract top-level response fields
    _success = _response['success'] ?? false;
    _messageType = _response['messageType']?.toString() ?? '';
    _message = _response['message']?.toString() ?? '';
    
    // Extract itemDetail dynamically
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    
    // Extract nested data from itemDetail dynamically
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    _toolbar = Map<String, dynamic>.from(_itemDetail['toolbar'] ?? {});
    _tree = Map<String, dynamic>.from(_itemDetail['tree'] ?? {});
    _grid = Map<String, dynamic>.from(_itemDetail['grid'] ?? {});
    
//     print('🔄 [MODULE DTLS TAB] Updated data - moduleData keys: ${_moduleData.keys}');
    
    // Trigger rebuild if widget is already built
    if (mounted) {
      setState(() {});
    }
  }
  
  // Method to update module data
  void updateModuleData(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
      
      // Sync changes back to itemDetail.value to ensure action handlers get latest data
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      
      // Sync changes back to the main response structure
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      
      // Update the CoreDetailProvider's rawResponse if available
      if (widget.onDataChanged != null) {
        widget.onDataChanged!(_response);
      }
    });
  }
  
  // Helper methods for toolbar
  bool isToolbarActionDisabled(String action) {
    return _toolbar['disabled']?[action] == true;
  }
  
  bool isToolbarActionHidden(String action) {
    return _toolbar['hidden']?[action] == true;
  }
  
  bool isToolbarActionVisible(String action) {
    return !isToolbarActionHidden(action);
  }
  
  bool isToolbarActionEnabled(String action) {
    return !isToolbarActionDisabled(action);
  }
  
  // Getter methods for easy access
  bool get isResponseSuccess => _success;
  String get responseMessage => _message;
  String get responseMessageType => _messageType;
  
  // Check if we have specific data types
  bool get hasTreeData => _tree.isNotEmpty;
  bool get hasGridData => _grid.isNotEmpty;
  
  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing code...
          // Basic Information Section
          _buildBasicInfoSection(),
          // Configuration Section
          _buildConfigurationSection(),
          // System Information Section
          _buildSystemInfoSection(),
          // Additional sections for tree/grid data if available
          if (hasTreeData) ...[
            _buildTreeSection(),
          ],
          if (hasGridData) ...[
            _buildGridSection(),
          ],
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  // ...existing code...

  Widget _buildTreeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tree Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text('Tree data available: ${_tree.keys.length} items'),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grid Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text('Grid data available: ${_grid.keys.length} items'),
          ],
        ),
      ),
    );
  }

  // ...existing code...

  Widget _buildBasicInfoSection() {
    return CardSection(
      title: 'Basic Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.blue.shade600,
      children: [
        ..._buildDynamicFields([
          {'key': 'code', 'label': 'Code', 'hintText': '<Auto Generated>'},
          {'key': 'name', 'required': true, 'label': 'Name'},
          {'key': 'moduleCode', 'required': true, 'label': 'Module Code'},
          {'key': 'description', 'label': 'Description', 'type': 'textarea', 'maxLines': 4, 'hintText': 'Enter module description'},
        ]),
      ],
    );
  }

    Widget _buildConfigurationSection() {
    return CardSection(
      title: 'Configuration',
      headerIcon: Icons.settings,
      headerColor: Colors.orange.shade600,
      children: [
        ..._buildDynamicFields([
          {'key': 'processName', 'hintText': 'Enter process name'},
          {'key': 'tableName', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Table Name', 'hintText': 'Select table schema for module', 'data': 'DROPDOWN.MODULE.ALLSCHEMA', 'display': 'name'},
          {'key': 'headers', 'required': false, 'label': 'Headers', 'type': 'textarea', 'maxLines': 2, 'hintText': 'List Header Label To Show On List View'},
          {'key': 'content', 'required': false, 'label': 'Content', 'type': 'textarea', 'maxLines': 2, 'hintText': 'List Content Key Value To Show On List View'},
          // Demo data for other type of dropdown and select
          // {'key': 'timeFormat', 'widget': 'select', 'selectType': 'select', 'label': 'Time Format', 'hintText': 'Search time format...', 'required': true, 'data': ['12 Hour (AM/PM)', '24 Hour Format', 'UTC Time']},
          // {
          //   'key': 'moduleTable', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Module Table', 'hintText': 'Choose module category...', 'data': 'DROPDOWN.MODULE.ALLSCHEMA', 'display': 'name',
          //   'moreDisplay': [
          //     {'key': 'code', 'label': 'Code'},
          //     {'key': 'description', 'label': 'Description'},
          //     {'key': 'status', 'label': 'Status'}
          //   ]
          // },
          // {
          //   'key': 'multiModule', 'widget': 'select', 'selectType': 'multiple', 'label': 'Multiple Modules', 'hintText': 'Select multiple modules...', 'data': 'DROPDOWN.MODULE.ALLSCHEMA', 'display': 'name',
          //   'moreDisplay': [
          //     {'key': 'code', 'label': 'Module Code'},
          //     {'key': 'description', 'label': 'Description'},
          //     {'key': 'moduleCode', 'label': 'Parent Module'},
          //     {'key': 'status', 'label': 'Status'}
          //   ]
          // },
        ]),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_rounded,
      headerColor: Colors.green.shade600,
      children: [
        ..._buildDynamicFields([
          {'key': 'createdBy', 'label': 'Created By', 'hintText': 'Created by user', 'type': 'text'},
          {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Record creation date'},

          // // Test Checkbox Fields - Required Field
          // {'key': 'agreementTest', 'widget': 'checkbox', 'label': 'I Agree to Terms', 'checkboxStyle': 'switch', 'required': true},

          // // Test Checkbox Fields - Material Style
          // {'key': 'isActiveTest', 'widget': 'checkbox', 'label': 'Is Active (Material)', 'hintText': 'Enable to activate this module', 'checkboxStyle': 'material', 'initialValue': false},
          
          // // Test Checkbox Fields - Custom Style
          // {'key': 'isPublicTest', 'widget': 'checkbox', 'label': 'Is Public (Custom)', 'hintText': 'Make this module publicly accessible', 'checkboxStyle': 'custom', 'position': 'trailing', 'customCheckedIcon': Icons.visibility, 'customUncheckedIcon': Icons.visibility_off},
          
          // // Test Checkbox Fields - Switch Style
          // {'key': 'isEnabledTest', 'widget': 'checkbox', 'label': 'Is Enabled (Switch)', 'hintText': 'Toggle to enable/disable module functionality', 'checkboxStyle': 'switch', 'initialValue': true},
          
          // // Test Checkbox Fields - Different Colors
          // {'key': 'notificationsTest', 'widget': 'checkbox', 'label': 'Enable Notifications', 'checkboxStyle': 'material', 'checkboxColor': Colors.green},
          
          // Commented out other datetime fields for testing
          // {'key': 'createdDateTest', 'widget': 'datetime', 'label': 'Created Date Test', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select creation date and time...'},
          // {'key': 'lastLoginDate', 'widget': 'datetime', 'label': 'Last Login Date', 'datetimeType': 'date', 'displayFormat': 'ddMMyyyy', 'minDate': DateTime(2025, 8, 15), 'hintText': 'Select last login date...'},
          // {'key': 'workingTime', 'widget': 'datetime', 'label': 'Working Time', 'datetimeType': 'time', 'minTime': {'hour': 7, 'minute': 30}, 'maxTime': {'hour': 11, 'minute': 30}, 'hintText': 'Select working time...'},
          // {'key': 'projectDuration', 'widget': 'datetime', 'label': 'Project Duration', 'datetimeType': 'daterange', 'startDateKey': 'projectStartDate', 'endDateKey': 'projectEndDate', 'displayFormat': 'ddMMyyyy', 'minDate': DateTime(2025, 8, 15), 'maxDate': DateTime(2025, 10, 15), 'hintText': 'Select project duration...'},
        ]),
      ],
    );
  }
  
  // Helper method to build fields dynamically using CoreDynamicFields
  List<Widget> _buildDynamicFields(List<Map<String, dynamic>> fieldConfigs) {
    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: _itemDetail,
      moduleData: _moduleData,
      onChanged: updateModuleData,
      isCommonField: _isCommonField,
    );
  }
  
  // Helper method for field configuration
  // Override this in each body to customize which fields should be included
  bool _isCommonField(String fieldName) {
    const commonFields = [
      // Basic module fields
      'code', 'name', 'moduleCode', 'description', 'processName', 
      'tableName', 'headers', 'content',
      // DateTime fields
      'createdBy', 'createdDate',
      // 'agreementTest', 'isActiveTest', 'isPublicTest', 'isEnabledTest', 'notificationsTest',
    ];
    return commonFields.contains(fieldName);
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
    // Return all module data for saving
    return Map<String, dynamic>.from(_moduleData);
  }

  @override
  Future<Map<String, dynamic>> loadTabSpecificData() async {
    return {};
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // TODO: Implement actual API call to save module details
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: Implement actual API call to submit module details
  }
}
