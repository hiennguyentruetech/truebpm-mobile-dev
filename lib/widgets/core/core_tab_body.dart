import 'package:flutter/material.dart';

/// Abstract base class for tab body components
/// Provides common structure and data handling while allowing custom content
abstract class CoreTabBody extends StatefulWidget {
  final String moduleCode;
  final String tabCode;
  final String? itemId;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>)? onDataChanged; // Callback để sync data ngược lại

  const CoreTabBody({
    super.key,
    required this.moduleCode,
    required this.tabCode,
    this.itemId,
    this.initialData,
    this.onDataChanged,
  });

  @override
  CoreTabBodyState createState();
}

/// Abstract state class for tab body components
abstract class CoreTabBodyState<T extends CoreTabBody> extends State<T> {

  bool _isLoading = false;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _loadTabData();
  }

  /// Abstract method to build tab-specific content
  Widget buildTabContent(BuildContext context);


  /// Abstract method to validate form data (optional for future use)
  bool validateData() => true;


  /// Load data for this specific tab
  Future<void> _loadTabData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await loadTabSpecificData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }


  /// Override to implement tab-specific data loading
  Future<void> loadTabSpecificData() async {
    // Default implementation - override in subclasses
    await Future.delayed(const Duration(milliseconds: 300));
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Error message
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _errorMessage = null),
                  color: Colors.red.shade600,
                ),
              ],
            ),
          ),

        // Main content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : buildTabContent(context),
        ),

        // Action buttons - Moved to AppBar in DetailCoreScreen
      ],
    );
  }
}
