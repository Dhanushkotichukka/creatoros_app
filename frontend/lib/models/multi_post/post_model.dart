import 'platform_type.dart';
import 'platform_content.dart';

class PostModel {
  final String id;
  final List<String> mediaPaths;
  final Map<PlatformType, PlatformContent> platformData;
  final DateTime? scheduledTime;
  final bool isDraft;
  final bool isPublished;
  final DateTime createdAt;
  final String title;

  PostModel({
    required this.id,
    this.mediaPaths = const [],
    this.platformData = const {},
    this.scheduledTime,
    this.isDraft = true,
    this.isPublished = false,
    required this.createdAt,
    this.title = '',
  });

  PostModel copyWith({
    String? id,
    List<String>? mediaPaths,
    Map<PlatformType, PlatformContent>? platformData,
    DateTime? scheduledTime,
    bool? isDraft,
    bool? isPublished,
    DateTime? createdAt,
    String? title,
  }) {
    return PostModel(
      id: id ?? this.id,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      platformData: platformData ?? this.platformData,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isDraft: isDraft ?? this.isDraft,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
    );
  }
}
