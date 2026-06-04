class InstagramReel {
  final String id;
  final String thumbnailUrl;
  final String? videoUrl;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final DateTime publishDate;
  final String? permalink;
  final int? viewCount;

  InstagramReel({
    required this.id,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.publishDate,
    this.permalink,
    this.viewCount,
  });

  factory InstagramReel.fromMap(Map<String, dynamic> map) {
    return InstagramReel(
      id: map['id'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      videoUrl: map['videoUrl'],
      caption: map['caption'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      publishDate: map['publishDate'] != null 
          ? DateTime.parse(map['publishDate']) 
          : DateTime.now(),
      permalink: map['permalink'],
      viewCount: map['viewCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'caption': caption,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'publishDate': publishDate.toIso8601String(),
      'permalink': permalink,
      'viewCount': viewCount,
    };
  }
}
