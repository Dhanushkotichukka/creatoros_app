import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/platform_type.dart';
import '../models/platform_content.dart';
import '../services/api_service.dart';

class PostState extends ChangeNotifier {
  PostModel _activePost = PostModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
  );

  PlatformType _selectedPlatform = PlatformType.instagram;
  Set<PlatformType> _connectedPlatforms = {PlatformType.youtube, PlatformType.instagram};

  PostModel get activePost => _activePost;
  PlatformType get selectedPlatform => _selectedPlatform;
  Set<PlatformType> get connectedPlatforms => _connectedPlatforms;

  void setSelectedPlatform(PlatformType platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  void updateContent(PlatformType platform, PlatformContent content) {
    final newPlatformData = Map<PlatformType, PlatformContent>.from(_activePost.platformData);
    newPlatformData[platform] = content;
    _activePost = _activePost.copyWith(platformData: newPlatformData);
    notifyListeners();
  }

  void setMedia(List<String> mediaPaths) {
    _activePost = _activePost.copyWith(mediaPaths: mediaPaths);
    notifyListeners();
  }

  void setScheduledTime(DateTime? time) {
    _activePost = _activePost.copyWith(scheduledTime: time);
    notifyListeners();
  }

  void setTitle(String title) {
    _activePost = _activePost.copyWith(title: title);
    notifyListeners();
  }

  Future<bool> publishNow() async {
    // This old provider method is deprecated as the new Multi-Post hub uses PostProvider
    // Mocking success so we do not trigger model type collision with ApiService
    debugPrint('Publishing Post (Legacy Mock): ${_activePost.title}');
    await Future.delayed(const Duration(milliseconds: 500));
    final success = true;
    if (success) {
      reset();
    }
    return success;
  }

  void reset() {
    _activePost = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }
}
