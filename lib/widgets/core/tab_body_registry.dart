import 'package:flutter/material.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

/// Signature for tab body constructor
typedef TabBodyConstructor = CoreTabBody Function({
  required String moduleCode,
  required String tabCode,
  String? itemId,
  Map<String, dynamic>? initialData,
  Function(Map<String, dynamic>)? onDataChanged,
});

/// Registry for dynamic tab body registration and creation
/// This replaces the hardcoded TabBodyFactory with a flexible registration system
class TabBodyRegistry {
  static final Map<String, TabBodyConstructor> _registry = {};
  
  /// Register a tab body constructor for a specific module and tab combination
  static void register({
    required String moduleCode,
    required String tabCode,
    required TabBodyConstructor constructor,
  }) {
    final key = _buildKey(moduleCode, tabCode);
    _registry[key] = constructor;
  }
  
  /// Register a tab body constructor for all tabs of a specific module
  static void registerForAllTabs({
    required String moduleCode,
    required TabBodyConstructor constructor,
  }) {
    final key = _buildKey(moduleCode, '*');
    _registry[key] = constructor;
  }
  
  /// Create a tab body widget based on module and tab codes
  static Widget? createTabBody({
    required String moduleCode,
    required String tabCode,
    String? itemId,
    Map<String, dynamic>? initialData,
    Function(Map<String, dynamic>)? onDataChanged,
  }) {
    // Try specific module-tab combination first
    final specificKey = _buildKey(moduleCode, tabCode);
    final specificConstructor = _registry[specificKey];
    
    if (specificConstructor != null) {
      return specificConstructor(
        moduleCode: moduleCode,
        tabCode: tabCode,
        itemId: itemId,
        initialData: initialData,
        onDataChanged: onDataChanged,
      );
    }
    
    // Try wildcard (all tabs for this module)
    final wildcardKey = _buildKey(moduleCode, '*');
    final wildcardConstructor = _registry[wildcardKey];
    
    if (wildcardConstructor != null) {
      return wildcardConstructor(
        moduleCode: moduleCode,
        tabCode: tabCode,
        itemId: itemId,
        initialData: initialData,
        onDataChanged: onDataChanged,
      );
    }
    
    // Return fallback widget if no constructor found
    return _createFallbackWidget(moduleCode, tabCode);
  }
  
  /// Check if a tab body is registered for the given module and tab
  static bool isRegistered({
    required String moduleCode,
    required String tabCode,
  }) {
    final specificKey = _buildKey(moduleCode, tabCode);
    final wildcardKey = _buildKey(moduleCode, '*');
    
    return _registry.containsKey(specificKey) || _registry.containsKey(wildcardKey);
  }
  
  /// Get all registered module-tab combinations
  static List<String> getRegisteredKeys() {
    return _registry.keys.toList();
  }
  
  /// Clear all registrations (useful for testing)
  static void clearAll() {
    _registry.clear();
  }
  
  /// Build registry key from module and tab codes
  static String _buildKey(String moduleCode, String tabCode) {
    return '${moduleCode.toUpperCase()}_${tabCode.toUpperCase()}';
  }
  
  /// Create fallback widget when no tab body is registered
  static Widget _createFallbackWidget(String moduleCode, String tabCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tab Not Implemented',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Module: $moduleCode\nTab: $tabCode',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'Register this tab body using TabBodyRegistry.register()',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
