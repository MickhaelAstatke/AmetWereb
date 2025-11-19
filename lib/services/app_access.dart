import 'package:flutter/foundation.dart';

class AppAccess {
  const AppAccess._();

  static const String _role =
      String.fromEnvironment('APP_ROLE', defaultValue: 'viewer');

  static bool get canEdit => kDebugMode || _role.toLowerCase() == 'editor';
}
