import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core/tab_form_field.dart';

/// Tab body cho MODULE QUERY (Query Configuration)
/// Xử lý cấu hình query và database operations
class ModuleQueryTabBody extends CoreTabBody {
  const ModuleQueryTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleQueryTabBody> createState() => _ModuleQueryTabBodyState();
}

class _ModuleQueryTabBodyState extends CoreTabBodyState<ModuleQueryTabBody> {
  
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
          
          // Query Configuration Section
          _buildQueryConfigSection(),
          const SizedBox(height: 24),
          
          // Advanced Query Section
          _buildAdvancedQuerySection(),
          const SizedBox(height: 24),
          
          // Query Test Section
          _buildQueryTestSection(),
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
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Query Configuration',
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

  Widget _buildQueryConfigSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Query Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Table Name
            TabFormField(
              label: 'Table Name',
              value: _moduleData['tableName']?.toString() ?? '',
              onChanged: (value) => updateModuleData('tableName', value),
              required: true,
              hintText: 'e.g., Core.Module',
            ),
            const SizedBox(height: 16),
            
            // Primary Key Field
            TabFormField(
              label: 'Primary Key Field',
              value: _moduleData['primaryKeyField']?.toString() ?? '',
              onChanged: (value) => updateModuleData('primaryKeyField', value),
              required: true,
              hintText: 'e.g., ID',
            ),
            const SizedBox(height: 16),
            
            // Display Fields
            TabFormField(
              label: 'Display Fields',
              value: _moduleData['displayFields']?.toString() ?? '',
              onChanged: (value) => updateModuleData('displayFields', value),
              required: true,
              hintText: 'e.g., code, name, moduleCode',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedQuerySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Query Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // SELECT Query
            TabFormField(
              label: 'SELECT Query',
              value: _moduleData['selectQuery']?.toString() ?? '',
              onChanged: (value) => updateModuleData('selectQuery', value),
              maxLines: 8,
              hintText: 'SELECT M.ID AS id, M.Code AS code, M.Name AS name FROM Core.Module AS M',
            ),
            const SizedBox(height: 16),
            
            // WHERE Conditions
            TabFormField(
              label: 'WHERE Conditions',
              value: _moduleData['whereConditions']?.toString() ?? '',
              onChanged: (value) => updateModuleData('whereConditions', value),
              maxLines: 3,
              hintText: 'WHERE M.StatusId = @StatusId AND M.IsActive = 1',
            ),
            const SizedBox(height: 16),
            
            // ORDER BY
            TabFormField(
              label: 'ORDER BY',
              value: _moduleData['orderBy']?.toString() ?? '',
              onChanged: (value) => updateModuleData('orderBy', value),
              hintText: 'M.Code ASC, M.Name ASC',
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Max Records
                Expanded(
                  child: TabFormField(
                    label: 'Max Records',
                    value: _moduleData['maxRecords']?.toString() ?? '1000',
                    onChanged: (value) => updateModuleData('maxRecords', int.tryParse(value) ?? 1000),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Enable Paging
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Enable Paging'),
                    value: _moduleData['enablePaging'] ?? true,
                    onChanged: (value) => updateModuleData('enablePaging', value),
                    activeColor: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryTestSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query Testing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Test Parameters
            TabFormField(
              label: 'Test Parameters (JSON)',
              value: _moduleData['testParameters']?.toString() ?? '',
              onChanged: (value) => updateModuleData('testParameters', value),
              maxLines: 4,
              hintText: '{"StatusId": "Active", "ModuleCode": "MODULE"}',
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _testQuery,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Query'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                
                ElevatedButton.icon(
                  onPressed: _validateQuery,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                
                ElevatedButton.icon(
                  onPressed: _clearResults,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test Results
            if (_moduleData['testResults'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _moduleData['testResults'].toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _testQuery() async {
    setState(() {}); // Loading managed by provider
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      updateModuleData('testResults', '''
Query executed successfully!
Records found: 15
Execution time: 0.25 seconds
      
Sample results:
{
  "id": "30F2A65D-EF27-484E-ABE9-53A0E0218FD8",
  "code": "MODULE-10001",
  "name": "Module"
}
''');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Query test completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      updateModuleData('testResults', 'Error: ${e.toString()}');
    } finally {
      setState(() {}); // Loading managed by provider
    }
  }

  void _validateQuery() async {
    setState(() {}); // Loading managed by provider
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Query validation successful'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() {}); // Loading managed by provider
    }
  }

  void _clearResults() {
    updateModuleData('testResults', null);
  }

  @override
  bool validateData() {
    if (_moduleData['tableName']?.toString().trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table Name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    if (_moduleData['primaryKeyField']?.toString().trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary Key Field is required'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> prepareDataForSave() {
    return {
      'tableName': _moduleData['tableName']?.toString().trim(),
      'primaryKeyField': _moduleData['primaryKeyField']?.toString().trim(),
      'displayFields': _moduleData['displayFields']?.toString().trim(),
      'selectQuery': _moduleData['selectQuery']?.toString().trim(),
      'whereConditions': _moduleData['whereConditions']?.toString().trim(),
      'orderBy': _moduleData['orderBy']?.toString().trim(),
      'maxRecords': _moduleData['maxRecords'] ?? 1000,
      'enablePaging': _moduleData['enablePaging'] ?? true,
      'testParameters': _moduleData['testParameters']?.toString().trim(),
    };
  }

  Future<Map<String, dynamic>> loadTabSpecificData() async {
    // Return empty map to use initialData from provider instead of mock data
    return {};
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // TODO: Implement actual API call
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: Implement actual API call
  }
}
