/// Dashboard Models
/// Data models for Dashboard module with Chart support

import 'package:flutter/material.dart';

// ============================================================================
// CHART CONFIG MODELS
// ============================================================================

/// Chart configuration item from API
class ChartConfigItem {
  final String id;
  final String code;
  final String name;
  final String? xAxisUnit;
  final String? yAxisUnit;
  final ChartTypeInfo? chartType;
  final bool isDefault;
  final bool isActive;
  final bool isMenu;
  final List<ChartConfigItem>? children;
  final String? label; // For menu items

  ChartConfigItem({
    required this.id,
    required this.code,
    required this.name,
    this.xAxisUnit,
    this.yAxisUnit,
    this.chartType,
    this.isDefault = false,
    this.isActive = true,
    this.isMenu = false,
    this.children,
    this.label,
  });

  factory ChartConfigItem.fromJson(Map<String, dynamic> json) {
    return ChartConfigItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['label']?.toString() ?? '',
      xAxisUnit: json['xAxisUnit']?.toString(),
      yAxisUnit: json['yAxisUnit']?.toString(),
      chartType: json['chartType'] != null 
          ? ChartTypeInfo.fromJson(json['chartType']) 
          : null,
      isDefault: json['isDefault'] == true,
      isActive: json['isActive'] == true,
      isMenu: json['isMenu'] == true,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((e) => ChartConfigItem.fromJson(e))
              .toList()
          : null,
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'xAxisUnit': xAxisUnit,
    'yAxisUnit': yAxisUnit,
    'chartType': chartType?.toJson(),
    'isDefault': isDefault,
    'isActive': isActive,
    'isMenu': isMenu,
    'children': children?.map((e) => e.toJson()).toList(),
    'label': label,
  };

  /// Get display name (name for chart items, label for menu items)
  String get displayName => isMenu ? (label ?? name) : name;

  /// Flatten tree to get all chart items (non-menu)
  List<ChartConfigItem> get allChartItems {
    List<ChartConfigItem> items = [];
    if (!isMenu) {
      items.add(this);
    }
    if (children != null) {
      for (var child in children!) {
        items.addAll(child.allChartItems);
      }
    }
    return items;
  }
}

/// Chart type information
class ChartTypeInfo {
  final String id;
  final String name;

  ChartTypeInfo({
    required this.id,
    required this.name,
  });

  factory ChartTypeInfo.fromJson(Map<String, dynamic> json) {
    return ChartTypeInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  /// Get chart type enum
  DashboardChartType get type {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('bar')) return DashboardChartType.bar;
    if (nameLower.contains('line')) return DashboardChartType.line;
    if (nameLower.contains('pie')) return DashboardChartType.pie;
    if (nameLower.contains('area')) return DashboardChartType.area;
    return DashboardChartType.bar;
  }
}

/// Dashboard chart types
enum DashboardChartType {
  bar,
  line,
  pie,
  area,
}

// ============================================================================
// CHART CONFIGS RESPONSE
// ============================================================================

/// Response for chartConfigs from PAGEDATA
class ChartConfigsResponse {
  final List<ChartConfigItem> data;
  final ChartConfigItem? value;

  ChartConfigsResponse({
    required this.data,
    this.value,
  });

  factory ChartConfigsResponse.fromJson(Map<String, dynamic> json) {
    return ChartConfigsResponse(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => ChartConfigItem.fromJson(e))
              .toList()
          : [],
      value: json['value'] != null 
          ? ChartConfigItem.fromJson(json['value']) 
          : null,
    );
  }

  /// Get all available charts (flattened from tree structure)
  List<ChartConfigItem> get allCharts {
    List<ChartConfigItem> charts = [];
    for (var item in data) {
      charts.addAll(item.allChartItems);
    }
    return charts;
  }

  /// Get default chart
  ChartConfigItem? get defaultChart => value;
}

// ============================================================================
// INBOX DATA MODELS
// ============================================================================

/// Inbox data item from DASHBOARD.LST
class InboxDataItem {
  final String id;
  final String key;
  final String title;
  final String? description;
  final dynamic value;
  final String? unit;
  final bool isDefault;
  final String? createdDate;

  InboxDataItem({
    required this.id,
    required this.key,
    required this.title,
    this.description,
    this.value,
    this.unit,
    this.isDefault = false,
    this.createdDate,
  });

  factory InboxDataItem.fromJson(Map<String, dynamic> json) {
    return InboxDataItem(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      value: json['value'],
      unit: json['unit']?.toString(),
      isDefault: json['isDefault'] == true,
      createdDate: json['createdDate']?.toString(),
    );
  }

