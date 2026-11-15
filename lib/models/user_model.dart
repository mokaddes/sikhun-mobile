class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? studentType;
  final String? educationLevel;
  final String? targetExam;
  final double walletBalance;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.studentType,
    this.educationLevel,
    this.targetExam,
    this.walletBalance = 0.0,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      studentType: json['student_type']?.toString() ?? json['segment']?.toString(),
      educationLevel: json['education_level']?.toString() ?? json['grade_level']?.toString(),
      targetExam: json['target_exam']?.toString(),
      walletBalance: (json['wallet_balance'] != null)
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      avatarUrl: json['avatar']?.toString() ?? json['profile_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'student_type': studentType,
      'education_level': educationLevel,
      'target_exam': targetExam,
      'wallet_balance': walletBalance,
      'avatar': avatarUrl,
    };
  }
}
