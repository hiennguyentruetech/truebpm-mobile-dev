import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:truebpm/services/core_service.dart';
// import 'package:truebpm/utils/core_api_logger.dart'; // Removed unused
import 'package:truebpm/utils/logger.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/loading_overlay.dart';

/// Tab body for TRACLA INFO - General Expense (use same tab code 'INFO' but separate UI tab)
class TRCInfoGeneralTabBody extends CoreTabBody {
  const TRCInfoGeneralTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRCInfoGeneralTabBody> createState() => _TRCInfoGeneralTabBodyState();
}

class _TRCInfoGeneralTabBodyState extends CoreTabBodyState<TRCInfoGeneralTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  bool _isGeneratingPerdiem = false;
  bool _isGeneratingAccom = false;

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRCInfoGeneralTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    // Preserve parent record id separately so collection item 'id' doesn't override in templates
    if (_moduleData['id'] != null) {
      _moduleData['_parentId'] = _moduleData['id'];
    }
    if (mounted) setState(() {});
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
      // Auto-recalculate for generalExpense collection items
      if (key == 'generalExpense' && value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final totalRaw = item['total'];
            double total = 0;
            if (totalRaw is int) total = totalRaw.toDouble();
            else if (totalRaw is double) total = totalRaw;
            final deductibleRaw = item['deductible'];
            double deductiblePercent = 0;
            if (deductibleRaw is int) deductiblePercent = deductibleRaw.toDouble();
            else if (deductibleRaw is double) deductiblePercent = deductibleRaw;
            double taxPercent = 0;
            if (item['expenseType'] is Map && (item['expenseType']['tax'] is num)) {
              taxPercent = (item['expenseType']['tax'] as num).toDouble();
            } else if (item['tax'] is num) {
              taxPercent = (item['tax'] as num).toDouble();
            }
            final totalAfterDeductible = total - (total * (deductiblePercent / 100));
            final totalAfterTax = totalAfterDeductible - (totalAfterDeductible * (taxPercent / 100));
            item['totalAfterTax'] = totalAfterTax.round();
          }
        }
      }
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
    if (_moduleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGenerateButtons(context),
            const SizedBox(height: 8),
            ..._buildDynamicFieldConfigs(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  List<Widget> _buildDynamicFieldConfigs() {
  // Build dropdown endpoints with explicit parent id to avoid null templates
  final parentId = _moduleData['_parentId'] ?? _moduleData['id'] ?? _moduleData['travelClaimId'];
  final encodedParentId = parentId == null ? '' : Uri.encodeComponent(parentId.toString());
    final fieldConfigs = [
      {
        'key': 'generalExpense',
        'widget': 'collection',
        'label': 'General Expense',
        'itemLabel': 'Expense Item',
        'addButtonText': 'Add Expense',
        'hintText': 'No expense added yet. Click Add to create one.',
        'allowAdd': true,
        'allowRemove': true,
        'editMode': 'modal',
        'useFloatingAddButton': true,
        'useAddFirstList': true,
        'totalSummary': {
          'key': 'totalAfterTax',
          'label': 'Total After Tax',
          'format': '#,##0',
          'suffix': ' VND',
          'bgColor': '#E8F5E8',
          'borderColor': '#A5D6A7',
          'labelColor': '#2E7D32',
          'valueColor': '#1B5E20',
        },
        'summary': {
          'fields': [
            { 'key': 'travelRequest', 'display': 'code', 'label': 'Travel Request', 'bgColor': '#F3E5F5', 'borderColor': '#CE93D8', 'labelColor': '#7B1FA2', 'valueColor': '#4A148C' },
            { 'key': 'date', 'label': 'Date', 'type': 'date', 'format': 'dd/MM/yyyy', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
            { 'key': 'expenseType', 'display': 'name', 'label': 'Type', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
            { 'key': 'locationObject', 'display': 'name', 'label': 'Location', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
            { 'key': 'purpose', 'label': 'Purpose', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
            { 'key': 'deductible', 'label': 'Deductible', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' %', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'total', 'label': 'Total', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'totalAfterTax', 'label': 'Total After Tax', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
          ]
        },
        'children': [
          {
            'key': 'travelRequest',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Travel Request',
            'data': 'DROPDOWN.TRACLA/TR.BYCLAIM?id=$encodedParentId',
            'display': 'code',
            'required': true,
            'hintText': 'Select travel request...',
            'clearOnChange': ['date'],
          },
          {
            'key': 'date',
            'widget': 'datetime',
            'label': 'Date',
            'datetimeType': 'date',
            'displayFormat': 'ddMMyyyy',
            'required': true,
            // Use dynamic paths for min/max constraints resolved at runtime
            'minDatePath': 'travelRequest.startDate',
            'maxDatePath': 'travelRequest.endDate',
            // Disable until travelRequest chosen
            'requireKeys': ['travelRequest.id'],
          },
          {
            'key': 'expenseType',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Expense Type',
            'data': 'DROPDOWN.TRACLA/EXP.TYPE',
            'display': 'name',
            'required': true,
          },
          {
            'key': 'locationObject',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Location',
            'data': 'DROPDOWN.TRACLA/LOC.BYCLAIM?id=$encodedParentId',
            'display': 'name',
            'required': true,
          },
          {'key': 'purpose', 'label': 'Purpose', 'type': 'textarea', 'maxLines': 3, 'required': true},
          {
            'key': 'deductible',
            'label': 'Deductible (%)',
            'type': 'number',
            'suffix': ' %',
            'decimalPlaces': 0,
            'required': false,
          },
          {
            'key': 'total',
            'label': 'Total',
            'type': 'number',
            'suffix': ' VND',
            'decimalPlaces': 0,
            'required': true,
          },
          {
            'key': 'totalAfterTax',
            'label': 'Total After Tax',
            'type': 'number',
            'suffix': ' VND',
            'decimalPlaces': 0,
            'required': false,
            'disabled': true,
          },
        ],
      },
    ];

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: _itemDetail,
      moduleData: _moduleData,
      onChanged: _onChanged,
    );
  }

  Widget? _buildFloatingActionButton() {
    // Check if we should show floating button based on config
    final generalExpense = _moduleData['generalExpense'] as List?;
    final maxItems = null; // You can configure this if needed

    if (maxItems != null && (generalExpense?.length ?? 0) >= maxItems) {
      return null; // Don't show if max items reached
    }

    return FloatingAddButton(
      onPressed: () {
        setState(() {
          if (_moduleData['generalExpense'] == null) {
            _moduleData['generalExpense'] = [];
          }
          final list = _moduleData['generalExpense'] as List;
          list.insert(0, <String, dynamic>{});

          _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
        });

        if (widget.onDataChanged != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            widget.onDataChanged!(_response);
          });
        }
      },
    );
  }

  Widget _buildGenerateButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Auto Generate Expense',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_isGeneratingPerdiem || _isGeneratingAccom)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _FancyButton(
                    label: 'PerDiem',
                    icon: Icons.flight_takeoff,
                    gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                    loading: _isGeneratingPerdiem,
                    onTap: _isGeneratingPerdiem
                        ? null
                        : () => _generateExpense(context, code: 'TREXTY-10007', isPerdiem: true),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _FancyButton(
                    label: 'Accomodation',
                    icon: Icons.hotel,
                    gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                    loading: _isGeneratingAccom,
                    onTap: _isGeneratingAccom
                        ? null
                        : () => _generateExpense(context, code: 'TREXTY-10005', isPerdiem: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateExpense(BuildContext context, {required String code, required bool isPerdiem}) async {
    final travelClaimId = _moduleData['id'];
    if (travelClaimId == null || (travelClaimId is String && travelClaimId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Travel Claim ID not found.')));
      return;
    }

    setState(() {
      if (isPerdiem) {
        _isGeneratingPerdiem = true;
      } else {
        _isGeneratingAccom = true;
      }
    });

    try {
      final endpoint = 'TRACLA/GEN.EXPENSE?code=$code&travelClaimId=$travelClaimId';
      appLogger.logWithClass('TRCInfoGeneralTabBody', 'Generating expenses via $endpoint');
      LoadingOverlay.show(context, message: 'Generating expenses...');
      final res = await CoreService.instance.getDropdownData(endpoint);
      if (res['success'] == true) {
        final data = res['data'];
        if (data is List) {
          final List<dynamic> newItems = data.map((e) => _normalizeExpenseItem(e)).toList();
          final List<dynamic> current = List<dynamic>.from(_moduleData['generalExpense'] ?? []);
          // Prepend new items
            _moduleData['generalExpense'] = [...newItems, ...current];
          // propagate changes
          _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
          setState(() {});
          if (widget.onDataChanged != null) {
            SchedulerBinding.instance.addPostFrameCallback((_) => widget.onDataChanged!(_response));
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created ${newItems.length} expense item(s).')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response is not a valid list.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generate expense failed: ${res['message'] ?? 'Unknown error'}')));
      }
    } catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
  LoadingOverlay.hide();
      if (mounted) {
        setState(() {
          if (isPerdiem) {
            _isGeneratingPerdiem = false;
          } else {
            _isGeneratingAccom = false;
          }
        });
      }
    }
  }

  Map<String, dynamic> _normalizeExpenseItem(dynamic raw) {
    if (raw is! Map<String, dynamic>) return {};
    final map = Map<String, dynamic>.from(raw);
    // Ensure required collection fields exist
    // Flatten/derive tax if nested in expenseType
    if (!map.containsKey('tax')) {
      final expenseType = map['expenseType'];
      if (expenseType is Map && expenseType['tax'] != null) {
        map['tax'] = expenseType['tax'];
      }
    }
    // Fallback defaults
    map['deductible'] = map['deductible'] ?? 0;
    map['purpose'] = map['purpose'] ?? '';
    map['total'] = map['total'] ?? map['totalAfterTax'] ?? 0;
    map['totalAfterTax'] = map['totalAfterTax'] ?? map['total'] ?? 0;
    // Date normalization (if ISO string keep as is, dynamic fields component may parse)
    return map;
  }
}

class _FancyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final bool loading;
  final VoidCallback? onTap;

  const _FancyButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  loading ? 'Processing...' : label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

