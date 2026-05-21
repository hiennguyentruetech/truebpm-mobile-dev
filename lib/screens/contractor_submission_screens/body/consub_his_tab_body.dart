import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for CONSUB HIS (Workflow History)
class ConsubHistoryTabBody extends CoreTabBody {
  const ConsubHistoryTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ConsubHistoryTabBody> createState() =>
      _ConsubHistoryTabBodyState();
}

class _ConsubHistoryTabBodyState
    extends CoreTabBodyState<ConsubHistoryTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ConsubHistoryTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    _normalizeHistory();
    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    if (mounted) setState(() {});
  }

  void _normalizeHistory() {
    final raw = _moduleData['approveWorkFlowHistory'];
    if (raw is! List) return;

    final normalized = raw.map((entry) {
      final Map<String, dynamic> item = entry is Map
          ? Map<String, dynamic>.from(entry)
          : <String, dynamic>{};
      final statusName = item['statusName']?.toString().trim();
      if (statusName != null && statusName.isNotEmpty) {
        item['statusNameClean'] = statusName;
      }
      return item;
    }).toList();

    _moduleData['approveWorkFlowHistory'] = normalized;
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
          ...CoreDynamicFields.buildFields(
            fieldConfigs: [
              {
                'key': 'approveWorkFlowHistory',
                'widget': 'collection',
                'label': 'Workflow History',
                'itemLabel': 'History',
                'hintText': 'No workflow history available',
                'allowAdd': false,
                'allowRemove': false,
                'editMode': 'modal',
                'titleTemplate': '{rowNum} - {approvalWorkFlowName}',
                'summary': {
                  'layout': 'row',
                  'fields': [
                    {
                      'key': 'rowNum',
                      'label': '#',
                      'type': 'number',
                      'layout': 'row',
                    },
                    {
                      'key': 'approvalWorkFlowName',
                      'label': 'Approval WorkFlow Name',
                      'layout': 'row',
                    },
                    {'key': 'createdBy', 'label': 'Assigner', 'layout': 'row'},
                    {
                      'key': 'createdDate',
                      'label': 'Date',
                      'widget': 'datetime',
                      'datetimeType': 'datetime',
                      'displayFormat': 'ddMMyyyy',
                      'layout': 'row',
                    },
                    {
                      'key': 'statusNameClean',
                      'label': 'Status',
                      'layout': 'row',
                    },
                  ],
                },
                'children': [
                  {
                    'key': 'rowNum',
                    'label': '#',
                    'type': 'number',
                    'disabled': true,
                  },
                  {
                    'key': 'approvalWorkFlowName',
                    'label': 'Approval WorkFlow Name',
                    'disabled': true,
                  },
                  {'key': 'createdBy', 'label': 'Assigner', 'disabled': true},
                  {
                    'key': 'createdDate',
                    'label': 'Date',
                    'widget': 'datetime',
                    'datetimeType': 'datetime',
                    'displayFormat': 'ddMMyyyy',
                    'disabled': true,
                  },
                  {
                    'key': 'statusNameClean',
                    'label': 'Status',
                    'disabled': true,
                  },
                ],
              },
            ],
            itemDetail: _itemDetail,
            moduleData: _moduleData,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}
