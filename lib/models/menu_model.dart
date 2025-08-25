class ApplicationPageId {
  final String id;
  final String pageId;
  final String applicationId;
  final String token;

  ApplicationPageId({
    required this.id,
    required this.pageId,
    required this.applicationId,
    required this.token,
  });

  factory ApplicationPageId.fromJson(Map<String, dynamic> json) {
    return ApplicationPageId(
      id: json['id'].toString(),
      pageId: json['pageId'].toString(),
      applicationId: json['applicationId'].toString(),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'applicationId': applicationId,
      'token': token,
    };
  }
}

class MenuModel {
  final String id;
  final String displayName;
  final String applicationId;
  final String parentMenuId;
  final String menuIndex;
  final ApplicationPageId? applicationPageId;
  List<MenuModel> children = [];
  bool isExpanded = false;

  MenuModel({
    required this.id,
    required this.displayName,
    required this.applicationId,
    required this.parentMenuId,
    required this.menuIndex,
    this.applicationPageId,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'].toString(),
      displayName: json['displayName'] ?? '',
      applicationId: json['applicationId'].toString(),
      parentMenuId: json['parentMenuId'].toString(),
      menuIndex: json['menuIndex'].toString(),
      applicationPageId: json['applicationPageId'] != null && json['applicationPageId'] != "-1"
          ? ApplicationPageId.fromJson(json['applicationPageId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'applicationId': applicationId,
      'parentMenuId': parentMenuId,
      'menuIndex': menuIndex,
      'applicationPageId': applicationPageId?.toJson(),
    };
  }

  bool get hasChildren => children.isNotEmpty;
  bool get isParent => parentMenuId == "-1";
}
