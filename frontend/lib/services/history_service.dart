import 'package:hive_flutter/hive_flutter.dart';

class HistoryService {
  static const String _insightsBoxName = 'insights_history_box';
  static const String _myAiBoxName = 'my_ai_history_box';
  static const String _masterAiBoxName = 'master_ai_history_box';

  static const int _maxHistoryCount = 20;

  static Future<void> init() async {
    await Hive.openBox(_insightsBoxName);
    await Hive.openBox(_myAiBoxName);
    await Hive.openBox(_masterAiBoxName);
  }

  // --- Insights History ---
  static Box get _insightsBox => Hive.box(_insightsBoxName);

  static Future<void> saveInsightHistory(String platform, Map<String, dynamic> data) async {
    final list = _insightsBox.get(platform, defaultValue: <dynamic>[]) as List<dynamic>;
    
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': platform,
      'data': data,
    };
    
    list.insert(0, entry);
    if (list.length > _maxHistoryCount) {
      list.removeLast();
    }
    
    await _insightsBox.put(platform, list);
  }

  static List<dynamic> getInsightHistory(String platform) {
    return _insightsBox.get(platform, defaultValue: <dynamic>[]) as List<dynamic>;
  }

  static Future<void> clearInsightHistory(String platform) async {
    await _insightsBox.delete(platform);
  }

  // --- My AI History ---
  static Box get _myAiBox => Hive.box(_myAiBoxName);

  static Future<void> saveMyAiHistory(String category, List<dynamic> videos, List<dynamic> topics) async {
    final list = _myAiBox.get('history', defaultValue: <dynamic>[]) as List<dynamic>;
    
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'category': category,
      'videos': videos,
      'topics': topics,
    };
    
    list.insert(0, entry);
    if (list.length > _maxHistoryCount) {
      list.removeLast();
    }
    
    await _myAiBox.put('history', list);
  }

  static List<dynamic> getMyAiHistory() {
    return _myAiBox.get('history', defaultValue: <dynamic>[]) as List<dynamic>;
  }

  static Future<void> clearMyAiHistory() async {
    await _myAiBox.delete('history');
  }

  // --- Master AI History ---
  static Box get _masterAiBox => Hive.box(_masterAiBoxName);

  static Future<void> saveMasterAiHistory(String platform, Map<String, dynamic> analysisResult) async {
    final list = _masterAiBox.get(platform, defaultValue: <dynamic>[]) as List<dynamic>;
    
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': platform,
      'analysisResult': analysisResult,
    };
    
    list.insert(0, entry);
    if (list.length > _maxHistoryCount) {
      list.removeLast();
    }
    
    await _masterAiBox.put(platform, list);
  }

  static List<dynamic> getMasterAiHistory(String platform) {
    return _masterAiBox.get(platform, defaultValue: <dynamic>[]) as List<dynamic>;
  }

  static Future<void> clearMasterAiHistory(String platform) async {
    await _masterAiBox.delete(platform);
  }
}
