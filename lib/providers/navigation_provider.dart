// providers/navigation_provider.dart
import 'package:flutter/foundation.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (index != 2) { // Skip camera index
      _currentIndex = index;
      notifyListeners();
    }
  }
}