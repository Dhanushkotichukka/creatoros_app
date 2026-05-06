import 'package:flutter/material.dart';

class ViewStateProvider extends ChangeNotifier {
  bool _showConnectView = false;
  int _homeResetTrigger = 0;
  int _selectedTab = 0;
  String _analyticsPlatform = 'Overview';
  String? _pinnedPlatform;

  bool get showConnectView => _showConnectView;
  int get homeResetTrigger => _homeResetTrigger;
  int get selectedTab => _selectedTab;
  String get analyticsPlatform => _analyticsPlatform;
  String? get pinnedPlatform => _pinnedPlatform;

  void setShowConnectView(bool value) {
    if (_showConnectView != value) {
      _showConnectView = value;
      notifyListeners();
    }
  }

  void setSelectedTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  void setAnalyticsPlatform(String platform) {
    _analyticsPlatform = platform;
    notifyListeners();
  }

  void jumpToAnalytics(String platform) {
    _analyticsPlatform = platform;
    _selectedTab = 1; // Analytics tab
    notifyListeners();
  }

  void setPinnedPlatform(String? platform) {
    _pinnedPlatform = platform;
    notifyListeners();
  }

  void resetHome() {
    _showConnectView = false;
    _homeResetTrigger++;
    notifyListeners();
  }
}
