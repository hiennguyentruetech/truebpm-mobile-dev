import 'package:flutter/material.dart';
import 'package:truebpm/utils/core_constants.dart';

class TaskListItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final List<String> headers;
  final List<String> contents;
  final VoidCallback? onTap;

  const TaskListItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.headers,
    required this.contents,
    this.onTap,
  });

  @override
  State<TaskListItemCard> createState() => _TaskListItemCardState();
}

class _TaskListItemCardState extends State<TaskListItemCard> {
  double _cardScale = 1.0;
  bool _isTapped = false;

  // Parse "key(type)" -> key, type
  ({String key, String? type}) _parseContentKey(String raw) {
    final m = RegExp(r'^(.*?)\s*\((.*?)\)\s* ? ? ?').firstMatch(raw);
    if (m != null) {
      return (key: m.group(1)!.trim(), type: m.group(2)!.trim().toLowerCase());
    }
    return (key: raw.trim(), type: null);
  }

  String? _getNestedValue(Map<String, dynamic> item, String path) {
    try {
      List<String> keys = path.split('.');
      dynamic value = item;
      
      for (String key in keys) {
        if (value is Map<String, dynamic> && value.containsKey(key)) {
          value = value[key];
        } else {
          return null;
        }
      }
      
      return value?.toString();
    } catch (e) {
      return null;
    }
  }

  // Date formatting helper with optional type hint
  String _formatDateIfNeeded(String header, String? raw, {String? typeHint}) {
    if (raw == null || raw.isEmpty) return '-';
    final isDateByHeader = header.toLowerCase().contains('date');
    final isDate = isDateByHeader || (typeHint == 'date');
    if (!isDate) return raw;
    try {
      // Parse as UTC to avoid timezone conversion
      final dt = DateTime.parse(raw).toUtc();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final hasTime = !(hh == '00' && mm == '00');
      final dd = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      final datePart = '$dd/$mo/$yyyy';
      return hasTime ? '$datePart $hh:$mm' : datePart;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? codeValue;
    List<MapEntry<String, String>> fieldsWithLabel = [];

    for (int i = 0; i < widget.contents.length && i < widget.headers.length; i++) {
      final parsed = _parseContentKey(widget.contents[i]);
      final raw = _getNestedValue(widget.item, parsed.key) ?? '-';
      final display = _formatDateIfNeeded(widget.headers[i], raw, typeHint: parsed.type);
      final header = widget.headers[i];
      
      if (parsed.key.toLowerCase().contains('code') && codeValue == null) {
        codeValue = display;
      } else {
        fieldsWithLabel.add(MapEntry(header, display));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() { _cardScale = CoreConstants.cardScaleOnTap; _isTapped = true; });
        },
        onTapUp: (_) {
          setState(() { _cardScale = 1.0; _isTapped = false; });
        },
        onTapCancel: () { setState(() { _cardScale = 1.0; _isTapped = false; }); },
        child: AnimatedScale(
          scale: _isTapped ? _cardScale : 1.0,
          duration: CoreConstants.cardAnimationDuration,
          curve: Curves.easeInOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(CoreConstants.cardBorderRadius),
              onTap: () { widget.onTap?.call(); },
              child: Card(
                elevation: CoreConstants.cardElevation,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CoreConstants.cardBorderRadius),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CoreConstants.cardBorderRadius),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 3.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CoreConstants.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header với STT, status & Code
                        _buildCardHeader(codeValue),
                        const SizedBox(height: 13),
                        // Các fields khác
                        if (fieldsWithLabel.isNotEmpty) ...[
                          ...fieldsWithLabel.map((field) => _TaskInfoRow(label: field.key, value: field.value)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(String? codeValue) {
    return Row(
      children: [
        // STT Circle - Display index + 1 for tasks
        Container(
          width: CoreConstants.circleSize,
          height: CoreConstants.circleSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (widget.index + 1).toString(), // Index starts from 1 for tasks
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        // Code container
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                codeValue ?? 'N/A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _TaskInfoRow({ required this.label, required this.value });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CoreConstants.infoBorderRadius),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label - 40% width, align right
            Expanded(
              flex: 40,
              child: Container(
                padding: const EdgeInsets.only(right: 0),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: null,
                ),
              ),
            ),
            // Dấu ":"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
            // Value - 60% width, align left
            Expanded(
              flex: 60,
              child: Container(
                padding: const EdgeInsets.only(left: 5),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
