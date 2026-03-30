import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:truebpm/services/core_service.dart';
// import 'package:truebpm/utils/core_api_logger.dart'; // Removed unused
import 'package:truebpm/utils/logger.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/loading_overlay.dart';
import 'package:truebpm/screens/travel_claim_screens/body/trc_fancy_button.dart';
import 'package:truebpm/screens/travel_claim_screens/body/trc_info_general_field_configs.dart';

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
  CoreTabBodyState<TRCInfoGeneralTabBody> createState() =>
      _TRCInfoGeneralTabBodyState();
}

class _TRCInfoGeneralTabBodyState
    extends CoreTabBodyState<TRCInfoGeneralTabBody> {
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
    bool hasAutoFillChanges = false;
    // Snapshot previous list for diffing to find the single changed item
    final prevListRaw = _moduleData['generalExpense'];
    final List<Map<String, dynamic>> prevItems = (prevListRaw is List)
        ? prevListRaw
              .map(
                (e) => e is Map<String, dynamic>
                    ? Map<String, dynamic>.from(e)
                    : <String, dynamic>{},
              )
              .toList(growable: false)
        : const [];

    setState(() {
      _moduleData[key] = value;

      // Auto-recalculate for generalExpense collection items
      if (key == 'generalExpense' && value is List) {
        // Ensure we work on independent item maps to avoid reference sharing between items
        final List<Map<String, dynamic>> items = value
            .map(
              (e) => e is Map<String, dynamic>
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{},
            )
            .toList(growable: true);
        _moduleData['generalExpense'] = items;
        print(
          'Processing generalExpense collection with ${items.length} items',
        );

        // Determine which item changed to avoid affecting others.
        int? changedIndex;
        if (prevItems.length == items.length) {
          for (int i = 0; i < items.length; i++) {
            if (!(i < prevItems.length && mapEquals(prevItems[i], items[i]))) {
              if (changedIndex == null) {
                changedIndex = i;
              } else {
                // More than one differs - ambiguous (e.g., reorder). Avoid auto-fill in this case.
                changedIndex = null;
                break;
              }
            }
          }
        } else if (items.length == prevItems.length + 1) {
          // Added one new item - assume first differing index is the new/edited one
          for (int i = 0; i < items.length; i++) {
            if (!(i < prevItems.length && mapEquals(prevItems[i], items[i]))) {
              changedIndex = i;
              break;
            }
          }
        } else {
          // Removal or multiple structural changes - skip auto-fill
          changedIndex = null;
        }

        bool mapEq(dynamic a, dynamic b) {
          if (a is Map && b is Map) return mapEquals(a, b);
          return a == b;
        }

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final prevItem = (i < prevItems.length) ? prevItems[i] : null;

          if (changedIndex != null && i == changedIndex) {
            print('Processing changed item $i: ${item.keys}');

            // Only run relevant auto-fills based on fields that changed
            final bool travelChanged = !mapEq(
              prevItem?['travelRequest'],
              item['travelRequest'],
            );
            final bool locationChanged = !mapEq(
              prevItem?['locationObject'],
              item['locationObject'],
            );
            final bool typeChanged = !mapEq(
              prevItem?['expenseType'],
              item['expenseType'],
            );

            if (travelChanged && _handleTravelRequestAutoFill(item)) {
              hasAutoFillChanges = true;
              print('Auto-filled date for item $i');
            }
            if ((locationChanged || typeChanged) &&
                _handleLocationAutoFill(item)) {
              hasAutoFillChanges = true;
              print('Auto-filled total for item $i');
            }

            // Calculate totalAfterTax for changed item
            final totalRaw = item['total'];
            double total = 0;
            if (totalRaw is int)
              total = totalRaw.toDouble();
            else if (totalRaw is double)
              total = totalRaw;
            final deductibleRaw = item['deductible'];
            double deductiblePercent = 0;
            if (deductibleRaw is int)
              deductiblePercent = deductibleRaw.toDouble();
            else if (deductibleRaw is double)
              deductiblePercent = deductibleRaw;
            double rawTax = 0;
            if (item['expenseType'] is Map &&
                (item['expenseType']['tax'] is num)) {
              rawTax = (item['expenseType']['tax'] as num).toDouble();
            } else if (item['tax'] is num) {
              rawTax = (item['tax'] as num).toDouble();
            }
            final double taxRate = rawTax <= 1 ? rawTax : rawTax / 100;
            final totalAfterDeductible =
                total - (total * (deductiblePercent / 100));
            final totalAfterTax =
                totalAfterDeductible - (totalAfterDeductible * taxRate);
            item['totalAfterTax'] = totalAfterTax.round();
          } else {
            // Do not auto-fill other items. Only ensure totalAfterTax exists if missing.
            if (item['totalAfterTax'] == null) {
              final totalRaw = item['total'];
              double total = 0;
              if (totalRaw is int)
                total = totalRaw.toDouble();
              else if (totalRaw is double)
                total = totalRaw;
              final deductibleRaw = item['deductible'];
              double deductiblePercent = 0;
              if (deductibleRaw is int)
                deductiblePercent = deductibleRaw.toDouble();
              else if (deductibleRaw is double)
                deductiblePercent = deductibleRaw;
              double rawTax = 0;
              if (item['expenseType'] is Map &&
                  (item['expenseType']['tax'] is num)) {
                rawTax = (item['expenseType']['tax'] as num).toDouble();
              } else if (item['tax'] is num) {
                rawTax = (item['tax'] as num).toDouble();
              }
              final double taxRate = rawTax <= 1 ? rawTax : rawTax / 100;
              final totalAfterDeductible =
                  total - (total * (deductiblePercent / 100));
              final totalAfterTax =
                  totalAfterDeductible - (totalAfterDeductible * taxRate);
              item['totalAfterTax'] = totalAfterTax.round();
            }
          }
        }
      }
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });

    // Trigger data change callback
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);

        // If auto-fill occurred, force an additional update cycle
        if (hasAutoFillChanges && mounted) {
          print('Triggering additional UI refresh cycles for auto-fill');

          // 1. Immediate setState
          setState(() {});

          // 2. Delayed setState to ensure modal UI updates
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              print('First delayed refresh');
              setState(() {});
              widget.onDataChanged!(_response);
            }
          });

          // 3. Another delayed setState for stubborn cases
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              print('Second delayed refresh');
              setState(() {});
            }
          });

          // 4. Force rebuild the entire collection by creating a new reference
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              print('Force rebuild collection');
              setState(() {
                // Create new list reference to force CoreCollection rebuild
                final currentList = _moduleData['generalExpense'] as List?;
                if (currentList != null) {
                  _moduleData['generalExpense'] = List.from(currentList);
                  _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
                  _response['itemDetail'] = Map<String, dynamic>.from(
                    _itemDetail,
                  );
                }
              });
              widget.onDataChanged!(_response);
            }
          });
        }
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
    final parentId =
        _moduleData['_parentId'] ??
        _moduleData['id'] ??
        _moduleData['travelClaimId'];
    final encodedParentId = parentId == null
        ? ''
        : Uri.encodeComponent(parentId.toString());
    // Detect hidden deductible flag from API: itemDetail.attribute.hidden.generalExpense.deductible == true
    final hiddenDeductible =
        _itemDetail['attribute']?['hidden']?['generalExpense']?['deductible'] ==
        true;
    final fieldConfigs = buildTrcInfoGeneralFieldConfigs(
      encodedParentId: encodedParentId,
      hiddenDeductible: hiddenDeductible,
    );

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
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Auto Generate Expense',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  child: TrcFancyButton(
                    label: 'PerDiem',
                    icon: Icons.flight_takeoff,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                    ),
                    loading: _isGeneratingPerdiem,
                    onTap: _isGeneratingPerdiem
                        ? null
                        : () => _generateExpense(
                            context,
                            code: 'TREXTY-10007',
                            isPerdiem: true,
                          ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TrcFancyButton(
                    label: 'Accomodation',
                    icon: Icons.hotel,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    ),
                    loading: _isGeneratingAccom,
                    onTap: _isGeneratingAccom
                        ? null
                        : () => _generateExpense(
                            context,
                            code: 'TREXTY-10005',
                            isPerdiem: false,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateExpense(
    BuildContext context, {
    required String code,
    required bool isPerdiem,
  }) async {
    final travelClaimId = _moduleData['id'];
    if (travelClaimId == null ||
        (travelClaimId is String && travelClaimId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Travel Claim ID not found.')),
      );
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
      final endpoint =
          'TRACLA/GEN.EXPENSE?code=$code&travelClaimId=$travelClaimId';
      appLogger.logWithClass(
        'TRCInfoGeneralTabBody',
        'Generating expenses via $endpoint',
      );
      LoadingOverlay.show(context, message: 'Generating expenses...');
      final res = await CoreService.instance.getDropdownData(endpoint);
      if (res['success'] == true) {
        final data = res['data'];
        if (data is List) {
          final List<dynamic> newItems = data
              .map((e) => _normalizeExpenseItem(e))
              .toList();
          final List<dynamic> current = List<dynamic>.from(
            _moduleData['generalExpense'] ?? [],
          );
          // Prepend new items
          _moduleData['generalExpense'] = [...newItems, ...current];
          // propagate changes
          _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
          setState(() {});
          if (widget.onDataChanged != null) {
            SchedulerBinding.instance.addPostFrameCallback(
              (_) => widget.onDataChanged!(_response),
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created ${newItems.length} expense item(s).'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Response is not a valid list.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generate expense failed: ${res['message'] ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  /// Auto-fill date when travelRequest is selected
  bool _handleTravelRequestAutoFill(Map<String, dynamic> item) {
    final travelRequest = item['travelRequest'];
    if (travelRequest is Map<String, dynamic>) {
      final startDate = travelRequest['startDate'];
      final endDate = travelRequest['endDate'];
      if (startDate != null) {
        final existing = item['date'];

        // Helper to parse various date input types safely
        DateTime? _parseDate(dynamic v) {
          if (v == null) return null;
          if (v is DateTime) return v;
          if (v is String && v.isNotEmpty) {
            try {
              return DateTime.parse(v);
            } catch (_) {
              return null;
            }
          }
          return null;
        }

        final existingDt = _parseDate(existing);
        final startDt = _parseDate(startDate);
        final endDt = _parseDate(endDate);

        // Only auto-fill when empty, or when existing date is out of the current travelRequest range
        final isEmpty =
            existing == null || (existing is String && existing.trim().isEmpty);
        final outOfRange =
            existingDt != null &&
            startDt != null &&
            (existingDt.isBefore(startDt) ||
                (endDt != null && existingDt.isAfter(endDt)));

        if (isEmpty || outOfRange) {
          final newDate = startDate;
          if (existing != newDate) {
            print('Auto-filling date: $newDate (previous: ${item['date']})');
            item['date'] = newDate;
            return true; // Data was changed
          }
        }
      }
    }
    return false; // No changes
  }

  /// Auto-fill total from perDiemAmount when locationObject is selected and expenseType is "Per Diem"
  bool _handleLocationAutoFill(Map<String, dynamic> item) {
    final locationObject = item['locationObject'];
    final expenseType = item['expenseType'];
    // Respect manual override flag set in modal editing
    if (item['_manualTotal'] == true) {
      return false; // Do not overwrite user-entered total
    }

    if (locationObject is Map<String, dynamic> &&
        expenseType is Map<String, dynamic>) {
      final expenseTypeId = expenseType['id'];
      final expenseTypeName = expenseType['name'];
      final perDiemAmount = locationObject['perDiemAmount'];

      // Check if this is a "Per Diem" expense type
      if (expenseTypeId == '225F3E9E-16CC-460D-B0F6-42167AC41EA8' ||
          (expenseTypeName != null &&
              expenseTypeName.toString().toLowerCase().contains('per diem'))) {
        if (perDiemAmount != null) {
          print(
            'Auto-filling total (parent-level) because no manual override: $perDiemAmount (previous: ${item['total']})',
          );
          item['total'] = perDiemAmount;
          return true; // Data was changed
        }
      }
    }
    return false; // No changes
  }
}
