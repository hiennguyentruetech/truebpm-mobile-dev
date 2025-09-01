import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for DATASPY PERMISSION
/// Handles grantPermission collection display similar to module_tbpms_tab_body.dart
class DataSpyPermissionTabBody extends CoreTabBody {
  const DataSpyPermissionTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<DataSpyPermissionTabBody> createState() => _DataSpyPermissionTabBodyState();
}

class _DataSpyPermissionTabBodyState extends CoreTabBodyState<DataSpyPermissionTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(DataSpyPermissionTabBody oldWidget) {
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
      if (key == 'grantPermision' && value is List) {
        // Special handling for grantPermision field with userPermission.name structure
        // Check if values are already formatted (have userPermission wrapper)
        final formattedValue = value.map((item) {
          if (item is Map<String, dynamic>) {
            // Check if already formatted (has userPermission wrapper)
            if (item.containsKey('userPermission')) {
              return item; // Already formatted, return as-is
            }

            // Format raw option to userPermission wrapper
            return {
              'id': item['id'] ?? '',
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
              'id': item,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildGrantPermissionSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGrantPermissionSection() {
    return Column(
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'grantPermision',
              'widget': 'select',
              'selectType': 'multiple',
              'label': 'Grant Permissions',
              'data': 'DROPDOWN.USRPER',
              'display': 'userPermission.name', // For input field display
              'dropdownDisplay': 'name', // For dropdown/popup display
              'splitKey': true, // Enable split key functionality
              'required': false,
              'hintText': 'Select user permissions...',
              'allowAdd': true,
              'allowRemove': true,
            },
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

  // Prepare data for save/submit
  Map<String, dynamic> prepareDataForSave() {
    return Map<String, dynamic>.from(_moduleData);
  }

  @override
  Future<void> loadTabSpecificData() async {
    // No-op, data provided by provider initialData
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
