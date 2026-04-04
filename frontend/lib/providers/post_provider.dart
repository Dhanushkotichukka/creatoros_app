import 'package:flutter/material.dart';
import '../models/multi_post/post_model.dart';
import '../models/multi_post/platform_type.dart';
import '../models/multi_post/platform_content.dart';
import '../services/api_service.dart';

class PostProvider extends ChangeNotifier {
  PostModel _activePost;
  PlatformType _selectedPlatform = PlatformType.instagram;
  Set<PlatformType> _connectedPlatforms = {};

  PostProvider({Set<PlatformType>? initialPlatforms}) : _activePost = PostModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
  ) {
    if (initialPlatforms != null) {
      _connectedPlatforms = initialPlatforms;
      if (_connectedPlatforms.isNotEmpty) {
        _selectedPlatform = _connectedPlatforms.first;
      }
    }
  }

  PostModel get activePost => _activePost;
  PlatformType get selectedPlatform => _selectedPlatform;
  Set<PlatformType> get connectedPlatforms => _connectedPlatforms;

  // Active Post methods
  void loadPost(PostModel post) {
    _activePost = post;
    notifyListeners();
  }

  void reset() {
    _activePost = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void updateContent(PlatformType platform, PlatformContent content) {
    var newPlatformData = Map<PlatformType, PlatformContent>.from(_activePost.platformData);
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

  Future<void> publishNow() async {
    _activePost = _activePost.copyWith(isDraft: false, isPublished: true);
    
    final success = await ApiService.publishPost(_activePost);
    
    if (success) {
      reset();
    } else {
      _activePost = _activePost.copyWith(isDraft: true, isPublished: false);
      notifyListeners();
      throw Exception('Failed to publish post');
    }
  }

  Future<void> schedulePost() async {
    _activePost = _activePost.copyWith(isDraft: false, isPublished: false);
    
    final success = await ApiService.publishPost(_activePost);
    
    if (success) {
      reset();
    } else {
      _activePost = _activePost.copyWith(scheduledTime: null);
      notifyListeners();
      throw Exception('Failed to schedule post');
    }
  }

  Future<void> saveAsDraft() async {
    _activePost = _activePost.copyWith(isDraft: true, isPublished: false);
    // Simulate save logic
    await Future.delayed(const Duration(milliseconds: 500));
    reset();
  }

  // Selected platform methods
  void setSelectedPlatform(PlatformType platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  // Connected platform methods
  void connectPlatform(PlatformType platform) {
    _connectedPlatforms.add(platform);
    notifyListeners();
  }

  void disconnectPlatform(PlatformType platform) {
    _connectedPlatforms.remove(platform);
    notifyListeners();
  }
}
