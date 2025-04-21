class Story {
  final String storyId;
  final String imageUrl;
  final DateTime createdAt; // 🛠 Đổi int -> DateTime
  final String userId;
  final String username;
  final String avatar;

  Story({
    required this.storyId,
    required this.imageUrl,
    required this.createdAt,
    required this.userId,
    required this.username,
    required this.avatar,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      storyId: json['storyId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: (json['createdAt'] != null && json['createdAt'] is Map && json['createdAt']['_seconds'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']['_seconds'] * 1000) // ✅ Chuyển Timestamp thành DateTime
          : DateTime.now(), // Nếu null thì dùng thời gian hiện tại
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown',
      avatar: json['avatar'] ?? '',
    );
  }
}
