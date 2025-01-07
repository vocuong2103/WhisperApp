class User {
  final String email;
  final String password;
  final String phoneNumber;
  final String avatar;
  final String status;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;

  User({
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.avatar = 'default_avatar.png',
    this.status = 'offline',
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
  });

  // Tạo đối tượng User từ JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      avatar: json['avatar'] ?? 'default_avatar.png',
      status: json['status'] ?? 'offline',
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      name: json['name'] ?? 'Anonymous',
    );
  }

  // Chuyển đổi đối tượng User thành JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'status': status,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
    };
  }
}