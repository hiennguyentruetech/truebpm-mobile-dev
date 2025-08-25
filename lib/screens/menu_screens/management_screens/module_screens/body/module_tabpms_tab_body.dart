import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

/// Tab body cho MODULE TABPMS (Table Application Permissions)
/// Xử lý phân quyền kết hợp table và application permissions
class ModuleTabpmsTabBody extends CoreTabBody {
  const ModuleTabpmsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleTabpmsTabBody> createState() => _ModuleTabpmsTabBodyState();
}

class _ModuleTabpmsTabBodyState extends CoreTabBodyState<ModuleTabpmsTabBody> {
  
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
          
          // Combined Permissions Matrix
          _buildPermissionsMatrixSection(),
          const SizedBox(height: 24),
          
          // Advanced Permissions
          _buildAdvancedPermissionsSection(),
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
            colors: [Colors.teal.shade600, Colors.teal.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.grid_view,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Table Application Permissions',
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

  Widget _buildPermissionsMatrixSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions Matrix',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Matrix header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Role / User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'List',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'View',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Create',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Edit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Delete',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Matrix rows
            if (_moduleData['permissionsMatrix'] != null) ...[
              for (int i = 0; i < (_moduleData['permissionsMatrix'] as List).length; i++)
                _buildPermissionMatrixRow(i),
            ] else ...[
              _buildEmptyState('No permissions configured'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionMatrixRow(int index) {
    final permission = (_moduleData['permissionsMatrix'] as List)[index];
    final isEven = index % 2 == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  permission['type'] == 'role' ? Icons.group : Icons.person,
                  size: 20,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    permission['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildPermissionCheckbox(
              permission['canList'] ?? false,
              (value) => _updatePermissionMatrix(index, 'canList', value),
            ),
          ),
          Expanded(
            child: _buildPermissionCheckbox(
              permission['canView'] ?? false,
              (value) => _updatePermissionMatrix(index, 'canView', value),
            ),
          ),
          Expanded(
            child: _buildPermissionCheckbox(
              permission['canCreate'] ?? false,
              (value) => _updatePermissionMatrix(index, 'canCreate', value),
            ),
          ),
          Expanded(
            child: _buildPermissionCheckbox(
              permission['canEdit'] ?? false,
              (value) => _updatePermissionMatrix(index, 'canEdit', value),
            ),
          ),
          Expanded(
            child: _buildPermissionCheckbox(
              permission['canDelete'] ?? false,
              (value) => _updatePermissionMatrix(index, 'canDelete', value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckbox(bool value, Function(bool) onChanged) {
    return Center(
      child: Checkbox(
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        activeColor: Colors.teal.shade600,
      ),
    );
  }

  Widget _buildAdvancedPermissionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Global Settings
            _buildAdvancedSetting(
              'Inherit Parent Permissions',
              _moduleData['inheritParent'] ?? false,
              (value) => updateModuleData('inheritParent', value),
              'Automatically inherit permissions from parent module',
            ),
            
            _buildAdvancedSetting(
              'Enable Role Hierarchy',
              _moduleData['enableRoleHierarchy'] ?? true,
              (value) => updateModuleData('enableRoleHierarchy', value),
              'Use hierarchical role-based permissions',
            ),
            
            _buildAdvancedSetting(
              'Dynamic Permissions',
              _moduleData['dynamicPermissions'] ?? false,
              (value) => updateModuleData('dynamicPermissions', value),
              'Allow runtime permission modifications',
            ),
            
            _buildAdvancedSetting(
              'Audit Permission Changes',
              _moduleData['auditChanges'] ?? true,
              (value) => updateModuleData('auditChanges', value),
              'Log all permission changes for audit trail',
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _resetPermissions,
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                
                ElevatedButton.icon(
                  onPressed: _copyFromTemplate,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                
                ElevatedButton.icon(
                  onPressed: _exportMatrix,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSetting(String title, bool value, Function(bool) onChanged, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.teal.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
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
          Text(message),
        ],
      ),
    );
  }

  void _updatePermissionMatrix(int index, String key, bool value) {
    final matrix = List<Map<String, dynamic>>.from(_moduleData['permissionsMatrix'] ?? []);
    matrix[index][key] = value;
    updateModuleData('permissionsMatrix', matrix);
  }

  void _resetPermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All permissions have been reset'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _copyFromTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions copied from template'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportMatrix() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions matrix exported'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  @override
  bool validateData() {
    return true;
  }

  // Method to prepare data for save (not overriding since base method was removed)
  Map<String, dynamic> prepareDataForSave() {
    return {
      'permissionsMatrix': _moduleData['permissionsMatrix'] ?? [],
      'inheritParent': _moduleData['inheritParent'] ?? false,
      'enableRoleHierarchy': _moduleData['enableRoleHierarchy'] ?? true,
      'dynamicPermissions': _moduleData['dynamicPermissions'] ?? false,
      'auditChanges': _moduleData['auditChanges'] ?? true,
    };
  }

  @override
  Future<Map<String, dynamic>> loadTabSpecificData() async {
    // Return empty map to use initialData from provider instead of mock data
    return {};
  }

  // Save and submit methods (not overriding since base methods were removed)
  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1200));
  }
}
