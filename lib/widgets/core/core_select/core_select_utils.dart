import 'package:flutter/material.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// CoreSelect utilities for API calls and data handling
class CoreSelectUtils {
  /// Load data from API
  static Future<List<dynamic>> loadOptionsFromAPI(
    String endpoint,
    BuildContext context, {
    bool showLoading = true,
  }) async {
    List<dynamic> options = [];
    bool hadError = false;

    // Show loading overlay
    if (showLoading && context.mounted) {
      LoadingOverlay.show(context, message: 'Loading options...');
    }

    try {
      final response = await CoreService.instance.getDropdownData(endpoint);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Handle different data types
        if (data is List) {
          options = List.from(data);
        } else {
          options = [data]; // Wrap single item in list
        }
      } else {
        hadError = true;
      }
    } catch (e) {
      hadError = true;
    } finally {
      // Hide loading overlay
      if (showLoading && context.mounted) {
        LoadingOverlay.hide();
      }
    }
    // Optional: brief user feedback on error (non-blocking)
    if (hadError && context.mounted) {
      // Use a SnackBar to avoid modal interruptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not load options (forbidden or unavailable).'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
    return options;
  }

  /// Get display text for an option
  static String getDisplayText(dynamic option, String? displayField) {
    if (option == null) return '';
    
    try {
      if (displayField != null && option is Map) {
        // Handle nested paths like 'userPermission.name'
        final displayValue = _getNestedValue(option, displayField);
        if (displayValue != null) {
          return displayValue.toString();
        } else {
          // If the specified display field is null, return empty string instead of fallback
          return '';
        }
      }
      
      // For primitive values or when no displayField specified
      if (option is String || option is num || option is bool) {
        return option.toString();
      }
      
      // For Map without displayField, try common fallback fields
      if (option is Map) {
        final fallbackFields = ['name', 'title', 'label', 'text', 'value'];
        for (final field in fallbackFields) {
          if (option[field] != null) {
            return option[field].toString();
          }
        }
        
        // If all fallback fields are null, return empty string
        return '';
      }
      
      return option.toString();
    } catch (e) {
      return '';
    }
  }

  /// Get the actual value from an option
  static dynamic getOptionValue(dynamic option, String? displayField) {
    if (displayField != null && option is Map) {
      return option; // Return the whole object for object-based options
    }
    return option; // Return the string value for primitive options
  }

  /// Compare two values for equality (handles objects and primitives)
  static bool compareValues(dynamic value1, dynamic value2, String? displayField) {
    if (value1 == null && value2 == null) return true;
    if (value1 == null || value2 == null) return false;
    
    // If both are Maps, compare by the display field or the whole object
    if (value1 is Map && value2 is Map) {
      if (displayField != null) {
        // Handle nested paths like 'userPermission.name'
        final val1 = _getNestedValue(value1, displayField);
        final val2 = _getNestedValue(value2, displayField);
        return val1 == val2;
      } else {
        return value1.toString() == value2.toString();
      }
    }
    
    // For other types, use direct comparison
    return value1 == value2;
  }

  /// Get nested value by 'a.b.c' path
  static dynamic _getNestedValue(Map<dynamic, dynamic> map, String path) {
    dynamic curr = map;
    for (final part in path.split('.')) {
      if (curr is Map && curr.containsKey(part)) {
        curr = curr[part];
      } else {
        return null;
      }
    }
    return curr;
  }

  /// Get default label from dataKey
  static String getDefaultLabel(String dataKey) {
    return dataKey.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  /// Filter options based on search text
  static List<dynamic> filterOptions(
    List<dynamic> options,
    String searchText,
    String Function(dynamic) getDisplayText,
    List<Map<String, String>>? moreDisplay,
  ) {
    if (searchText.isEmpty) {
      return List.from(options);
    } else {
      final searchLower = searchText.toLowerCase();
      final hasMoreDisplay = moreDisplay != null && moreDisplay.isNotEmpty;

      return options.where((option) {
        final displayText = getDisplayText(option).toLowerCase();

        if (displayText.contains(searchLower)) {
          return true;
        }

        if (hasMoreDisplay && option is Map) {
          for (final field in moreDisplay) {
            final key = field['key'] ?? '';
            final raw = getByPath(option, key);
            final value = raw?.toString().toLowerCase() ?? '';
            if (value.contains(searchLower)) {
              return true;
            }
          }
        }

        return false;
      }).toList();
    }
  }

  /// Safely get nested value by dot-notation path (e.g., 'customerId.name')
  static dynamic getByPath(Map obj, String path) {
    try {
      dynamic curr = obj;
      for (final part in path.split('.')) {
        if (curr is Map && curr.containsKey(part)) {
          curr = curr[part];
        } else {
          return null;
        }
      }
      return curr;
    } catch (_) {
      return null;
    }
  }
}
