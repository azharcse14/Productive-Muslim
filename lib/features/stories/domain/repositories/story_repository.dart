import '../../../../core/utils/result.dart';
import '../entities/story.dart';

/// Bundled Quran and hadith stories (JSON assets).
abstract interface class StoryRepository {
  Future<Result<List<Story>>> stories(StoryKind kind);
}
