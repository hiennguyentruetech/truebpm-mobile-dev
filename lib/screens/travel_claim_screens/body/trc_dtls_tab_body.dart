import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for TRACLA DTLS (Details)
class TRCDetailsTabBody extends CoreTabBody {
  const TRCDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRCDetailsTabBody> createState() => _TRCDetailsTabBodyState();
}

class _TRCDetailsTabBodyState extends CoreTabBodyState<TRCDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRCDetailsTabBody oldWidget) {
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
      _setByPath(_moduleData, key, value);
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  void _setByPath(Map<String, dynamic> map, String path, dynamic value) {
    final parts = path.split('.');
    Map<String, dynamic> curr = map;
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final bool isLast = i == parts.length - 1;
      if (isLast) {
        curr[part] = value;
      } else {
        if (curr[part] is! Map<String, dynamic>) {
          curr[part] = <String, dynamic>{};
        }
        curr = curr[part] as Map<String, dynamic>;
      }
    }
  }

  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralInfoSection(),
          _buildTravelRequestsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.info_outline,
      headerColor: const Color.fromARGB(255, 26, 26, 163),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true, 'visibleWhen': { 'key': 'id', 'operator': 'ne', 'value': null } },
            { 'key': 'code', 'label': 'Claim Code', 'disabled': true},
            { 'key': 'totalRemained', 'label': 'Total Remained', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'disabled': true},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }



  Widget _buildTravelRequestsSection() {
    return CardSection(
      title: 'Travel Request Selection',
      headerIcon: Icons.flight_takeoff,
      headerColor: const Color.fromARGB(255, 17, 130, 73),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'travelRequests',
              'widget': 'collection',
              'label': 'Travel Requests',
              'itemLabel': 'Travel Request',
              'addButtonText': 'Add Travel Request',
              'hintText': 'Select travel requests to include in this claim',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'children': [
                {'key': 'travelRequest', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Travel Request', 'data': 'DROPDOWN.TRACLA.TR?username={{username}}', 'display': 'code'},
              ],
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
      headerIcon: Icons.info_outline,
      headerColor: const Color.fromARGB(255, 71, 102, 21),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'createdBy', 'label': 'Created By', 'type': 'text', 'disabled': true},
            {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'disabled': true},
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

