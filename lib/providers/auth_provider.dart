import 'package:flutter/foundation.dart';

/// A lightweight authorization provider that exposes whether the current
/// session is allowed to edit lyric content.
class AuthProvider extends ChangeNotifier {
  AuthProvider({bool initialCanEdit = true}) : _canEdit = initialCanEdit;

  bool _canEdit;

  bool get canEdit => _canEdit;

  /// Updates the edit capability. Useful for wiring in a real auth backend
  /// later on or for manually toggling permissions during development.
  void setCanEdit(bool value) {
    if (_canEdit == value) {
      return;
    }
    _canEdit = value;
    notifyListeners();
  }
}
