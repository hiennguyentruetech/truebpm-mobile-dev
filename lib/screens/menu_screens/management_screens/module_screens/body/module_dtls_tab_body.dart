import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';

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
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  
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
      _updateDataFromInitialData();
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
      _moduleData[key] = value;
      
      // Sync changes back to itemDetail.value to ensure action handlers get latest data
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      
      // Sync changes back to the main response structure
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }
  
  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Section
          _buildBasicInfoSection(),
          // Configuration Section
          _buildConfigurationSection(),
          // System Information Section
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInfoSection() {
    return CardSection(
      title: 'Basic Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.blue.shade600,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'code', 'label': 'Code', 'hintText': '<Auto Generated>', 'disabled': true},
            {'key': 'name', 'required': true, 'label': 'Name'},
            {'key': 'moduleCode', 'required': true, 'label': 'Module Code'},
            {'key': 'description', 'label': 'Description', 'type': 'textarea', 'maxLines': 4, 'hintText': 'Enter module description'},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return CardSection(
      title: 'Configuration',
      headerIcon: Icons.settings,
      headerColor: Colors.orange.shade600,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'processName', 'hintText': 'Enter process name'},
            {'key': 'tableName', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Table Name', 'hintText': 'Select table schema for module', 'data': 'DROPDOWN.MODULE.ALLSCHEMA', 'display': 'name'},
            {'key': 'headers', 'required': false, 'label': 'Headers', 'type': 'textarea', 'maxLines': 2, 'hintText': 'List Header Label To Show On List View'},
            {'key': 'content', 'required': false, 'label': 'Content', 'type': 'textarea', 'maxLines': 2, 'hintText': 'List Content Key Value To Show On List View'},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_rounded,
      headerColor: Colors.green.shade600,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'createdBy', 'label': 'Created By', 'hintText': 'Created by user', 'type': 'text', 'disabled': true},
            {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Record creation date', 'disabled': true},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
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
    // No-op, data provided by provider initialData
    return {};
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement actual API call to save module details
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement actual API call to submit module details
  }
}
