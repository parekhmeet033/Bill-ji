import 'package:flutter/material.dart';

enum NavTab { home, items, kitchen, analytics, settings }

class NavigationProvider extends ChangeNotifier {
  NavTab _currentTab = NavTab.home;
  Key _reportsKey = UniqueKey();

  NavTab get currentTab => _currentTab;
  Key get reportsKey => _reportsKey;

  // For backward compatibility with IndexedStack
  int getSelectedIndex(bool isKdsEnabled) {
    final List<NavTab> available = [
      NavTab.home,
      NavTab.items,
      if (isKdsEnabled) NavTab.kitchen,
      NavTab.analytics,
      NavTab.settings,
    ];
    
    final index = available.indexOf(_currentTab);
    return index != -1 ? index : 0;
  }

  void setTab(NavTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void setIndex(int index) {
    // This is now just a safety wrapper or can be deprecated
    // but we'll keep it for UI elements that still send index
  }

  void refreshReports() {
    _reportsKey = UniqueKey();
    notifyListeners();
  }

  void reset() {
    _currentTab = NavTab.home;
    _reportsKey = UniqueKey();
    notifyListeners();
  }

  void ensureValidTab(bool isKdsEnabled) {
    if (_currentTab == NavTab.kitchen && !isKdsEnabled) {
      _currentTab = NavTab.home;
      notifyListeners();
    }
  }
}
