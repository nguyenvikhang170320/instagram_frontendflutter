// 1. Class đại diện cho từng Story riêng lẻ (ảnh/video)
class Story {
  final String storyId;
  final String imageUrl;
  final DateTime createdAt;
  final int viewersCount;
  bool isViewed; // Để check xem đã xem chưa (hiển thị viền xám/đỏ)

  Story({
    required this.storyId,
    required this.imageUrl,
    required this.createdAt,
    this.viewersCount = 0,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      storyId: json['storyId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      // 🛠 Fix logic DateTime: Hỗ trợ cả Timestamp Firestore (_seconds) và String ISO
      createdAt: _parseDate(json['createdAt']),
      viewersCount: json['viewersCount'] ?? 0,
      isViewed: json['isViewed'] ?? false,
    );
  }

  // Hàm phụ trợ để parse ngày tháng an toàn
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();

    // Trường hợp 1: Trả về object Timestamp của Firestore (có _seconds)
    if (date is Map && date['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(date['_seconds'] * 1000);
    }

    // Trường hợp 2: Trả về chuỗi String (ISO 8601)
    if (date is String) {
      return DateTime.tryParse(date) ?? DateTime.now();
    }

    return DateTime.now();
  }
}

// 2. Class đại diện cho một Nhóm Story của 1 User (Giống cục tròn trên Instagram)
class StoryGroup {
  final String userId;
  final String username;
  final String avatar;
  final List<Story> stories;

  StoryGroup({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.stories,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    var list = json['stories'] as List? ?? [];
    // Map list json thành list các object Story ở trên
    List<Story> storyList = list.map((i) => Story.fromJson(i)).toList();

    return StoryGroup(
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown',
      avatar: json['avatar'] ?? '', // Nếu null thì trả về rỗng để UI xử lý hiện avatar mặc định
      stories: storyList,
    );
  }
}