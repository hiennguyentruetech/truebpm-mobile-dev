import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

/// Tab body cho MODULE ATPMS (Application Permissions)
/// Xử lý phân quyền application-level permissions
class ModuleAtpmsTabBody extends CoreTabBody {
  const ModuleAtpmsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ModuleAtpmsTabBody> createState() => _ModuleAtpmsTabBodyState();
}

class _ModuleAtpmsTabBodyState extends CoreTabBodyState<ModuleAtpmsTabBody> {
  
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
          
          // Application Functions
          _buildApplicationFunctionsSection(),
          const SizedBox(height: 24),
          
          // Menu Permissions
          _buildMenuPermissionsSection(),
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
            colors: [Colors.indigo.shade600, Colors.indigo.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.apps,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Application Permissions',
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

  Widget _buildApplicationFunctionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Functions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Application functions list
            if (_moduleData['appFunctions'] != null) ...[
              for (int i = 0; i < (_moduleData['appFunctions'] as List).length; i++)
                _buildAppFunctionItem(i),
            ] else ...[
              _buildEmptyState('No application functions defined'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppFunctionItem(int index) {
    final appFunction = (_moduleData['appFunctions'] as List)[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.functions,
            color: Colors.indigo.shade600,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appFunction['name'] ?? 'Function',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  appFunction['description'] ?? 'No description',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: appFunction['enabled'] ?? false,
            onChanged: (value) => _updateAppFunction(index, 'enabled', value),
            activeColor: Colors.indigo.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPermissionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Menu permissions list
            if (_moduleData['menuPermissions'] != null) ...[
              for (int i = 0; i < (_moduleData['menuPermissions'] as List).length; i++)
                _buildMenuPermissionItem(i),
            ] else ...[
              _buildEmptyState('No menu permissions configured'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuPermissionItem(int index) {
    final menuPermission = (_moduleData['menuPermissions'] as List)[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu,
            color: Colors.blue.shade600,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menuPermission['menuName'] ?? 'Menu Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  menuPermission['path'] ?? 'No path',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: menuPermission['visible'] ?? false,
            onChanged: (value) => _updateMenuPermission(index, 'visible', value),
            activeColor: Colors.blue.shade600,
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

  void _updateAppFunction(int index, String key, dynamic value) {
    final appFunctions = List<Map<String, dynamic>>.from(_moduleData['appFunctions'] ?? []);
    appFunctions[index][key] = value;
    updateModuleData('appFunctions', appFunctions);
  }

  void _updateMenuPermission(int index, String key, dynamic value) {
    final menuPermissions = List<Map<String, dynamic>>.from(_moduleData['menuPermissions'] ?? []);
    menuPermissions[index][key] = value;
    updateModuleData('menuPermissions', menuPermissions);
  }

  @override
  bool validateData() {
    return true;
  }

  @override
  Map<String, dynamic> prepareDataForSave() {
    return {
      'appFunctions': _moduleData['appFunctions'] ?? [],
      'menuPermissions': _moduleData['menuPermissions'] ?? [],
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
  }

  @override
  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1200));
  }
}
