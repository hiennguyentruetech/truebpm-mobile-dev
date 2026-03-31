part of 'core_collection.dart';

extension _CoreCollectionModalEditorExt on _CoreCollectionState {
  void _showEditModal(int index, Map<String, dynamic> item) {
    final editingItem = Map<String, dynamic>.from(item);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit ${widget.itemLabel ?? 'Item'} ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.children.length} fields to edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: _buildModalItemFields(
                              editingItem,
                              setModalState,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _replaceItem(index, editingItem);
                                  _notifyChange();
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildModalItemFields(
    Map<String, dynamic> item,
    StateSetter setModalState,
  ) {
    final itemItemDetail = {
      'value': item,
      'attribute': widget.itemDetail['attribute'] ?? {},
    };

    final parentCtx = widget.itemDetail['value'];
    final Map<String, dynamic> mergedCtx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ...item,
    };

    final List<Map<String, dynamic>> fieldConfigs =
        List<Map<String, dynamic>>.from(widget.children);

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) {
        setModalState(() {
          item[key] = value;
          if (key == 'total') {
            item['_manualTotal'] = true;
          }
          if (key == 'travelRequest' && value is Map) {
            final startDate = value['startDate'];
            if (startDate != null) {
              DateTime? parsed;
              if (startDate is DateTime) {
                parsed = startDate;
              } else if (startDate is String) {
                parsed =
                    DateTime.tryParse(startDate) ?? _tryParseDate(startDate);
              }
              if (parsed != null) {
                item['_defaultDate_date'] = parsed.toIso8601String();
              } else {
                item['_defaultDate_date'] = startDate.toString();
              }
            }
          }
          if (key == 'locationObject' || key == 'expenseType') {
            final expenseType = item['expenseType'];
            final locationObj = item['locationObject'];
            if (expenseType is Map && locationObj is Map) {
              final expenseTypeId = expenseType['id'];
              final perDiemAmount = locationObj['perDiemAmount'];
              if (perDiemAmount != null &&
                  expenseTypeId == '225F3E9E-16CC-460D-B0F6-42167AC41EA8') {
                item['total'] = perDiemAmount;
                item.remove('_manualTotal');
              }
            }
          }
        });
      },
    );
  }

  DateTime? _tryParseDate(String input) {
    final isoBasic = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoBasic.hasMatch(input)) {
      final parts = input.split('-');
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }

    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final slashMatch = slash.firstMatch(input);
    if (slashMatch != null) {
      final d = int.tryParse(slashMatch.group(1)!);
      final m = int.tryParse(slashMatch.group(2)!);
      final y = int.tryParse(slashMatch.group(3)!);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }

    final compact = RegExp(r'^(\d{2})(\d{2})(\d{4})$');
    final compactMatch = compact.firstMatch(input);
    if (compactMatch != null) {
      final d = int.tryParse(compactMatch.group(1)!);
      final m = int.tryParse(compactMatch.group(2)!);
      final y = int.tryParse(compactMatch.group(3)!);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }
}
