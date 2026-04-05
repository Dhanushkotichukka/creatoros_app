import 'package:flutter/material.dart';

class ViewStateProvider extends ChangeNotifier {
  bool _showConnectView = false;
  int _homeResetTrigger = 0;

  bool get showConnectView => _showConnectView;
  int get homeResetTrigger => _homeResetTrigger;

  void setShowConnectView(bool value) {
    if (_showConnectView != value) {
      _showConnectView = value;
      notifyListeners();
    }
  }

  void resetHome() {
    _showConnectView = false;
    _homeResetTrigger++;
    notifyListeners();
  }
}
