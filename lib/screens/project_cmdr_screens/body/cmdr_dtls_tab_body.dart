import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for CMDRMD DTLS (Details)
class CmdrDetailsTabBody extends CoreTabBody {
  const CmdrDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<CmdrDetailsTabBody> createState() => _CmdrDetailsTabBodyState();
}

class _CmdrDetailsTabBodyState extends CoreTabBodyState<CmdrDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(CmdrDetailsTabBody oldWidget) {
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
          _buildProjectInfoSection(),
          _buildBasicInfoSection(),
          _buildInChargeSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            // {'key': 'code', 'label': 'Code'},
            { 'key': 'itemNo', 'label': 'No', 'disabled': true},
            { 'key': 'name', 'label': 'Name', 'disabled': true},
            { 'key': 'completeness', 'label': 'Completeness', 'type': 'number', 'suffix': '%', 'minValue': 0, 'maxValue': 100},
            { 'key': 'finishDate', 'widget': 'datetime', 'label': 'Finish Date', 'datetimeType': 'date', 'displayFormat': 'ddMMyyyy'},
            { 'key': 'workStatus', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Work Status', 'data': 'DROPDOWN.PRJMGT/WORKSTATUS', 'display': 'name'},
            { 'key': 'completeness', 'widget': 'input', 'label': 'Completeness', 'type': 'number', 'suffix': '%', 'decimalPlaces': 2, 'minValue': 0, 'maxValue': 100},
            { 'key': 'isPaymentMilestone', 'widget': 'checkbox', 'label': 'Payment Milestone', 'checkboxStyle': 'switch'},
            { 'key': 'paymentStatus', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Payment Status', 'data': 'DROPDOWN.PRJMGT/PAYMENTSTATUS', 'display': 'name'},
            { 'key': 'paymentGroup', 'widget': 'input', 'label': 'Payment Group', 'type': 'number'},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildProjectInfoSection() {
    return CardSection(
      title: 'Project Information',
      headerIcon: Icons.business_center_outlined,
      headerColor: Colors.purple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'projectName', 'label': 'Project Name'},
            {'key': 'projectCode', 'label': 'Project Code'},
            {'key': 'projectCompletedPercent', 'label': 'Percentage of Completeness', 'type': 'number', 'suffix': '%', 'decimalPlaces': 2},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildInChargeSection() {
    final inChargePerson = _moduleData['inChargePerson'] as List<dynamic>?;
    if (inChargePerson == null || inChargePerson.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return CardSection(
      title: 'In Charge Person',
      headerIcon: Icons.people_outline,
      headerColor: Colors.teal,
      children: [
        ...inChargePerson.map((person) {
          final personData = person['person'] as Map<String, dynamic>?;
          final roleData = person['role'] as Map<String, dynamic>?;
          final isOwner = person['isOwner'] as bool? ?? false;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isOwner ? Colors.amber.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOwner ? Colors.amber.shade300 : Colors.grey.shade300,
                width: isOwner ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOwner ? Colors.amber : Colors.grey.shade400,
                  radius: 20,
                  child: Icon(
                    isOwner ? Icons.star : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              personData?['fullName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (roleData?['name'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Role: ${roleData!['name']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
