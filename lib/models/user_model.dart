class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? institution;
  final String? role;
  final String type; // ssc | hsc | admission | job | university
  final String? educationLevel;
  final String? targetExam;
  final double walletBalance;
  final String? avatarUrl;
  final String? themeMode;
  final bool leaderboardOptOut;
  final bool emailVerified;
  final bool onboardingCompleted;
  final String? referralCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.institution,
    this.role,
    this.type = 'admission',
    this.educationLevel,
    this.targetExam,
    this.walletBalance = 0.0,
    this.avatarUrl,
    this.themeMode,
    this.leaderboardOptOut = false,
    this.emailVerified = true,
    this.onboardingCompleted = true,
    this.referralCode,
  });

  String get studentType => type;

  /// Only Admission and Job students can access Question Bank for now (mirrors web QuestionBankPracticeController).
  bool get canAccessQuestionBank => type == 'admission' || type == 'job';

  String get typeLabelBn {
    switch (type) {
      case 'admission':
        return 'বিশ্ববিদ্যালয় ভর্তি প্রস্তুতি';
      case 'job':
        return 'বিসিএস ও সরকারি চাকরি প্রস্তুতি';
      case 'hsc':
        return 'উচ্চ মাধ্যমিক (HSC)';
      case 'ssc':
        return 'মাধ্যমিক (SSC)';
      case 'university':
        return 'বিশ্ববিদ্যালয় অ্যাকাডেমিক';
      default:
        return type.toUpperCase();
    }
  }

  String get typeLabelEn {
    switch (type) {
      case 'admission':
        return 'University Admission';
      case 'job':
        return 'BCS & Job Prep';
      case 'hsc':
        return 'Higher Secondary (HSC)';
      case 'ssc':
        return 'Secondary (SSC)';
      case 'university':
        return 'University Academic';
      default:
        return type.toUpperCase();
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['student_type'] ?? json['segment'] ?? 'admission')
        .toString()
        .toLowerCase();

    String? avatar = json['avatar']?.toString() ?? json['profile_photo_url']?.toString();
    if (avatar != null && avatar.isNotEmpty && !avatar.startsWith('http')) {
      final clean = avatar.startsWith('/') ? avatar.substring(1) : avatar;
      avatar = 'https://sikhun.com/${clean.startsWith('storage/') ? clean : 'storage/$clean'}';
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      institution: json['institution']?.toString(),
      role: json['role']?.toString(),
      type: rawType,
      educationLevel: json['education_level']?.toString() ?? json['grade_level']?.toString(),
      targetExam: json['target_exam']?.toString(),
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      avatarUrl: avatar,
      themeMode: json['theme_mode']?.toString(),
      leaderboardOptOut: json['leaderboard_opt_out'] == true || json['leaderboard_opt_out'] == 1,
      emailVerified: json['email_verified_at'] != null,
      onboardingCompleted: json['onboarding_completed_at'] != null,
      referralCode: json['referral_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'institution': institution,
      'role': role,
      'type': type,
      'student_type': type,
      'education_level': educationLevel,
      'target_exam': targetExam,
      'wallet_balance': walletBalance,
      'avatar': avatarUrl,
      'theme_mode': themeMode,
      'leaderboard_opt_out': leaderboardOptOut,
      'referral_code': referralCode,
    };
  }
}