  /// Get formatted value
  String get formattedValue {
    if (value == null) return '0';
    if (value is num) {
      final numValue = value as num;
      if (numValue == numValue.toInt()) {
        return numValue.toInt().toString();
      }
      return numValue.toStringAsFixed(1);
    }
    return value.toString();
  }

  /// Get icon based on title/key
  IconData get icon {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('eleave') || titleLower.contains('leave')) {
      return Icons.event_busy_rounded;
    }
    if (titleLower.contains('overtime') || titleLower.contains('ot')) {
      return Icons.access_time_rounded;
    }
    if (titleLower.contains('travel claim') || titleLower.contains('expense')) {
      return Icons.receipt_long_rounded;
    }
    if (titleLower.contains('travel request') || titleLower.contains('travel')) {
      return Icons.flight_takeoff_rounded;
    }
    return Icons.analytics_rounded;
  }

  /// Get color based on title/key
  Color get color {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('eleave') || titleLower.contains('leave')) {
      return Colors.green;
    }
    if (titleLower.contains('overtime') || titleLower.contains('ot')) {
      return Colors.orange;
    }
    if (titleLower.contains('travel claim') || titleLower.contains('expense')) {
      return Colors.purple;
    }
    if (titleLower.contains('travel request') || titleLower.contains('travel')) {
      return Colors.blue;
    }
    return Colors.teal;
  }
}

// ============================================================================
// DEFAULT CHARTS MODELS
// ============================================================================

/// Default chart item from DASHBOARD.DTLS
class DefaultChartItem {
  final String id;
  final String name;

  DefaultChartItem({
    required this.id,
    required this.name,
  });

  factory DefaultChartItem.fromJson(Map<String, dynamic> json) {
    return DefaultChartItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Dashboard config from DASHBOARD.DTLS
class DashboardConfig {
  final String? dashboardId;
  final String? dashboardName;
  final List<DefaultChartItem> defaultCharts;

  DashboardConfig({
    this.dashboardId,
    this.dashboardName,
    required this.defaultCharts,
  });

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final itemDetail = json['itemDetail'] ?? json;
    return DashboardConfig(
      dashboardId: itemDetail['value']?['dashboardId']?.toString(),
      dashboardName: itemDetail['value']?['dashboardName']?.toString(),
      defaultCharts: itemDetail['data'] != null
          ? (itemDetail['data'] as List)
              .map((e) => DefaultChartItem.fromJson(e))
              .toList()
          : [],
    );
  }
}

// ============================================================================
// CHART DETAIL MODELS
// ============================================================================

/// Y-Axis data series
class ChartYAxisData {
  final String label;
  final List<num> data;
  final String? stack;
  final Color? color;

  ChartYAxisData({
    required this.label,
    required this.data,
    this.stack,
    this.color,
  });

  factory ChartYAxisData.fromJson(Map<String, dynamic> json) {
    return ChartYAxisData(
      label: json['label']?.toString() ?? '',
      data: json['data'] != null
          ? (json['data'] as List).map((e) => (e as num?) ?? 0).toList()
          : [],
      stack: json['stack']?.toString(),
    );
  }
}

/// Filter option for chart
class ChartFilterOption {
  final String label;
  final String value;

  ChartFilterOption({
    required this.label,
    required this.value,
  });

