import 'package:flutter/material.dart';
import 'package:truebpm/models/core_data_model.dart';

class DataSpySelector extends StatelessWidget {
  final DataSpies? dataSpies;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const DataSpySelector({
    super.key,
    required this.dataSpies,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (dataSpies == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedId,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade600),
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: dataSpies!.data
              .map((e) => DropdownMenuItem<String>(
                    value: e.id,
                    child: Row(
                      children: [
                        Icon(Icons.data_usage, 
                             color: Colors.blue.shade400, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          hint: Row(
            children: [
              Icon(Icons.data_usage, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              const Text('Chọn DataSpy'),
            ],
          ),
        ),
      ),
    );
  }
}
