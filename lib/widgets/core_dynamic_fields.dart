import 'package:flutter/material.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/core_datetime.dart';
import 'package:truebpm/widgets/core_collection.dart';
import 'package:truebpm/widgets/core_status_chip.dart';
import 'package:truebpm/widgets/core_tree.dart';
import 'package:truebpm/services/storage_service.dart';
import 'package:truebpm/utils/functions.dart';

/// Core Dynamic Fields Builder
/// A reusable widget for building dynamic form fields based on configuration
/// Supports input, select, datetime, and checkbox widgets
class CoreDynamicFields {
  /// Build dynamic fields from configuration list
  /// Returns a list of widgets based on field configurations
  static List<Widget> buildFields({
    required List<Map<String, dynamic>> fieldConfigs,
    required Map<String, dynamic> itemDetail,
    required Map<String, dynamic> moduleData,
    required Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
    Function(String)? isCommonField,
  }) {
    List<Widget> fields = [];

    // Build a context map that includes current item (value) and module-level data as fallback
    final Map<String, dynamic> contextMap = {
      ...moduleData,
      ...(itemDetail['value'] is Map<String, dynamic>
          ? itemDetail['value'] as Map<String, dynamic>
          : <String, dynamic>{}),
    };

    for (Map<String, dynamic> original in fieldConfigs) {
      final Map<String, dynamic> config = Map<String, dynamic>.from(original);
      final String fieldName = config['key'] ?? '';
      if (fieldName.isEmpty) continue;

      // Always include field if it's configured, unless visibility condition hides it
      bool shouldInclude = true;

      // Evaluate visibleWhen conditions if provided
      if (config.containsKey('visibleWhen')) {
        shouldInclude = _evaluateVisibility(config['visibleWhen'], contextMap);
      } else if (isCommonField != null) {
        // Legacy fallback for specific use cases that need data-driven field inclusion
        shouldInclude =
            moduleData.containsKey(fieldName) || isCommonField(fieldName);
      }

      if (!shouldInclude) continue;

      // Resolve dynamic templates in data endpoints (e.g., '.../API?x={{a.b}}')
      if (config['data'] is String &&
          (config['data'] as String).contains('{{')) {
        config['data'] = _resolveTemplate(config['data'] as String, contextMap);
      }

      // Prepare per-field onChanged wrapper to support clearOnChange
      final List<String> clearOnChange = List<String>.from(
        config['clearOnChange'] ?? const <String>[],
      );
      void wrappedOnChanged(String key, dynamic value) {
        onChanged(key, value);
        if (key == fieldName && clearOnChange.isNotEmpty) {
          for (final depKey in clearOnChange) {
            // Clear dependent keys; send null by default
            onChanged(depKey, null);
          }
        }
      }

      final String widgetType =
          config['widget'] ??
          'input'; // 'input', 'select', 'datetime', 'checkbox', 'collection', 'status'
      switch (widgetType) {
        case 'select':
          fields.add(
            _buildSelectField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
          break;
        case 'datetime':
          fields.add(
            _buildDateTimeField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
          break;
        case 'checkbox':
          fields.add(
            _buildCheckboxField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
          break;
        case 'collection':
          fields.add(
            _buildCollectionField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
          break;
        case 'tree':
          fields.add(
            _buildTreeField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
          break;
        case 'status':
          fields.add(
            _buildStatusField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
          break;
        default:
          fields.add(
            _buildInputField(
              config,
              itemDetail,
              wrappedOnChanged,
              getDefaultLabel,
            ),
          );
      }
    }

    return fields;
  }

  /// Build CoreInput field from configuration
  static Widget _buildInputField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final bool isRequired = config['required'] ?? false;
    final String? label = config['label'];
    final String? hintText = config['hintText'];
    final String typeStr = config['type'] ?? 'text';
    final int maxLines = config['maxLines'] ?? 1;
    final String? suffix = config['suffix'];
    final int decimalPlaces = config['decimalPlaces'] ?? 0;
    final double? minValue = config['minValue']?.toDouble();
    final double? maxValue = config['maxValue']?.toDouble();

    // Convert type string to enum
    CoreInputType inputType;
    switch (typeStr.toLowerCase()) {
      case 'number':
        inputType = CoreInputType.number;
        break;
      case 'currency':
        inputType = CoreInputType.currency;
        break;
      case 'textarea':
        inputType = CoreInputType.textarea;
        break;
      case 'email':
        inputType = CoreInputType.email;
        break;
      case 'phone':
        inputType = CoreInputType.phone;
        break;
      case 'password':
        inputType = CoreInputType.password;
        break;
      case 'url':
        inputType = CoreInputType.url;
        break;
      default:
        inputType = CoreInputType.text;
    }

    final bool? disabledOverride = config.containsKey('disabled')
        ? config['disabled'] as bool?
        : null;
    final bool? hiddenOverride = config.containsKey('hidden')
        ? config['hidden'] as bool?
        : null;

    return CoreInput(
      dataKey: fieldName,
      itemDetail: itemDetail,
      label:
          label ??
          (getDefaultLabel != null
              ? getDefaultLabel(fieldName)
              : CoreDynamicFields.getDefaultLabel(fieldName)),
      type: inputType,
      suffix: suffix,
      hintText: hintText,
      maxLines: maxLines,
      decimalPlaces: decimalPlaces,
      minValue: minValue,
      maxValue: maxValue,
      disabled: disabledOverride,
      hidden: hiddenOverride,
      onlyView: config['onlyView'] ?? false,
      onChanged: (value) {
        // Ensure numeric type for number inputs
        if (inputType == CoreInputType.number) {
          final text = value.trim();
          if (text.isEmpty) {
            onChanged(fieldName, null);
            return;
          }

          // Normalize the text: handle Vietnamese formatting (dots for thousands, comma for decimal)
          String normalized = text;
          if (text.contains(',')) {
            // Has comma (decimal), remove dots (thousands) and replace comma with dot
            normalized = text.replaceAll('.', '').replaceAll(',', '.');
          } else {
            // No comma, remove any commas and keep dots (assuming dots are thousands)
            // But if it's a simple number without thousands, keep as-is
            if (text.contains('.') && text.split('.').length > 2) {
              // Multiple dots = thousands separator, remove them
              normalized = text.replaceAll('.', '');
            }
          }

          // Parse to number
          final dynamic numeric = normalized.contains('.')
              ? double.tryParse(normalized)
              : int.tryParse(normalized);

          onChanged(fieldName, numeric);
        } else {
          onChanged(fieldName, value);
        }
      },
      required: isRequired,
    );
  }

  /// Build CoreSelect field from configuration
  static Widget _buildSelectField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final bool isRequired = config['required'] ?? false;
    final String? label = config['label'];
    final String? hintText = config['hintText'];
    final String selectTypeStr =
        config['selectType'] ?? 'select'; // 'select' or 'dropdown'
    final dynamic data = config['data']; // Can be List or String (API endpoint)
    final String? display = config['display']; // Display field for objects
    final List<Map<String, String>>? moreDisplay = config['moreDisplay']
        ?.cast<Map<String, String>>();

    // Special case for grantPermission with userPermission wrapper
    final String? specialDisplay =
        config['specialDisplay']; // For special display format like 'userPermission.name'
    final bool useUserPermissionWrapper =
        config['useUserPermissionWrapper'] ?? false;

    // Split key functionality for different display in input vs dropdown
    final bool splitKey = config['splitKey'] ?? false;
    final String? dropdownDisplay = config['dropdownDisplay'];

    // Validate splitKey configuration
    if (splitKey && dropdownDisplay == null) {
      // If splitKey is true, dropdownDisplay should be provided
      debugPrint(
        'Warning: splitKey is true but dropdownDisplay is not provided for field $fieldName',
      );
    }

    // Convert selectType string to enum
    CoreSelectType selectType;
    switch (selectTypeStr.toLowerCase()) {
      case 'dropdown':
        selectType = CoreSelectType.dropdown;
        break;
      case 'multiple':
        selectType = CoreSelectType.multiple;
        break;
      default:
        selectType = CoreSelectType.select;
    }

    // Build a stable key that changes when endpoint or field changes to avoid state reuse
    final String dataKeyForKey = data is String ? data : 'static';
    final Key widgetKey = ValueKey<String>(
      'select:$fieldName|data:$dataKeyForKey',
    );

    final bool? disabledOverride = config.containsKey('disabled')
        ? config['disabled'] as bool?
        : null;
    final bool? hiddenOverride = config.containsKey('hidden')
        ? config['hidden'] as bool?
        : null;

    return CoreSelect(
      key: widgetKey,
      dataKey: fieldName,
      itemDetail: itemDetail,
      label:
          label ??
          (getDefaultLabel != null
              ? getDefaultLabel(fieldName)
              : CoreDynamicFields.getDefaultLabel(fieldName)),
      type: selectType,
      hintText: hintText,
      disabled: disabledOverride ?? false,
      hidden: hiddenOverride ?? false,
      data: data,
      display: display,
      moreDisplay: moreDisplay,
      onChanged: (value) => onChanged(fieldName, value),
      required: isRequired,
      // Pass special configuration
      specialDisplay: specialDisplay,
      useUserPermissionWrapper: useUserPermissionWrapper,
      // Pass split key configuration
      splitKey: splitKey,
      dropdownDisplay: dropdownDisplay,
    );
  }

  /// Build CoreDateTime field from configuration
  static Widget _buildDateTimeField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final bool isRequired = config['required'] ?? false;
    final String? label = config['label'];
    final String? hintText = config['hintText'];
    final String datetimeTypeStr =
        config['datetimeType'] ??
        'date'; // 'date', 'datetime', 'time', 'daterange'
    final String? startDateKey = config['startDateKey'];
    final String? endDateKey = config['endDateKey'];
    final String displayFormatStr = config['displayFormat'] ?? 'ddMMyyyy';
    final String? defaultDatePath = config['defaultDatePath'];
    DateTime? defaultDate;

    // Parse min/max constraints
    DateTime? minDate = config['minDate'] != null
        ? (config['minDate'] is DateTime
              ? config['minDate']
              : DateTime.tryParse(config['minDate'].toString()))
        : null;
    DateTime? maxDate = config['maxDate'] != null
        ? (config['maxDate'] is DateTime
              ? config['maxDate']
              : DateTime.tryParse(config['maxDate'].toString()))
        : null;

    // Dynamic date constraints via path
    dynamic getByPathLocal(Map<String, dynamic>? map, String path) {
      if (map == null) return null;
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

    final valueMap = itemDetail['value'] is Map<String, dynamic>
        ? itemDetail['value'] as Map<String, dynamic>
        : <String, dynamic>{};
    if (config['minDatePath'] != null && minDate == null) {
      final raw = getByPathLocal(valueMap, config['minDatePath']);
      if (raw is DateTime) {
        minDate = raw;
      } else if (raw is String) {
        minDate = DateTime.tryParse(raw);
      }
    }
    if (config['maxDatePath'] != null && maxDate == null) {
      final raw = getByPathLocal(valueMap, config['maxDatePath']);
      if (raw is DateTime) {
        maxDate = raw;
      } else if (raw is String) {
        maxDate = DateTime.tryParse(raw);
      }
    }
    if (defaultDatePath != null) {
      final raw = getByPathLocal(valueMap, defaultDatePath);
      if (raw is DateTime) {
        defaultDate = raw;
      } else if (raw is String) {
        defaultDate = DateTime.tryParse(raw);
      }
    }
    final TimeOfDay? minTime = config['minTime'] != null
        ? _parseTimeOfDay(config['minTime'])
        : null;
    final TimeOfDay? maxTime = config['maxTime'] != null
        ? _parseTimeOfDay(config['maxTime'])
        : null;
    // Default time for time pickers
    final TimeOfDay? defaultTime = config['defaultTime'] != null
        ? _parseTimeOfDay(config['defaultTime'])
        : null;

    // Convert datetimeType string to enum
    CoreDateTimeType datetimeType;
    switch (datetimeTypeStr.toLowerCase()) {
      case 'datetime':
        datetimeType = CoreDateTimeType.datetime;
        break;
      case 'time':
        datetimeType = CoreDateTimeType.time;
        break;
      case 'daterange':
        datetimeType = CoreDateTimeType.daterange;
        break;
      default:
        datetimeType = CoreDateTimeType.date;
    }

    // Convert displayFormat string to enum
    DateDisplayFormat displayFormat;
    switch (displayFormatStr.toLowerCase()) {
      case 'yyyymmdd':
        displayFormat = DateDisplayFormat.yyyyMMdd;
        break;
      case 'mmddyyyy':
        displayFormat = DateDisplayFormat.mmddyyyy;
        break;
      default:
        displayFormat = DateDisplayFormat.ddMMyyyy;
    }

    // Determine disabled override with optional required key dependencies.
    // IMPORTANT: We only pass a non-null disabled/hidden override to CoreDateTime when we *intend* to override
    // the attribute map coming from backend. If we always pass `false`, the widget's internal logic
    // (which first checks widget.disabled != null) would ignore attribute-based disabled flags.
    bool? disabledOverride = config.containsKey('disabled')
        ? config['disabled'] as bool?
        : null;
    bool unmetDependency = false;
    if (config['requireKeys'] is List) {
      for (final keyPath in (config['requireKeys'] as List)) {
        final dep = getByPathLocal(valueMap, keyPath.toString());
        if (dep == null || (dep is String && dep.isEmpty)) {
          unmetDependency = true;
          break;
        }
      }
    }
    if (unmetDependency) {
      disabledOverride = true; // force disable when dependencies not satisfied
    }
    final bool? hiddenOverride = config.containsKey('hidden')
        ? config['hidden'] as bool?
        : null;

    return CoreDateTime(
      dataKey: fieldName,
      startDateKey: startDateKey,
      endDateKey: endDateKey,
      itemDetail: itemDetail,
      label:
          label ??
          (getDefaultLabel != null
              ? getDefaultLabel(fieldName)
              : CoreDynamicFields.getDefaultLabel(fieldName)),
      type: datetimeType,
      displayFormat: displayFormat,
      hintText: hintText,
      minDate: minDate,
      maxDate: maxDate,
      minTime: minTime,
      maxTime: maxTime,
      defaultTime: defaultTime,
      defaultDate: defaultDate,
      disabled: disabledOverride,
      hidden: hiddenOverride,
      onChanged: datetimeType != CoreDateTimeType.daterange
          ? (value) => onChanged(fieldName, value)
          : null,
      onStartDateChanged:
          datetimeType == CoreDateTimeType.daterange && startDateKey != null
          ? (value) => onChanged(startDateKey, value)
          : null,
      onEndDateChanged:
          datetimeType == CoreDateTimeType.daterange && endDateKey != null
          ? (value) => onChanged(endDateKey, value)
          : null,
      required: isRequired,
    );
  }

  /// Build CoreCheckbox field from configuration
  static Widget _buildCheckboxField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final bool isRequired = config['required'] ?? false;
    final String? label = config['label'];
    final String? hintText = config['hintText'];
    final bool initialValue = config['initialValue'] ?? false;
    final String checkboxStyleStr =
        config['checkboxStyle'] ?? 'material'; // 'material', 'custom', 'switch'
    final String positionStr =
        config['position'] ?? 'leading'; // 'leading', 'trailing'
    final Color? checkboxColor = config['checkboxColor'];
    final IconData? customCheckedIcon = config['customCheckedIcon'];
    final IconData? customUncheckedIcon = config['customUncheckedIcon'];

    // Convert checkboxStyle string to enum
    CheckboxStyle checkboxStyle;
    switch (checkboxStyleStr.toLowerCase()) {
      case 'custom':
        checkboxStyle = CheckboxStyle.custom;
        break;
      case 'switch':
        checkboxStyle = CheckboxStyle.switchStyle;
        break;
      default:
        checkboxStyle = CheckboxStyle.material;
    }

    // Convert position string to enum
    CheckboxPosition position;
    switch (positionStr.toLowerCase()) {
      case 'trailing':
        position = CheckboxPosition.trailing;
        break;
      default:
        position = CheckboxPosition.leading;
    }

    return CoreCheckbox(
      dataKey: fieldName,
      itemDetail: itemDetail,
      label:
          label ??
          (getDefaultLabel != null
              ? getDefaultLabel(fieldName)
              : CoreDynamicFields.getDefaultLabel(fieldName)),
      hintText: hintText,
      initialValue: initialValue,
      style: checkboxStyle,
      position: position,
      checkboxColor: checkboxColor,
      customCheckedIcon: customCheckedIcon,
      customUncheckedIcon: customUncheckedIcon,
      disabled: config['disabled'],
      hidden: config['hidden'],
      onChanged: (value) => onChanged(fieldName, value),
      required: isRequired,
    );
  }

  /// Build Collection field from configuration
  static Widget _buildCollectionField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final bool isRequired = config['required'] ?? false;
    final String? label = config['label'];
    final String? hintText = config['hintText'];
    final List<Map<String, dynamic>> children = List<Map<String, dynamic>>.from(
      config['children'] ?? [],
    );
    final String? itemLabel = config['itemLabel'];
    final String? addButtonText = config['addButtonText'];
    final bool allowAdd = config['allowAdd'] ?? true;
    final bool allowRemove = config['allowRemove'] ?? true;
    final int? maxItems = config['maxItems'];
    final int? minItems = config['minItems'];
    final String editMode = config['editMode'] ?? 'inline';
    final Map<String, dynamic>? summary =
        config['summary'] as Map<String, dynamic>?;
    final bool useFloatingAddButton = config['useFloatingAddButton'] ?? false;
    final bool useAddFirstList = config['useAddFirstList'] ?? false;
    final Map<String, dynamic>? totalSummary =
        config['totalSummary'] as Map<String, dynamic>?;
    final String? titleTemplate = config['titleTemplate'];
    final List<Map<String, dynamic>>? footerActions =
        (config['footerActions'] as List?)?.cast<Map<String, dynamic>>();
    final onFooterAction =
        config['onFooterAction']
            as void Function(
              BuildContext,
              Map<String, dynamic>,
              Map<String, dynamic>,
            )?;

    return CoreCollection(
      dataKey: fieldName,
      itemDetail: itemDetail,
      label:
          label ??
          (getDefaultLabel != null
              ? getDefaultLabel(fieldName)
              : CoreDynamicFields.getDefaultLabel(fieldName)),
      hintText: hintText,
      children: children,
      itemLabel: itemLabel,
      addButtonText: addButtonText,
      allowAdd: allowAdd,
      allowRemove: allowRemove,
      maxItems: maxItems,
      minItems: minItems,
      onChanged: (value) => onChanged(fieldName, value),
      required: isRequired,
      editMode: editMode,
      summary: summary,
      useFloatingAddButton:
          useFloatingAddButton, // When true, CoreCollection hides bottom add button
      useAddFirstList: useAddFirstList,
      totalSummary: totalSummary,
      titleTemplate: titleTemplate,
      footerActions: footerActions,
      onFooterAction: onFooterAction,
    );
  }

  /// Build CoreTree field from configuration
  static Widget _buildTreeField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final bool isRequired = config['required'] ?? false;
    final String? label = config['label'];
    final String? hintText = config['hintText'];
    final List<Map<String, dynamic>> children = List<Map<String, dynamic>>.from(
      config['children'] ?? [],
    );
    final String? itemLabel = config['itemLabel'];
    final String? addButtonText = config['addButtonText'];
    final bool allowAdd = config['allowAdd'] ?? true;
    final bool allowEdit = config['allowEdit'] ?? true;
    final bool allowDelete = config['allowDelete'] ?? true;
    final Map<String, dynamic>? summary = config['summary'];
    final String? headerTemplate = config['headerTemplate'];
    final bool isUseUpdateAction = config['isUseUpdateAction'] ?? false;
    final bool isOnItemDetailValue = config['isOnItemDetailValue'] ?? false;
    final String? titleKey = config['titleKey'];
    final String? titleTemplate = config['titleTemplate'];
    final List<Map<String, dynamic>>? footerActions =
        (config['footerActions'] as List?)?.cast<Map<String, dynamic>>();
    final onFooterAction =
        config['onFooterAction']
            as void Function(
              BuildContext,
              Map<String, dynamic>,
              Map<String, dynamic>,
            )?;
    final List<String>? commonFields = (config['commonFields'] as List?)
        ?.cast<String>();

    // Level-based action restrictions
    final Map<String, dynamic>? levelRestrictions =
        config['levelRestrictions'] as Map<String, dynamic>?;
    // ignore: unused_local_variable
    final int? minLevelForAdd = levelRestrictions?['minLevelForAdd'] as int?;
    // ignore: unused_local_variable
    final int? minLevelForEdit = levelRestrictions?['minLevelForEdit'] as int?;
    // ignore: unused_local_variable
    final int? minLevelForDelete =
        levelRestrictions?['minLevelForDelete'] as int?;
    // ignore: unused_local_variable
    final int? minLevelForFooterActions =
        levelRestrictions?['minLevelForFooterActions'] as int?;
    // ignore: unused_local_variable
    final int? maxLevel = levelRestrictions?['maxLevel'] as int?;
    // ignore: unused_local_variable
    final bool? preventChildCreation =
        levelRestrictions?['preventChildCreation'] as bool?;
    // ignore: unused_local_variable
    final bool? showNextLevelIcon =
        levelRestrictions?['showNextLevelIcon'] as bool?;

    // Default values for tree fields
    final Map<String, dynamic>? defaultValues =
        config['defaultValues'] as Map<String, dynamic>?;

    // Permission-based action restrictions
    final Map<String, dynamic>? permissions =
        config['permissions'] as Map<String, dynamic>?;

    return CoreTree(
      dataKey: fieldName,
      itemDetail: itemDetail,
      label:
          label ??
          (getDefaultLabel != null
              ? getDefaultLabel(fieldName)
              : CoreDynamicFields.getDefaultLabel(fieldName)),
      hintText: hintText,
      children: children,
      itemLabel: itemLabel,
      addButtonText: addButtonText,
      allowAdd: allowAdd,
      allowEdit: allowEdit,
      allowDelete: allowDelete,
      summary: summary,
      headerTemplate: headerTemplate,
      isUseUpdateAction: isUseUpdateAction,
      isOnItemDetailValue: isOnItemDetailValue,
      titleKey: titleKey,
      titleTemplate: titleTemplate,
      footerActions: footerActions,
      onFooterAction: onFooterAction,
      commonFields: commonFields,
      required: isRequired,
      onChanged: (value) => onChanged(fieldName, value),
      // Level-based action restrictions
      levelRestrictions: levelRestrictions,
      // Default values for tree fields
      defaultValues: defaultValues,
      // Permission-based action restrictions
      permissions: permissions,
    );
  }

  /// Helper method to parse TimeOfDay from various formats
  static TimeOfDay? _parseTimeOfDay(dynamic timeValue) {
    if (timeValue is TimeOfDay) return timeValue;
    if (timeValue is Map) {
      final int? hour = timeValue['hour'];
      final int? minute = timeValue['minute'];
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    if (timeValue is String) {
      final parts = timeValue.split(':');
      if (parts.length >= 2) {
        final int? hour = int.tryParse(parts[0]);
        final int? minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    return null;
  }

  /// Default method to get label for field
  /// Convert camelCase to Title Case
  static String getDefaultLabel(String fieldName) {
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Validate data based on required fields from attributes
  /// Returns true if all required fields are filled, false otherwise
  /// Shows SnackBar with error message if validation fails
  static bool validateData({
    required BuildContext context,
    required Map<String, dynamic> moduleData,
    required Map<String, dynamic> itemDetail,
    Function(String)? getCustomLabel,
  }) {
    final attributes = itemDetail['attribute'] ?? {};
    final requiredFields = attributes['required'] ?? {};

    for (String fieldName in moduleData.keys) {
      if (requiredFields[fieldName] == true) {
        final value = moduleData[fieldName]?.toString().trim();
        if (value == null || value.isEmpty) {
          final label =
              getCustomLabel?.call(fieldName) ?? getDefaultLabel(fieldName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label is required'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      }
    }
    return true;
  }

  /// Default common fields list for reference
  static const List<String> defaultCommonFields = [
    'code',
    'name',
    'moduleCode',
    'description',
    'createdBy',
    'createdDate',
  ];

  /// Default common field checker
  static bool isDefaultCommonField(String fieldName) {
    return defaultCommonFields.contains(fieldName);
  }

  /// Resolve string template with {{path.to.value}} placeholders from context
  /// Special handling for {{username}} to get current logged-in username
  static String _resolveTemplate(
    String template,
    Map<String, dynamic> context,
  ) {
    return template.replaceAllMapped(RegExp(r'{{\s*([^}]+)\s*}}'), (match) {
      final path = match.group(1)!.trim();

      // Special handling for username
      if (path == 'username') {
        // Get username from StorageService synchronously
        try {
          final username =
              StorageService.prefs.getString('saved_username') ?? '';
          return username.isNotEmpty ? Uri.encodeComponent(username) : '';
        } catch (e) {
          return '';
        }
      }

      // Regular path resolution
      final value = _getByPath(context, path);
      return (value == null || value.toString().isEmpty)
          ? ''
          : Uri.encodeComponent(value.toString());
    });
  }

  /// Get nested value by 'a.b.c' path
  static dynamic _getByPath(Map<String, dynamic> map, String path) {
    return Functions().getByPath(map, path, supportListLength: false);
  }

  /// Evaluate visibleWhen conditions.
  /// Supports:
  /// - List of { key, operator, value } where operator in: eq, ne, in, notEmpty, empty, exists, notExists
  /// - Single Map will be treated as a one-item list
  static bool _evaluateVisibility(
    dynamic visibleWhen,
    Map<String, dynamic> context,
  ) {
    return Functions().evaluateVisibility(visibleWhen, context);
  }

  /// Build CoreStatusChip field from configuration
  static Widget _buildStatusField(
    Map<String, dynamic> config,
    Map<String, dynamic> itemDetail,
    Function(String, dynamic) onChanged,
    Function(String)? getDefaultLabel,
  ) {
    final String fieldName = config['key'] ?? '';
    final String? label = config['label'];
    final CoreStatusChipSize size = _parseStatusChipSize(config['size']);
    final bool showIcon = config['showIcon'] ?? true;

    return CoreStatusChip(
      dataKey: fieldName,
      itemDetail: itemDetail,
      label: label,
      size: size,
      showIcon: showIcon,
      disabled: config['disabled'] ?? false,
      hidden: config['hidden'] ?? false,
    );
  }

  /// Parse status chip size from config
  static CoreStatusChipSize _parseStatusChipSize(dynamic sizeConfig) {
    if (sizeConfig is String) {
      switch (sizeConfig.toLowerCase()) {
        case 'small':
          return CoreStatusChipSize.small;
        case 'large':
          return CoreStatusChipSize.large;
        default:
          return CoreStatusChipSize.medium;
      }
    }
    return CoreStatusChipSize.medium;
  }
}
