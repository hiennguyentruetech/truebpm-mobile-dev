import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core/tab_form_field.dart';

/// Tab body cho MODULE CONFIG (Grid Configuration)
/// Xử lý cấu hình grid và display settings
class ModuleConfigTabBody extends CoreTabBody {
  const ModuleConfigTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleConfigTabBody> createState() => _ModuleConfigTabBodyState();
}

class _ModuleConfigTabBodyState extends CoreTabBodyState<ModuleConfigTabBody> {
  
  // Local data storage to replace removed formData
  Map<String, dynamic> _moduleData = {};
  
  @override
  void initState() {
    super.initState();
    _moduleData = Map<String, dynamic>.from(widget.initialData ?? {});
  }
  
  // Method to update module data
  void updateModuleData(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
    });
  }
  
  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(),
          const SizedBox(height: 24),
          
          // Grid Display Configuration
          _buildGridDisplaySection(),
          const SizedBox(height: 24),
          
          // Column Configuration
          _buildColumnConfigSection(),
          const SizedBox(height: 24),
          
          // Toolbar Configuration
          _buildToolbarConfigSection(),
          const SizedBox(height: 24),
          
          // Action Buttons Configuration
          _buildActionButtonsSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.orange.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.settings,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Grid Configuration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Module: ${_moduleData['moduleCode']?.toString() ?? 'MODULE'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDisplaySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grid Display Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Headers configuration
            TabFormField(
              label: 'Headers',
              value: _moduleData['headers']?.toString() ?? '',
              onChanged: (value) => updateModuleData('headers', value),
              required: true,
              hintText: 'Code, Name, Module Code',
            ),
            const SizedBox(height: 16),
            
            // Content configuration
            TabFormField(
              label: 'Content Fields',
              value: _moduleData['content']?.toString() ?? '',
              onChanged: (value) => updateModuleData('content', value),
              required: true,
              hintText: 'code, name, moduleCode',
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Page Size
                Expanded(
                  child: TabFormField(
                    label: 'Page Size',
                    value: _moduleData['pageSize']?.toString() ?? '20',
                    onChanged: (value) => updateModuleData('pageSize', int.tryParse(value) ?? 20),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Enable Pagination
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Enable Pagination'),
                    value: _moduleData['enablePagination'] ?? true,
                    onChanged: (value) => updateModuleData('enablePagination', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Enable Sorting
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Enable Sorting'),
                    value: _moduleData['enableSorting'] ?? true,
                    onChanged: (value) => updateModuleData('enableSorting', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
                
                // Enable Filtering
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Enable Filtering'),
                    value: _moduleData['enableFiltering'] ?? true,
                    onChanged: (value) => updateModuleData('enableFiltering', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnConfigSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Column Configuration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewColumn,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Column'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Column list
            if (_moduleData['columns'] != null) ...[
              for (int i = 0; i < (_moduleData['columns'] as List).length; i++)
                _buildColumnItem(i),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    const Text('No columns configured. Click "Add Column" to start.'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColumnItem(int index) {
    final column = (_moduleData['columns'] as List)[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Column ${index + 1}: ${column['name'] ?? 'Unnamed'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editColumn(index),
                icon: const Icon(Icons.edit),
                color: Colors.orange.shade600,
              ),
              IconButton(
                onPressed: () => _removeColumn(index),
                icon: const Icon(Icons.delete),
                color: Colors.red.shade600,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Field: ${column['field'] ?? 'N/A'}'),
              ),
              Expanded(
                child: Text('Type: ${column['type'] ?? 'Text'}'),
              ),
              Expanded(
                child: Text('Width: ${column['width'] ?? 'Auto'}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarConfigSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toolbar Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Show Search
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show Search'),
                    value: _moduleData['showSearch'] ?? true,
                    onChanged: (value) => updateModuleData('showSearch', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
                
                // Show Export
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show Export'),
                    value: _moduleData['showExport'] ?? false,
                    onChanged: (value) => updateModuleData('showExport', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            
            Row(
              children: [
                // Show Refresh
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show Refresh'),
                    value: _moduleData['showRefresh'] ?? true,
                    onChanged: (value) => updateModuleData('showRefresh', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
                
                // Show Column Chooser
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Column Chooser'),
                    value: _moduleData['showColumnChooser'] ?? false,
                    onChanged: (value) => updateModuleData('showColumnChooser', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Buttons',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Enable Add
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Enable Add'),
                    value: _moduleData['enableAdd'] ?? true,
                    onChanged: (value) => updateModuleData('enableAdd', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
                
                // Enable Edit
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Enable Edit'),
                    value: _moduleData['enableEdit'] ?? true,
                    onChanged: (value) => updateModuleData('enableEdit', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            
            Row(
              children: [
                // Enable Delete
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Enable Delete'),
                    value: _moduleData['enableDelete'] ?? true,
                    onChanged: (value) => updateModuleData('enableDelete', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
                
                // Enable View
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Enable View'),
                    value: _moduleData['enableView'] ?? true,
                    onChanged: (value) => updateModuleData('enableView', value),
                    activeColor: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewColumn() {
    final columns = List<Map<String, dynamic>>.from(_moduleData['columns'] ?? []);
    columns.add({
      'name': 'New Column',
      'field': 'newField',
      'type': 'Text',
      'width': 100,
      'visible': true,
      'sortable': true,
      'filterable': true,
    });
    updateModuleData('columns', columns);
  }

  void _editColumn(int index) {
    // TODO: Show dialog to edit column
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit column ${index + 1}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _removeColumn(int index) {
    final columns = List<Map<String, dynamic>>.from(_moduleData['columns'] ?? []);
    columns.removeAt(index);
    updateModuleData('columns', columns);
  }

  @override
  bool validateData() {
    if (_moduleData['headers']?.toString().trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Headers configuration is required'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    if (_moduleData['content']?.toString().trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content fields configuration is required'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }

  @override
  Map<String, dynamic> prepareDataForSave() {
    return {
      'headers': _moduleData['headers']?.toString().trim(),
      'content': _moduleData['content']?.toString().trim(),
      'pageSize': _moduleData['pageSize'] ?? 20,
      'enablePagination': _moduleData['enablePagination'] ?? true,
      'enableSorting': _moduleData['enableSorting'] ?? true,
      'enableFiltering': _moduleData['enableFiltering'] ?? true,
      'columns': _moduleData['columns'] ?? [],
      'showSearch': _moduleData['showSearch'] ?? true,
      'showExport': _moduleData['showExport'] ?? false,
      'showRefresh': _moduleData['showRefresh'] ?? true,
      'showColumnChooser': _moduleData['showColumnChooser'] ?? false,
      'enableAdd': _moduleData['enableAdd'] ?? true,
      'enableEdit': _moduleData['enableEdit'] ?? true,
      'enableDelete': _moduleData['enableDelete'] ?? true,
      'enableView': _moduleData['enableView'] ?? true,
    };
  }

  @override
  Future<Map<String, dynamic>> loadTabSpecificData() async {
    // Return empty map to use initialData from provider instead of mock data
    return {};
  }

  @override
  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // TODO: Implement actual API call
  }

  @override
  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: Implement actual API call
  }
}