  factory ChartFilterOption.fromJson(Map<String, dynamic> json) {
    return ChartFilterOption(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

/// Filter configuration for chart
class ChartFilter {
  final String id;
  final String field;
  final String label;
  final String type;
  final List<ChartFilterOption> options;

  ChartFilter({
    required this.id,
    required this.field,
    required this.label,
    required this.type,
    required this.options,
  });

  factory ChartFilter.fromJson(Map<String, dynamic> json) {
    return ChartFilter(
      id: json['id']?.toString() ?? '',
      field: json['field']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'dropdown',
      options: json['options'] != null
          ? (json['options'] as List)
              .map((e) => ChartFilterOption.fromJson(e))
              .toList()
          : [],
    );
  }

  /// Get default option (first in list)
  ChartFilterOption? get defaultOption => options.isNotEmpty ? options.first : null;
}

/// Chart detail data from CHARTDTLS
class ChartDetailData {
  final String id;
  final String label;
  final String type;
  final String? layout;
  final List<String> xAxis;
  final List<ChartYAxisData> yAxis;
  final String? xAxisUnit;
  final String? yAxisUnit;
  final List<ChartFilter> filters;
  final Map<String, String> filterValues;
  final Map<String, dynamic>? configChart;
  final List<Color>? listColor;

  ChartDetailData({
    required this.id,
    required this.label,
    required this.type,
    this.layout,
    required this.xAxis,
    required this.yAxis,
    this.xAxisUnit,
    this.yAxisUnit,
    required this.filters,
    required this.filterValues,
    this.configChart,
    this.listColor,
  });

  factory ChartDetailData.fromJson(Map<String, dynamic> json) {
    final itemDetail = json['itemDetail'] ?? json;
    final configs = json['configs'] ?? {};
    
    // Parse list colors
    List<Color>? colors;
    if (configs['listColor'] != null && configs['listColor'] is List) {
      colors = (configs['listColor'] as List).map((c) {
        if (c is String && c.startsWith('#')) {
          return Color(int.parse(c.substring(1), radix: 16) + 0xFF000000);
        }
        return Colors.blue;
      }).toList();
    }
    
    return ChartDetailData(
      id: itemDetail['id']?.toString() ?? '',
      label: itemDetail['label']?.toString() ?? '',
      type: itemDetail['type']?.toString() ?? 'bar',
      layout: itemDetail['layout']?.toString(),
      xAxis: itemDetail['xAxis'] != null
          ? (itemDetail['xAxis'] as List).map((e) => e.toString()).toList()
          : [],
      yAxis: itemDetail['yAxis'] != null
          ? (itemDetail['yAxis'] as List)
              .map((e) => ChartYAxisData.fromJson(e))
              .toList()
          : [],
      xAxisUnit: itemDetail['xAxisUnit']?.toString(),
      yAxisUnit: itemDetail['yAxisUnit']?.toString(),
      filters: itemDetail['filter'] != null
          ? (itemDetail['filter'] as List)
              .map((e) => ChartFilter.fromJson(e))
              .toList()
          : [],
      filterValues: itemDetail['filterValues'] != null
          ? Map<String, String>.from(
              (itemDetail['filterValues'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : {},
      configChart: itemDetail['configChart'] as Map<String, dynamic>?,
      listColor: colors,
    );
  }

  /// Get chart type enum
  DashboardChartType get chartType {
    final typeLower = type.toLowerCase();
    if (typeLower.contains('bar')) return DashboardChartType.bar;
    if (typeLower.contains('line')) return DashboardChartType.line;
    if (typeLower.contains('pie')) return DashboardChartType.pie;
    if (typeLower.contains('area')) return DashboardChartType.area;
    return DashboardChartType.bar;
  }

  /// Check if chart is horizontal layout
  bool get isHorizontal => layout?.toLowerCase() == 'horizontal';

  /// Get max Y value for chart scaling
  double get maxYValue {
    double max = 0;
    for (var series in yAxis) {
      for (var value in series.data) {
        if (value > max) max = value.toDouble();
      }
    }
    return max == 0 ? 10 : max * 1.1; // Add 10% padding
  }

  /// Get total values for pie chart
  double get totalValue {
    double total = 0;
    for (var series in yAxis) {
      for (var value in series.data) {
        total += value.toDouble();
      }
    }
    return total;
  }
}

// ============================================================================
// DASHBOARD PAGEDATA RESPONSE
// ============================================================================

/// Full response from DASHBOARD.PAGEDATA
class DashboardPageDataResponse {
  final bool success;
  final ChartConfigsResponse chartConfigs;
  final String? messageType;

  DashboardPageDataResponse({
    required this.success,
    required this.chartConfigs,
    this.messageType,
  });

  factory DashboardPageDataResponse.fromJson(Map<String, dynamic> json) {
    return DashboardPageDataResponse(
      success: json['success'] == true,
      chartConfigs: json['chartConfigs'] != null
          ? ChartConfigsResponse.fromJson(json['chartConfigs'])
          : ChartConfigsResponse(data: []),
      messageType: json['messageType']?.toString(),
    );
  }
}

/// Full response from DASHBOARD.LST
class DashboardListResponse {
  final bool success;
  final List<InboxDataItem> data;
  final InboxDataItem? defaultItem;
  final String? messageType;

  DashboardListResponse({
    required this.success,
    required this.data,
    this.defaultItem,
    this.messageType,
  });

  factory DashboardListResponse.fromJson(Map<String, dynamic> json) {
    return DashboardListResponse(
      success: json['success'] == true,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => InboxDataItem.fromJson(e))
              .toList()
          : [],
      defaultItem: json['value'] != null 
          ? InboxDataItem.fromJson(json['value']) 
          : null,
      messageType: json['messageType']?.toString(),
    );
  }
}
