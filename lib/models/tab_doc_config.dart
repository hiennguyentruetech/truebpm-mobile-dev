import 'package:flutter/material.dart';
/// Configuration for sub-tabs within Document (DOC) tabs
class TabDocConfig {
  final String code;
  final String name;
  final bool isDefault;
  final IconData? iconData;

  const TabDocConfig({
    required this.code,
    required this.name,
    this.isDefault = false,
    this.iconData,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'isDefault': isDefault,
    'iconData': iconData != null ? iconData!.codePoint : null,
    'iconFontFamily': iconData != null ? iconData!.fontFamily : null,
    'iconFontPackage': iconData != null ? iconData!.fontPackage : null,
  };

  factory TabDocConfig.fromJson(Map<String, dynamic> json) => TabDocConfig(
    code: json['code'] as String,
    name: json['name'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
    iconData: json['iconData'] != null
        ? IconData(
            json['iconData'] as int,
            fontFamily: json['iconFontFamily'] as String?,
            fontPackage: json['iconFontPackage'] as String?,
          )
        : null,
  );
}
