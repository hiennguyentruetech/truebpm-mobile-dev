import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';

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
  
  // Local data storage to replace removed formData
  Map<String, dynamic> _moduleData = {};
  
  @override
  void initState() {
    super.initState();
    // Khởi tạo moduleData từ initialData hoặc từ itemDetail.value nếu có
    _moduleData = Map<String, dynamic>.from(widget.initialData ?? {});
    
    // Nếu có itemDetail.value.queryFieldString, lấy giá trị đó
    if (widget.initialData != null && 
        widget.initialData!['itemDetail'] is Map<String, dynamic> &&
        widget.initialData!['itemDetail']['value'] is Map<String, dynamic>) {
      final itemDetailValue = widget.initialData!['itemDetail']['value'] as Map<String, dynamic>;
      if (itemDetailValue.containsKey('queryFieldString')) {
        _moduleData['queryFieldString'] = itemDetailValue['queryFieldString'];
      }
    }
  }
  
  // Method to update module data
  void updateModuleData(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
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

    // Tạo itemDetail với value chứa moduleData
    final Map<String, dynamic> itemDetail = {
      'value': _moduleData,
      'attribute': {
        'required': {
          'queryFieldString': true,
        }
      }
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sử dụng CoreDynamicFields để build input field
          ...CoreDynamicFields.buildFields(
            fieldConfigs: fieldConfigs,
            itemDetail: itemDetail,
            moduleData: _moduleData,
            onChanged: updateModuleData,
          ),
        ],
      ),
    );
  }

  @override
  bool validateData() {
    if (_moduleData['queryFieldString']?.toString().trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Query Field String is required'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> prepareDataForSave() {
    return {
      'queryFieldString': _moduleData['queryFieldString']?.toString().trim(),
    };
  }

  Future<Map<String, dynamic>> loadTabSpecificData() async {
    // Return empty map to use initialData from provider instead of mock data
    return {};
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // TODO: Implement actual API call
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: Implement actual API call
  }
}
