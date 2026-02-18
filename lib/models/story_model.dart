class StoryModel {
  final String id;
  final String title;
  final DateTime createdAt;

  /// Для сторис лучше использовать imageUrl (Firestore)
  final String? imageUrl;

  /// Оставляем опционально, если вдруг будут локальные картинки
  final String? assetPath;

  /// Чем выше — тем выше в списке
  final int priority;

  const StoryModel({
    required this.id,
    required this.title,
    required this.createdAt,
    this.imageUrl,
    this.assetPath,
    required this.priority,
  });
}
