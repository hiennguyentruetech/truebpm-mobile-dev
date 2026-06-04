import 'package:flutter/material.dart';

class CoreDetailResponse {
  final ItemDetail? itemDetail;
  final ToolbarConfig? toolbar;
  final String? title;
  final List<TabConfig>? tabs;

  CoreDetailResponse({this.itemDetail, this.toolbar, this.title, this.tabs});

  factory CoreDetailResponse.fromJson(Map<String, dynamic> json) {
    return CoreDetailResponse(
      itemDetail: json['itemDetail'] != null
          ? ItemDetail.fromJson(json['itemDetail'])
          : null,
      toolbar: json['toolbar'] != null
          ? ToolbarConfig.fromJson(json['toolbar'])
          : null,
      title: json['title']?.toString(),
      tabs: json['tabs'] != null
          ? (json['tabs'] as List).map((e) => TabConfig.fromJson(e)).toList()
          : null,
    );
  }
}

class ItemDetail {
  final Map<String, dynamic> value;
  final DetailAttributes? attribute;
  final ToolbarConfig? toolbar;

  ItemDetail({required this.value, this.attribute, this.toolbar});

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      value: json['value'] ?? {},
      attribute: json['attribute'] != null
          ? DetailAttributes.fromJson(json['attribute'])
          : null,
      toolbar: json['toolbar'] != null
          ? ToolbarConfig.fromJson(json['toolbar'])
          : null,
    );
  }
}

class DetailAttributes {
  final Map<String, bool> disabled;
  final Map<String, bool> hidden;
  final Map<String, bool> required;

  DetailAttributes({
    required this.disabled,
    required this.hidden,
    required this.required,
  });

  /// Safely extract only top-level bool entries from a map that may contain
  /// nested objects (e.g. `"createdBy": {"fullName": false}`).
  /// Non-bool values are skipped to avoid [TypeError] from `Map<String, bool>.from()`.
  static Map<String, bool> _flatBoolMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, bool>{};
    for (final entry in raw.entries) {
      if (entry.value is bool) {
        result[entry.key.toString()] = entry.value as bool;
      }
      // Skip nested maps / non-bool values — they are handled
      // directly by widgets via raw itemDetail['attribute'] traversal.
    }
    return result;
  }

  factory DetailAttributes.fromJson(Map<String, dynamic> json) {
    return DetailAttributes(
      disabled: _flatBoolMap(json['disabled']),
      hidden: _flatBoolMap(json['hidden']),
      required: _flatBoolMap(json['required']),
    );
  }

  bool isDisabled(String key) => disabled[key] ?? false;
  bool isHidden(String key) => hidden[key] ?? false;
  bool isRequired(String key) => required[key] ?? false;
}

class ToolbarConfig {
  final Map<String, bool> disabled;
  final Map<String, bool> hidden;

  ToolbarConfig({required this.disabled, required this.hidden});

  factory ToolbarConfig.fromJson(Map<String, dynamic> json) {
    return ToolbarConfig(
      disabled: Map<String, bool>.from(json['disabled'] ?? {}),
      hidden: Map<String, bool>.from(json['hidden'] ?? {}),
    );
  }

  bool isVisible(String action) => !(hidden[action] ?? false);
  bool isEnabled(String action) => !(disabled[action] ?? false);
}

class TabConfig {
  final String code;
  final String? apiCode;
  final String name;
  final bool isDefault;
  final Widget Function({
    required String moduleCode,
    required String tabCode,
    String? itemId,
    Map<String, dynamic>? initialData,
    Function(Map<String, dynamic>)? onDataChanged,
  })?
  tabBodyBuilder;

  TabConfig({
    required this.code,
    this.apiCode,
    required this.name,
    this.isDefault = false,
    this.tabBodyBuilder,
  });

  factory TabConfig.fromJson(Map<String, dynamic> json) {
    return TabConfig(
      code: json['code']?.toString() ?? '',
      apiCode: json['apiCode']?.toString(),
      name: json['name']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      // tabBodyBuilder không thể serialize từ JSON
    );
  }
}

// Enum for toolbar actions
enum ToolbarAction {
  save('save'),
  submit('submit'),
  copy('copy'),
  cancel('cancel'),
  delete('delete'),
  print('print'),
  refresh('refresh');

  const ToolbarAction(this.value);
  final String value;
}
