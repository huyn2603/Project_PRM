class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.jobTitle = 'Freelancer',
    this.bio = '',
    this.avatarUrl = '',
    this.reminderDays = 7,
    this.notifyPayments = true,
    this.notifyProjectUpdates = true,
    this.notifyTeamPayouts = true,
    this.reserveRate = 0.2,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String jobTitle;
  final String bio;
  final String avatarUrl;
  final int reminderDays;
  final bool notifyPayments;
  final bool notifyProjectUpdates;
  final bool notifyTeamPayouts;
  final double reserveRate;

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? (data['fullName'] as String).trim()
          : (data['email'] as String? ?? 'Người dùng'),
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      jobTitle: data['jobTitle'] as String? ?? 'Freelancer',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      reminderDays: (data['reminderDays'] as num?)?.toInt() ?? 7,
      notifyPayments: data['notifyPayments'] as bool? ?? true,
      notifyProjectUpdates: data['notifyProjectUpdates'] as bool? ?? true,
      notifyTeamPayouts: data['notifyTeamPayouts'] as bool? ?? true,
      reserveRate: (data['reserveRate'] as num?)?.toDouble() ?? 0.2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'jobTitle': jobTitle,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'reminderDays': reminderDays,
      'notifyPayments': notifyPayments,
      'notifyProjectUpdates': notifyProjectUpdates,
      'notifyTeamPayouts': notifyTeamPayouts,
      'reserveRate': reserveRate,
    };
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return email[0].toUpperCase();
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? jobTitle,
    String? bio,
    String? avatarUrl,
    int? reminderDays,
    bool? notifyPayments,
    bool? notifyProjectUpdates,
    bool? notifyTeamPayouts,
    double? reserveRate,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      reminderDays: reminderDays ?? this.reminderDays,
      notifyPayments: notifyPayments ?? this.notifyPayments,
      notifyProjectUpdates: notifyProjectUpdates ?? this.notifyProjectUpdates,
      notifyTeamPayouts: notifyTeamPayouts ?? this.notifyTeamPayouts,
      reserveRate: reserveRate ?? this.reserveRate,
    );
  }
}
