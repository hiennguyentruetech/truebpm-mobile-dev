import 'package:flutter/material.dart';

class CoreDetailResponse {
  final ItemDetail? itemDetail;
  final ToolbarConfig? toolbar;
  final String? title;
  final List<TabConfig>? tabs;

  CoreDetailResponse({
    this.itemDetail,
    this.toolbar,
    this.title,
    this.tabs,
  });

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

  ItemDetail({
    required this.value,
    this.attribute,
    this.toolbar,
  });

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

  factory DetailAttributes.fromJson(Map<String, dynamic> json) {
    return DetailAttributes(
      disabled: Map<String, bool>.from(json['disabled'] ?? {}),
      hidden: Map<String, bool>.from(json['hidden'] ?? {}),
      required: Map<String, bool>.from(json['required'] ?? {}),
    );
  }

  bool isDisabled(String key) => disabled[key] ?? false;
  bool isHidden(String key) => hidden[key] ?? false;
  bool isRequired(String key) => required[key] ?? false;
}

class ToolbarConfig {
  final Map<String, bool> disabled;
  final Map<String, bool> hidden;

  ToolbarConfig({
    required this.disabled,
    required this.hidden,
  });

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
  final String name;
  final bool isDefault;
  final Widget Function({
    required String moduleCode,
    required String tabCode,
    String? itemId,
    Map<String, dynamic>? initialData,
    Function(Map<String, dynamic>)? onDataChanged,
  })? tabBodyBuilder;

  TabConfig({
    required this.code,
    required this.name,
    this.isDefault = false,
    this.tabBodyBuilder,
  });

  factory TabConfig.fromJson(Map<String, dynamic> json) {
    return TabConfig(
      code: json['code']?.toString() ?? '',
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
