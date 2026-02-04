/// Dashboard Models
/// Data models for Dashboard module with Chart support

import 'dart:math';

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

  ChartTypeInfo({required this.id, required this.name});

  factory ChartTypeInfo.fromJson(Map<String, dynamic> json) {
    return ChartTypeInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

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
enum DashboardChartType { bar, line, pie, area }

// ============================================================================
// CHART CONFIGS RESPONSE
// ============================================================================

/// Response for chartConfigs from PAGEDATA
class ChartConfigsResponse {
  final List<ChartConfigItem> data;
  final ChartConfigItem? value;

  ChartConfigsResponse({required this.data, this.value});

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
    if (titleLower.contains('travel request') ||
        titleLower.contains('travel')) {
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
    if (titleLower.contains('travel request') ||
        titleLower.contains('travel')) {
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

  DefaultChartItem({required this.id, required this.name});

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

  ChartFilterOption({required this.label, required this.value});

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
  ChartFilterOption? get defaultOption =>
      options.isNotEmpty ? options.first : null;
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
    // Pie/Donut charts - check multiple patterns
    if (typeLower.contains('pie') ||
        typeLower.contains('donut') ||
        typeLower.contains('doughnut') ||
        typeLower.contains('ring') ||
        typeLower.contains('circle') ||
        typeLower.contains('round')) {
      return DashboardChartType.pie;
    }
    if (typeLower.contains('line')) return DashboardChartType.line;
    if (typeLower.contains('area')) return DashboardChartType.area;
    if (typeLower.contains('bar')) return DashboardChartType.bar;
    return DashboardChartType.bar;
  }

  /// Check if chart is horizontal layout
  bool get isHorizontal => layout?.toLowerCase() == 'horizontal';

  /// Check if chart is stacked layout
  bool get isStacked => layout?.toLowerCase() == 'stacked';

  /// Get unique stack groups from yAxis
  /// Returns a map of stackName -> list of series indices
  Map<String, List<int>> get stackGroups {
    final Map<String, List<int>> groups = {};
    for (int i = 0; i < yAxis.length; i++) {
      final stackName = yAxis[i].stack ?? 'default';
      groups.putIfAbsent(stackName, () => []).add(i);
    }
    return groups;
  }

  /// Get the raw max value from data
  double get _rawMaxValue {
    double max = 0;

    if (isStacked) {
      // For stacked charts, calculate max per stack group
      final groups = stackGroups;
      for (int xIndex = 0; xIndex < xAxis.length; xIndex++) {
        for (var stackName in groups.keys) {
          final seriesIndices = groups[stackName]!;
          double stackTotal = 0;
          for (var seriesIndex in seriesIndices) {
            if (seriesIndex < yAxis.length &&
                xIndex < yAxis[seriesIndex].data.length) {
              stackTotal += yAxis[seriesIndex].data[xIndex].toDouble();
            }
          }
          if (stackTotal > max) max = stackTotal;
        }
      }
    } else {
      // For grouped charts, find individual max
      for (var series in yAxis) {
        for (var value in series.data) {
          if (value > max) max = value.toDouble();
        }
      }
    }
    return max;
  }

  /// Calculate nice max Y value and interval for chart scaling
  /// Uses "nice numbers" algorithm like MUIx Chart for professional appearance
  (double maxY, double interval) get yAxisConfig {
    final rawMax = _rawMaxValue;
    if (rawMax == 0) return (10.0, 2.0);

    // Calculate nice step size for approximately 5-6 divisions
    final roughStep = rawMax / 5;
    final magnitude = _magnitude(roughStep);
    final niceStep = _niceNumber(roughStep, magnitude);

    // Calculate nice max value
    final niceMax = (rawMax / niceStep).ceil() * niceStep;

    return (niceMax.toDouble(), niceStep.toDouble());
  }

  /// Get magnitude of a number (power of 10)
  double _magnitude(double value) {
    if (value == 0) return 1;
    return pow(10, (log(value.abs()) / ln10).floor()).toDouble();
  }

  /// Round to nice number (1, 2, 5, 10, etc.)
  double _niceNumber(double value, double magnitude) {
    final normalized = value / magnitude;
    if (normalized <= 1) return magnitude;
    if (normalized <= 2) return 2 * magnitude;
    if (normalized <= 5) return 5 * magnitude;
    return 10 * magnitude;
  }

  /// Get max Y value for chart scaling (nice number)
  double get maxYValue => yAxisConfig.$1;

  /// Get Y axis interval for grid lines (nice number)
  double get yAxisInterval => yAxisConfig.$2;

  /// Get valueFormatter from configChart if available
  /// Checks configChart.yAxis.valueFormatter first, then root valueFormatter
  String? get valueFormatter {
    // Check yAxis config first (for Y axis formatting)
    final yAxisConfig = configChart?['yAxis'];
    if (yAxisConfig != null && yAxisConfig is Map) {
      final yAxisFormatter = yAxisConfig['valueFormatter']?.toString();
      if (yAxisFormatter != null && yAxisFormatter.isNotEmpty) {
        return yAxisFormatter;
      }
    }
    // Fallback to root valueFormatter
    return configChart?['valueFormatter']?.toString();
  }

  /// Get xAxis valueFormatter from configChart if available
  /// Checks configChart.xAxis.valueFormatter first, then root valueFormatter
  String? get xAxisValueFormatter {
    // Check xAxis config first (for X axis formatting)
    final xAxisConfig = configChart?['xAxis'];
    if (xAxisConfig != null && xAxisConfig is Map) {
      final xAxisFormatter = xAxisConfig['valueFormatter']?.toString();
      if (xAxisFormatter != null && xAxisFormatter.isNotEmpty) {
        return xAxisFormatter;
      }
    }
    // Fallback to root valueFormatter
    return configChart?['valueFormatter']?.toString();
  }

  /// Get formatted Y axis value
  /// Supports JS-like valueFormatter from MUIx Chart config
  String formatYAxisValue(double value) {
    final formatter = valueFormatter;
    if (formatter != null && formatter.isNotEmpty) {
      // Parse simple formatter patterns like "(number) => number + ' day'"
      return _applyFormatter(value, formatter);
    }

    // Default formatting
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Get formatted X axis value (for horizontal charts)
  /// Supports JS-like valueFormatter from MUIx Chart config
  String formatXAxisValue(double value) {
    final formatter = xAxisValueFormatter;
    if (formatter != null && formatter.isNotEmpty) {
      // Parse simple formatter patterns like "(number) => number + ' day'"
      return _applyFormatter(value, formatter);
    }

    // Default formatting
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Apply formatter pattern to value
  String _applyFormatter(double value, String formatter) {
    // Handle common MUIx formatter patterns:
    // "(number) => Number(number.toFixed(2)) + ' day'"
    // "(number) => number + '%'"
    // "new Intl.NumberFormat('en-US',{notation:'compact'}).format"
    // etc.

    try {
      // Check for Intl.NumberFormat with compact notation
      if (formatter.contains('notation') && formatter.contains('compact')) {
        return _formatCompactNumber(value);
      }

      // Check for suffix pattern: + ' something' or + " something"
      final suffixRegex = RegExp(r"""\+\s*['"]([^'"]+)['"]""");
      final suffixMatch = suffixRegex.firstMatch(formatter);
      final suffix = suffixMatch?.group(1) ?? '';

      // Check for toFixed pattern
      final toFixedRegex = RegExp(r'toFixed\((\d+)\)');
      final toFixedMatch = toFixedRegex.firstMatch(formatter);
      final decimalPlaces = int.tryParse(toFixedMatch?.group(1) ?? '') ?? 0;

      // Format the value
      String formatted;
      if (decimalPlaces > 0) {
        formatted = value.toStringAsFixed(decimalPlaces);
        // Remove trailing zeros
        formatted = double.parse(formatted).toString();
        if (formatted.endsWith('.0')) {
          formatted = formatted.substring(0, formatted.length - 2);
        }
      } else if (value == value.toInt()) {
        formatted = value.toInt().toString();
      } else {
        formatted = value.toStringAsFixed(1);
      }

      return '$formatted$suffix';
    } catch (_) {
      // Fallback to default formatting
      if (value == value.toInt()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }
  }

  /// Format number in compact notation (like Intl.NumberFormat with notation:'compact')
  /// Examples: 1000 -> 1K, 1000000 -> 1M, 1000000000 -> 1B
  String _formatCompactNumber(double value) {
    if (value == 0) return '0';

    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';

    String formatted;
    if (absValue >= 1e9) {
      formatted =
          '${(absValue / 1e9).toStringAsFixed(absValue % 1e9 == 0 ? 0 : 1)}B';
    } else if (absValue >= 1e6) {
      formatted =
          '${(absValue / 1e6).toStringAsFixed(absValue % 1e6 == 0 ? 0 : 1)}M';
    } else if (absValue >= 1e3) {
      formatted =
          '${(absValue / 1e3).toStringAsFixed(absValue % 1e3 == 0 ? 0 : 1)}K';
    } else {
      formatted = absValue == absValue.toInt()
          ? absValue.toInt().toString()
          : absValue.toStringAsFixed(1);
    }

    // Remove unnecessary .0
    formatted = formatted
        .replaceAll('.0K', 'K')
        .replaceAll('.0M', 'M')
        .replaceAll('.0B', 'B');

    return '$sign$formatted';
  }

  /// Get formatted tooltip value
  /// Shows full value with thousand separators and currency suffix
  /// Does NOT round - shows exact value with decimals if present
  String formatTooltipValue(double value) {
    final formatter = valueFormatter;
    
    // Format with thousand separators (using dots like Vietnamese format)
    // Keep decimals if present, don't round
    String formatted = _formatDoubleWithThousandSeparator(value);
    
    // Extract currency/suffix from formatter if available
    String suffix = '';
    if (formatter != null) {
      // Check for currency patterns like 'VND', 'USD', etc.
      final currencyRegex = RegExp(r"['\x22]([A-Z]{3})['\x22]|currency:\s*['\x22]([A-Z]{3})['\x22]");
      final currencyMatch = currencyRegex.firstMatch(formatter);
      if (currencyMatch != null) {
        suffix = ' ${currencyMatch.group(1) ?? currencyMatch.group(2) ?? ''}';
      } else {
        // Check for suffix pattern: + ' something' or + " something"
        final suffixRegex = RegExp(r"\+\s*['\x22]([^'\x22]+)['\x22]");
        final suffixMatch = suffixRegex.firstMatch(formatter);
        if (suffixMatch != null) {
          suffix = ' ${suffixMatch.group(1) ?? ''}';
        }
      }
    }
    
    return '$formatted$suffix';
  }
  
  /// Format double with thousand separator, preserving decimals
  String _formatDoubleWithThousandSeparator(double value) {
    // Check if value has decimal part
    if (value == value.toInt()) {
      return _formatWithThousandSeparator(value.toInt());
    }
    
    // Split into integer and decimal parts
    final parts = value.toString().split('.');
    final intPart = int.parse(parts[0]);
    final decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Format integer part with separators
    final formattedInt = _formatWithThousandSeparator(intPart.abs());
    final sign = intPart < 0 ? '-' : '';
    
    // Combine with decimal (limit to 2 decimal places for display)
    if (decimalPart.isNotEmpty) {
      final truncatedDecimal = decimalPart.length > 2 ? decimalPart.substring(0, 2) : decimalPart;
      // Remove trailing zeros
      final cleanDecimal = truncatedDecimal.replaceAll(RegExp(r'0+$'), '');
      if (cleanDecimal.isNotEmpty) {
        return '$sign$formattedInt,$cleanDecimal';
      }
    }
    return '$sign$formattedInt';
  }
  
  /// Format number with thousand separator (dot)
  String _formatWithThousandSeparator(int value) {
    final str = value.abs().toString();
    final buffer = StringBuffer();
    int count = 0;
    
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
      count++;
    }
    
    final result = buffer.toString().split('').reversed.join();
    return value < 0 ? '-$result' : result;
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
