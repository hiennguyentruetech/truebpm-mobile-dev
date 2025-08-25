import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for CARBKG DTLS (Details)
class CarBookingDetailsTabBody extends CoreTabBody {
  const CarBookingDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<CarBookingDetailsTabBody> createState() => _CarBookingDetailsTabBodyState();
}

class _CarBookingDetailsTabBodyState extends CoreTabBodyState<CarBookingDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(CarBookingDetailsTabBody oldWidget) {
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
          _buildBasicInformationSection(),
          _buildAssetInformationSection(),
          _buildSystemInformationSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInformationSection() {
    return CardSection(
      title: 'Basic Information',
      headerIcon: Icons.directions_car_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true },
            { 'key': 'code', 'label': 'Code', 'widget': 'input', 'type': 'text', 'disabled': true },
            { 'key': 'purpose', 'label': 'Purpose', 'widget': 'input', 'type': 'text', 'required': true },
            {'key': 'fromDate', 'widget': 'datetime', 'label': 'From Date - To Date', 'datetimeType': 'daterange', 'startDateKey': 'fromDate', 'endDateKey': 'toDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select duration...'},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildAssetInformationSection() {
    return CardSection(
      title: 'Asset Information',
      headerIcon: Icons.car_rental,
      headerColor: const Color.fromARGB(255, 87, 6, 101),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'assetId',
              'label': 'Asset',
              'widget': 'select',
              'selectType': 'dropdown',
              'data': 'DROPDOWN.CARBKG/ASSET',
              'display': 'name',
              'required': true,
            },
            // Display nested asset fields as view-only inputs
            { 'key': 'assetId.name', 'label': 'Asset Name', 'widget': 'input', 'type': 'text', 'onlyView': true },
            { 'key': 'beforeKM', 'label': 'Before KM', 'widget': 'input', 'type': 'number', 'decimalPlaces': 0 },
            { 'key': 'afterKM', 'label': 'After KM', 'widget': 'input', 'type': 'number', 'decimalPlaces': 0 },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildSystemInformationSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'createdBy', 'label': 'Created By', 'widget': 'input', 'type': 'text', 'disabled': true },
            { 'key': 'createdDate', 'label': 'Created Date', 'widget': 'datetime', 'datetimeType': 'datetime', 'disabled': true },
            { 'key': 'updatedDate', 'label': 'Last Updated Date', 'widget': 'datetime', 'datetimeType': 'datetime', 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}
