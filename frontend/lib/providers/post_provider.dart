import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/multi_post/post_model.dart';
import '../models/multi_post/platform_type.dart';
import '../models/multi_post/platform_content.dart';
import '../services/api_service.dart';

class PostProvider extends ChangeNotifier {
  PostModel _activePost;
  PlatformType _selectedPlatform = PlatformType.instagram;
  Set<PlatformType> _connectedPlatforms = {};
  Set<PlatformType> _targetPlatforms = {};

  PostProvider({Set<PlatformType>? initialPlatforms, String? initialMedia}) : _activePost = PostModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
  ) {
    if (initialPlatforms != null) {
      _connectedPlatforms = initialPlatforms;
      _targetPlatforms = Set<PlatformType>.from(_connectedPlatforms);
      if (_connectedPlatforms.isNotEmpty) {
        _selectedPlatform = _connectedPlatforms.first;
      }
      _loadTargetPreferences();
    }
    if (initialMedia != null) {
      _activePost = _activePost.copyWith(mediaPaths: [initialMedia]);
    }
  }

  PostModel get activePost => _activePost;
  PlatformType get selectedPlatform => _selectedPlatform;
  Set<PlatformType> get connectedPlatforms => _connectedPlatforms;
  Set<PlatformType> get targetPlatforms => _targetPlatforms;

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
    // Only keep platformData for targetPlatforms
    final Map<PlatformType, PlatformContent> filteredData = {};
    for (var platform in _targetPlatforms) {
      filteredData[platform] = _activePost.platformData[platform] ?? PlatformContent();
    }
    
    _activePost = _activePost.copyWith(
      platformData: filteredData,
      isDraft: false, 
      isPublished: true
    );
    
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
    final Map<PlatformType, PlatformContent> filteredData = {};
    for (var platform in _targetPlatforms) {
      filteredData[platform] = _activePost.platformData[platform] ?? PlatformContent();
    }

    _activePost = _activePost.copyWith(
      platformData: filteredData,
      isDraft: false, 
      isPublished: false
    );
    
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
    await Future.delayed(const Duration(milliseconds: 500));
    reset();
  }

  // Selected/Target platform methods
  void setSelectedPlatform(PlatformType platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  void toggleTargetPlatform(PlatformType platform) {
    if (_targetPlatforms.contains(platform)) {
      _targetPlatforms.remove(platform);
    } else {
      _targetPlatforms.add(platform);
      _selectedPlatform = platform;
    }
    _saveTargetPreferences();
    notifyListeners();
  }

  // Connected platform methods
  void connectPlatform(PlatformType platform) {
    _connectedPlatforms.add(platform);
    if (!_targetPlatforms.contains(platform)) {
      _targetPlatforms.add(platform);
    }
    notifyListeners();
  }

  void disconnectPlatform(PlatformType platform) {
    _connectedPlatforms.remove(platform);
    _targetPlatforms.remove(platform);
    notifyListeners();
  }

  // Persistence helpers
  Future<void> _loadTargetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('target_platforms');
      if (saved != null && saved.isNotEmpty) {
        final loaded = <PlatformType>{};
        for (var name in saved) {
          try {
            final type = PlatformType.values.firstWhere((e) => e.name == name);
            if (_connectedPlatforms.contains(type)) loaded.add(type);
          } catch (_) {}
        }
        if (loaded.isNotEmpty) {
          _targetPlatforms = loaded;
          _selectedPlatform = _targetPlatforms.first;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _saveTargetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('target_platforms', _targetPlatforms.map((e) => e.name).toList());
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }
}
