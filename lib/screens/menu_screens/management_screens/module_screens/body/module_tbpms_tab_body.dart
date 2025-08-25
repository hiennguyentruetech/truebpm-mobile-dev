import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

/// Tab body cho MODULE TBPMS (Table Permissions)
/// Xử lý phân quyền table-level permissions
class ModuleTbpmsTabBody extends CoreTabBody {
  const ModuleTbpmsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleTbpmsTabBody> createState() => _ModuleTbpmsTabBodyState();
}

class _ModuleTbpmsTabBodyState extends CoreTabBodyState<ModuleTbpmsTabBody> {
  
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
          
          // Permission Overview
          _buildPermissionOverviewSection(),
          const SizedBox(height: 24),
          
          // Role Permissions
          _buildRolePermissionsSection(),
          const SizedBox(height: 24),
          
          // User Permissions
          _buildUserPermissionsSection(),
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
            colors: [Colors.purple.shade600, Colors.purple.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.security,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Table Permissions',
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

  Widget _buildPermissionOverviewSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permission Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Permission Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Roles',
                    '${_moduleData['totalRoles'] ?? 5}',
                    Icons.group,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    '${_moduleData['totalUsers'] ?? 25}',
                    Icons.person,
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Permissions',
                    '${_moduleData['activePermissions'] ?? 15}',
                    Icons.check_circle,
                    Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshPermissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                
                ElevatedButton.icon(
                  onPressed: _exportPermissions,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissionsSection() {
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
                  'Role Permissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addRolePermission,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Role permissions list
            if (_moduleData['rolePermissions'] != null) ...[
              for (int i = 0; i < (_moduleData['rolePermissions'] as List).length; i++)
                _buildRolePermissionItem(i),
            ] else ...[
              _buildEmptyState('No role permissions configured'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRolePermissionItem(int index) {
    final rolePermission = (_moduleData['rolePermissions'] as List)[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: Colors.purple.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rolePermission['roleName'] ?? 'Unnamed Role',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editRolePermission(index),
                icon: const Icon(Icons.edit),
                color: Colors.purple.shade600,
              ),
              IconButton(
                onPressed: () => _removeRolePermission(index),
                icon: const Icon(Icons.delete),
                color: Colors.red.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Permission checkboxes
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildPermissionChip('Read', rolePermission['canRead'] ?? false, (value) {
                _updateRolePermission(index, 'canRead', value);
              }),
              _buildPermissionChip('Create', rolePermission['canCreate'] ?? false, (value) {
                _updateRolePermission(index, 'canCreate', value);
              }),
              _buildPermissionChip('Update', rolePermission['canUpdate'] ?? false, (value) {
                _updateRolePermission(index, 'canUpdate', value);
              }),
              _buildPermissionChip('Delete', rolePermission['canDelete'] ?? false, (value) {
                _updateRolePermission(index, 'canDelete', value);
              }),
              _buildPermissionChip('Execute', rolePermission['canExecute'] ?? false, (value) {
                _updateRolePermission(index, 'canExecute', value);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserPermissionsSection() {
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
                  'User Permissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addUserPermission,
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // User permissions list
            if (_moduleData['userPermissions'] != null) ...[
              for (int i = 0; i < (_moduleData['userPermissions'] as List).length; i++)
                _buildUserPermissionItem(i),
            ] else ...[
              _buildEmptyState('No user permissions configured'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserPermissionItem(int index) {
    final userPermission = (_moduleData['userPermissions'] as List)[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userPermission['userName'] ?? 'Unnamed User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editUserPermission(index),
                icon: const Icon(Icons.edit),
                color: Colors.blue.shade600,
              ),
              IconButton(
                onPressed: () => _removeUserPermission(index),
                icon: const Icon(Icons.delete),
                color: Colors.red.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Permission checkboxes
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildPermissionChip('Read', userPermission['canRead'] ?? false, (value) {
                _updateUserPermission(index, 'canRead', value);
              }),
              _buildPermissionChip('Create', userPermission['canCreate'] ?? false, (value) {
                _updateUserPermission(index, 'canCreate', value);
              }),
              _buildPermissionChip('Update', userPermission['canUpdate'] ?? false, (value) {
                _updateUserPermission(index, 'canUpdate', value);
              }),
              _buildPermissionChip('Delete', userPermission['canDelete'] ?? false, (value) {
                _updateUserPermission(index, 'canDelete', value);
              }),
              _buildPermissionChip('Execute', userPermission['canExecute'] ?? false, (value) {
                _updateUserPermission(index, 'canExecute', value);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: Colors.purple.shade200,
      checkmarkColor: Colors.purple.shade700,
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

  // Event handlers
  void _refreshPermissions() async {
    setState(() {}); // Loading managed by provider
    try {
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions refreshed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() {}); // Loading managed by provider
    }
  }

  void _exportPermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting permissions...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _addRolePermission() {
    final rolePermissions = List<Map<String, dynamic>>.from(_moduleData['rolePermissions'] ?? []);
    rolePermissions.add({
      'roleId': '',
      'roleName': 'New Role',
      'canRead': false,
      'canCreate': false,
      'canUpdate': false,
      'canDelete': false,
      'canExecute': false,
    });
    updateModuleData('rolePermissions', rolePermissions);
  }

  void _editRolePermission(int index) {
    // TODO: Show dialog to edit role permission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit role permission ${index + 1}'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _removeRolePermission(int index) {
    final rolePermissions = List<Map<String, dynamic>>.from(_moduleData['rolePermissions'] ?? []);
    rolePermissions.removeAt(index);
    updateModuleData('rolePermissions', rolePermissions);
  }

  void _updateRolePermission(int index, String key, bool value) {
    final rolePermissions = List<Map<String, dynamic>>.from(_moduleData['rolePermissions'] ?? []);
    rolePermissions[index][key] = value;
    updateModuleData('rolePermissions', rolePermissions);
  }

  void _addUserPermission() {
    final userPermissions = List<Map<String, dynamic>>.from(_moduleData['userPermissions'] ?? []);
    userPermissions.add({
      'userId': '',
      'userName': 'New User',
      'canRead': false,
      'canCreate': false,
      'canUpdate': false,
      'canDelete': false,
      'canExecute': false,
    });
    updateModuleData('userPermissions', userPermissions);
  }

  void _editUserPermission(int index) {
    // TODO: Show dialog to edit user permission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit user permission ${index + 1}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _removeUserPermission(int index) {
    final userPermissions = List<Map<String, dynamic>>.from(_moduleData['userPermissions'] ?? []);
    userPermissions.removeAt(index);
    updateModuleData('userPermissions', userPermissions);
  }

  void _updateUserPermission(int index, String key, bool value) {
    final userPermissions = List<Map<String, dynamic>>.from(_moduleData['userPermissions'] ?? []);
    userPermissions[index][key] = value;
    updateModuleData('userPermissions', userPermissions);
  }

  @override
  bool validateData() {
    // Basic validation
    return true;
  }

  @override
  Map<String, dynamic> prepareDataForSave() {
    return {
      'rolePermissions': _moduleData['rolePermissions'] ?? [],
      'userPermissions': _moduleData['userPermissions'] ?? [],
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
