import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for DASCFG DTLS (Details)
class DashboardConfigDetailsTabBody extends CoreTabBody {
  const DashboardConfigDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<DashboardConfigDetailsTabBody> createState() => _DashboardConfigDetailsTabBodyState();
}

class _DashboardConfigDetailsTabBodyState extends CoreTabBodyState<DashboardConfigDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(DashboardConfigDetailsTabBody oldWidget) {
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
      _moduleData[key] = value;
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });

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
          _buildGeneralSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGeneralSection() {
    return CardSection(
      title: 'Dashboard Config Details',
      headerIcon: Icons.dashboard_customize_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'code', 'label': 'Code', 'disabled': true},
            {'key': 'name', 'label': 'Name', 'required': true},
            {
              'key': 'description',
              'label': 'Description',
              'type': 'textarea',
              'maxLines': 3,
              'hintText': 'Enter dashboard config description...'
            },
            {
              'key': 'timeCache',
              'label': 'Time Cache',
              'type': 'number',
              'suffix': ' s',
            },
            {
              'key': 'isDefault',
              'widget': 'checkbox',
              'label': 'Default Config',
              'checkboxStyle': 'switch',
            },
            {
              'key': 'isActive',
              'widget': 'checkbox',
              'label': 'Active',
              'checkboxStyle': 'switch',
            },
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
      headerIcon: Icons.settings_outlined,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'createdBy', 'label': 'Created By', 'disabled': true},
            {
              'key': 'createdDate',
              'widget': 'datetime',
              'label': 'Created Date',
              'datetimeType': 'datetime',
              'displayFormat': 'ddMMyyyy',
              'disabled': true,
            },
            {'key': 'updatedBy', 'label': 'Updated By', 'disabled': true},
            {
              'key': 'updatedDate',
              'widget': 'datetime',
              'label': 'Updated Date',
              'datetimeType': 'datetime',
              'displayFormat': 'ddMMyyyy',
              'disabled': true,
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
}
