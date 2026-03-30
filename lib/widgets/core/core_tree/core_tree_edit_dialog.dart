part of 'core_tree.dart';

class _TreeItemEditDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final bool isAdd;
  final List<Map<String, dynamic>> children;
  final String itemLabel;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic> parentItemDetail;

  const _TreeItemEditDialog({
    required this.item,
    required this.isAdd,
    required this.children,
    required this.itemLabel,
    required this.onSave,
    required this.parentItemDetail,
  });

  @override
  State<_TreeItemEditDialog> createState() => _TreeItemEditDialogState();
}

class _TreeItemEditDialogState extends State<_TreeItemEditDialog> {
  Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeForm() {
    // Initialize form data; if the dialog opens mid-build, defer state updates
    _formData = Map<String, dynamic>.from(widget.item ?? {});
  }

  List<Widget> _buildFields() {
    final itemItemDetail = {
      'value': _formData,
      'attribute': widget.parentItemDetail['attribute'] ?? {},
    };

    final parentCtx = widget.parentItemDetail['value'];
    final Map<String, dynamic> mergedCtx = {
      if (parentCtx is Map<String, dynamic>) ...parentCtx,
      ..._formData,
    };

    final List<Map<String, dynamic>> fieldConfigs =
        List<Map<String, dynamic>>.from(widget.children);

    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: itemItemDetail,
      moduleData: mergedCtx,
      onChanged: (key, value) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _formData[key] = value;
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with gradient (match CoreCollection)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
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
                child: Icon(
                  widget.isAdd ? Icons.add_rounded : Icons.edit_outlined,
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
                      '${widget.isAdd ? 'Add' : 'Edit'} ${widget.itemLabel}',
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

        // Modal Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: _buildFields()),
          ),
        ),

        // Bottom toolbar (match CoreCollection)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                  label: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                    // Close dialog first to avoid navigation issues
                    Navigator.of(context).pop();
                    // Delay save to ensure dialog is fully closed
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.onSave(_formData);
                    });
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    widget.isAdd ? 'Add' : 'Save',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}
