import 'package:flutter/material.dart';

/// Custom time picker widget với wheel selection
class CustomTimePicker extends StatelessWidget {
  final TimeOfDay currentTime;
  final Function(TimeOfDay) onTimeChanged;
  final TimeOfDay? minTime;
  final TimeOfDay? maxTime;

  const CustomTimePicker({
    super.key,
    required this.currentTime,
    required this.onTimeChanged,
    this.minTime,
    this.maxTime,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Helper to check if a time is within min/max
    bool isTimeAllowed(int hour, int minute) {
      if (minTime != null) {
        if (hour < minTime!.hour || (hour == minTime!.hour && minute < minTime!.minute)) {
          return false;
        }
      }
      if (maxTime != null) {
        if (hour > maxTime!.hour || (hour == maxTime!.hour && minute > maxTime!.minute)) {
          return false;
        }
      }
      return true;
    }

    return Column(
      children: [
        // Digital time display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatTimeForDisplay(currentTime),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              fontFamily: 'monospace',
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Hour and minute selectors
        Row(
          children: [
            // Hour selector
            Expanded(
              child: _buildTimeSelector(
                'Hour',
                24,
                currentTime.hour,
                (index) => onTimeChanged(TimeOfDay(hour: index, minute: currentTime.minute)),
                (index) => isTimeAllowed(index, currentTime.minute),
              ),
            ),

            const SizedBox(width: 20),

            // Minute selector
            Expanded(
              child: _buildTimeSelector(
                'Minute',
                60,
                currentTime.minute,
                (index) => onTimeChanged(TimeOfDay(hour: currentTime.hour, minute: index)),
                (index) => isTimeAllowed(currentTime.hour, index),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    int itemCount,
    int selectedValue,
    Function(int) onChanged,
    bool Function(int)? isAllowedChecker,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: selectedValue),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                final isSelected = index == selectedValue;
                final allowed = isAllowedChecker == null ? true : isAllowedChecker(index);
                return Opacity(
                  opacity: allowed ? 1.0 : 0.3,
                  child: IgnorePointer(
                    ignoring: !allowed,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeForDisplay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
