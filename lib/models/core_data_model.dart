class PayloadPagedData {
  final Map<String, dynamic> user;
  final String moduleCode;

  PayloadPagedData({required this.user, required this.moduleCode});

  Map<String, dynamic> toJson() => {
        'user': user,
        'moduleCode': moduleCode,
      };
}

class PayloadListData {
  final Map<String, dynamic> user;
  final String moduleCode;
  final String tabModuleCode;
  final DataSpy dataSpy;
  final int pagination;

  PayloadListData({
    required this.user,
    required this.moduleCode,
    required this.tabModuleCode,
    required this.dataSpy,
    required this.pagination,
  });

  Map<String, dynamic> toJson() => {
        'user': user,
        'moduleCode': moduleCode,
        'tabModuleCode': tabModuleCode,
        'dataSpy': dataSpy.toJson(),
        'pagination': pagination,
      };
}

class DataSpy {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String moduleCode;

  DataSpy({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.moduleCode,
  });

  factory DataSpy.fromJson(Map<String, dynamic> json) => DataSpy(
        id: json['id'],
        code: json['code'],
        name: json['name'],
        description: json['description'],
        moduleCode: json['moduleCode'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'moduleCode': moduleCode,
      };
}

class DataSpies {
  final List<DataSpy> data;
  final DataSpy value;

  DataSpies({required this.data, required this.value});

  factory DataSpies.fromJson(Map<String, dynamic> json) => DataSpies(
        data: (json['data'] as List).map((e) => DataSpy.fromJson(e)).toList(),
        value: DataSpy.fromJson(json['value']),
      );
}

class ConfigListItem {
  final String headers;
  final String content;

  ConfigListItem({required this.headers, required this.content});

  factory ConfigListItem.fromJson(Map<String, dynamic> json) => ConfigListItem(
        headers: json['headers'],
        content: json['content'],
      );

  List<String> get headersList => headers.split(',').map((e) => e.trim()).toList();
  List<String> get contentsList => content.split(',').map((e) => e.trim()).toList();
}

class CoreListResponse {
  final List<dynamic> data;
  final ConfigListItem? configListItem;

  CoreListResponse({required this.data, this.configListItem});

  factory CoreListResponse.fromJson(Map<String, dynamic> json) => CoreListResponse(
        data: json['data'] as List,
        configListItem: json['configListItem'] != null 
            ? ConfigListItem.fromJson(json['configListItem'])
            : null,
      );
}
