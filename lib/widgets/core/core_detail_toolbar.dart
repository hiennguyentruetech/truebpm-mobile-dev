import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';

class CoreDetailToolbar extends StatelessWidget {
  final ToolbarConfig? toolbarConfig;
  final Function(ToolbarAction) onActionTap;

  const CoreDetailToolbar({
    super.key,
    required this.toolbarConfig,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side actions
          Expanded(
            child: Row(
              children: [
                _buildToolbarButton(
                  ToolbarAction.save,
                  Icons.save,
                  'Save',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  ToolbarAction.submit,
                  Icons.send,
                  'Submit',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  ToolbarAction.copy,
                  Icons.copy,
                  'Copy',
                  Colors.orange,
                ),
              ],
            ),
          ),
          // Right side actions
          Row(
            children: [
              _buildToolbarButton(
                ToolbarAction.print,
                Icons.print,
                'Print',
                Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                ToolbarAction.delete,
                Icons.delete,
                'Delete',
                Colors.red,
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                ToolbarAction.cancel,
                Icons.close,
                'Cancel',
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    ToolbarAction action,
    IconData icon,
    String label,
    Color color,
  ) {
    final isVisible = toolbarConfig?.isVisible(action.value) ?? true;
    final isEnabled = toolbarConfig?.isEnabled(action.value) ?? true;

    if (!isVisible) return const SizedBox.shrink();

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isEnabled ? () => onActionTap(action) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              color: isEnabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled ? color : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? color : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
