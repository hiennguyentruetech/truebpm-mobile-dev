import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body cho MODULE QUERY (Query Configuration)
/// Xử lý cấu hình query và database operations
class ModuleQueryTabBody extends CoreTabBody {
  const ModuleQueryTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleQueryTabBody> createState() => _ModuleQueryTabBodyState();
}

class _ModuleQueryTabBodyState extends CoreTabBodyState<ModuleQueryTabBody> {
  
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
  void didUpdateWidget(ModuleQueryTabBody oldWidget) {
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
    // Tạo cấu hình field cho CoreDynamicFields
    final List<Map<String, dynamic>> fieldConfigs = [
      {
        'key': 'queryFieldString',
        'widget': 'input',
        'type': 'textarea',
        'label': 'Query Field String',
        'required': true,
        'maxLines': 25, // Tăng lên 25 dòng
        'hintText': 'Enter your query field string here...',
      }
    ];



    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sử dụng CoreDynamicFields để build input field
          ...CoreDynamicFields.buildFields(
            fieldConfigs: fieldConfigs,
            itemDetail: _itemDetail,
            moduleData: _moduleData,
            onChanged: _onChanged,
          ),
        ],
      ),
    ).dismissKeyboardOnTap();
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
