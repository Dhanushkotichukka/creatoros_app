class PlatformContent {
  String title;
  String description;
  String contentType; // Post, Reel, Story
  String privacyStatus; // public, private, unlisted
  bool madeForKids; // YouTube COPPA compliance
  List<String> hashtags;

  PlatformContent({
    this.title = '',
    this.description = '',
    this.contentType = 'Post',
    this.privacyStatus = 'public',
    this.madeForKids = false,
    this.hashtags = const [],
  });

  PlatformContent copyWith({
    String? title,
    String? description,
    String? contentType,
    String? privacyStatus,
    bool? madeForKids,
    List<String>? hashtags,
  }) {
    return PlatformContent(
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      privacyStatus: privacyStatus ?? this.privacyStatus,
      madeForKids: madeForKids ?? this.madeForKids,
      hashtags: hashtags ?? this.hashtags,
    );
  }
}
