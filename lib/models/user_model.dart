class UserModel {
  final String id;
  final String code;
  final String fullName;
  final String? phone;
  final String? email;
  final String? personalEmail;
  final String? position;
  final String? createdDate;
  final String? managerFullName;
  final List<dynamic> roles;

  UserModel({
    required this.id,
    required this.code,
    required this.fullName,
    this.phone,
    this.email,
    this.personalEmail,
    this.position,
    this.createdDate,
    this.managerFullName,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      personalEmail: json['personalEmail'],
      position: json['position'],
      createdDate: json['createdDate'],
      managerFullName: json['managerFullName'],
      roles: json['roles'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'personalEmail': personalEmail,
      'position': position,
      'createdDate': createdDate,
      'managerFullName': managerFullName,
      'roles': roles,
    };
  }
}
