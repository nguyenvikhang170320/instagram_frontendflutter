class User {
  final String userId;
  final String username;
  final String fullname;
  final String bio;
  final String avatar;
  final String email;
  final bool isVerified;
  final DateTime? createdAt;

  const User({
    required this.userId,
    required this.username,
    required this.fullname,
    required this.bio,
    required this.avatar,
    required this.email,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.empty() => const User(
    userId: '',
    username: '',
    fullname: '',
    bio: '',
    avatar: '',
    email: '',
    isVerified: false,
    createdAt: null,
  );

  User copyWith({
    String? userId,
    String? username,
    String? fullname,
    String? bio,
    String? avatar,
    String? email,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullname: fullname ?? this.fullname,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullname: (json['fullname'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      isVerified: json['isVerified'] == true,
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fullname': fullname,
      'bio': bio,
      'avatar': avatar,
      'email': email,
      'isVerified': isVerified,
      // xuất DateTime theo ISO (dễ debug). Nếu backend cần Timestamp thì map lại ở backend.
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseCreatedAt(dynamic value) {
    if (value == null) return null;

    // Backend của bạn đôi khi trả string ISO
    if (value is String) {
      return DateTime.tryParse(value);
    }

    // Firestore Timestamp dạng map (seconds/nanoseconds)
    if (value is Map) {
      final seconds = value['seconds'];
      final nanoseconds = value['nanoseconds'] ?? 0;

      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + ((nanoseconds is int) ? (nanoseconds ~/ 1000000) : 0),
          isUtc: false,
        );
      }
      if (seconds is String) {
        final s = int.tryParse(seconds);
        if (s != null) {
          return DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: false);
        }
      }
    }

    return null;
  }
}
