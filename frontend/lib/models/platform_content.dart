class PlatformContent {
  final String title;
  final String description;
  final List<String> hashtags;
  final String contentType; // 'Post', 'Reel', 'Story'

  PlatformContent({
    this.title = '',
    this.description = '',
    this.hashtags = const [],
    this.contentType = 'Post',
  });

  PlatformContent copyWith({
    String? title,
    String? description,
    List<String>? hashtags,
    String? contentType,
  }) {
    return PlatformContent(
      title: title ?? this.title,
      description: description ?? this.description,
      hashtags: hashtags ?? this.hashtags,
      contentType: contentType ?? this.contentType,
    );
  }
}
