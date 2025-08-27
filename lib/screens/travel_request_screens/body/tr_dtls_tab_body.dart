import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for TRAREQ DTLS (Details)
class TRDetailsTabBody extends CoreTabBody {
  const TRDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRDetailsTabBody> createState() => _TRDetailsTabBodyState();
}

class _TRDetailsTabBodyState extends CoreTabBodyState<TRDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRDetailsTabBody oldWidget) {
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
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
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
          _buildScheduleSection(),
          _buildReasonsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'status', 'widget': 'status', 'showIcon': true},
            {'key': 'code', 'label': 'Travel Request Code'},
            // Object keys should be select dropdowns (placeholder API endpoints)
            {'key': 'country', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Country', 'hintText': 'Select country', 'data': 'DROPDOWN.TRAREQ/COUNTRY', 'display': 'name', 'clearOnChange': ['locations']},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return CardSection(
      title: 'Travel Schedule',
      headerIcon: Icons.calendar_today,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'startDate', 'widget': 'datetime', 'label': 'From - To', 'datetimeType': 'daterange', 'startDateKey': 'startDate', 'endDateKey': 'endDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select duration'},
            {'key': 'startToEnd', 'label': 'Start To End', 'hintText': 'e.g., 14/08/2025-14/09/2025', 'disabled': true},
            {'key': 'totalDays', 'type': 'number', 'label': 'Total Days', 'suffix': ' days', 'disabled': true},
            {'key': 'location', 'label': 'Location'},
            // locations collection (objects)
            {
              'key': 'locations',
              'widget': 'collection',
              'label': 'Locations',
              'itemLabel': 'Location',
              'addButtonText': 'Add Location',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'children': [
                {'key': 'name', 'label': 'Name'},
                {'key': 'description', 'label': 'Description'},
                {'key': 'perDiemAmount', 'label': 'Per Diem Amount', 'type': 'currency', 'suffix': ' VND'},
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

  Widget _buildReasonsSection() {
    return CardSection(
      title: 'Reasons',
      headerIcon: Icons.list_alt,
      headerColor: Colors.orange,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'reasons',
              'widget': 'collection',
              'label': 'Travel Reasons',
              'itemLabel': 'Reason',
              'addButtonText': 'Add New Reason',
              'hintText': 'Click Add to add reasons',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'children': [
                {'key': 'details', 'label': 'Details', 'type': 'textarea', 'maxLines': 3},
                {'key': 'percentage', 'label': 'Percentage', 'type': 'number', 'suffix': '%'},
                // Object keys as dropdowns with sample endpoints
                {'key': 'reasonType', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Reason Type', 'data': 'DROPDOWN.TRAREQ/REASON_TYPES', 'display': 'name', 'clearOnChange': ['project', 'opportunity', 'solution']},
                {'key': 'project', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project', 'data': 'DROPDOWN.TRAREQ/PROJECTS', 'display': 'name'},
                {'key': 'opportunity', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Opportunity', 'data': 'DROPDOWN.TRAREQ/OPPORTUNITIES', 'display': 'name'},
                {'key': 'solution', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Solution', 'data': 'DROPDOWN.TRAREQ/SOLUTIONS', 'display': 'name'},
                {'key': 'salesperson', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Salesperson', 'data': 'DROPDOWN.TRAREQ/SALESPERSONS', 'display': 'fullName'},
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
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'createdBy', 'label': 'Created By', 'type': 'text'},
            {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy'},
            {'key': 'updatedDate', 'widget': 'datetime', 'label': 'Updated Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy'},
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

