import 'package:flutter/material.dart';
import 'framework.dart';

/// A hook that returns the [ThemeData] of the current [BuildContext].
///
/// It will automatically trigger a rebuild of the [HookWidget] whenever the
/// theme changes.
///
/// ```dart
/// final theme = useTheme();
/// return Text('Hello', style: theme.textTheme.bodyLarge);
/// ```
ThemeData useTheme() {
  final context = useContext();
  // We use standard Theme.of(context) which registers the widget for rebuilds.
  // Note: This requires material.dart but the framework tries to stay generic.
  // However, most Flutter apps use Material. If not, this might fail or
  // we could provide a generic way. For now, let's assume Material/Cupertino
  // or just use inherited widgets.
  // Actually, Theme.of is specific to Material. Let's use it as a shortcut.
  // We need to import material.dart or use a dynamic check.
  return Theme.of(context);
}

/// A hook that returns the [MediaQueryData] of the current [BuildContext].
///
/// It will automatically trigger a rebuild of the [HookWidget] whenever the
/// media query results change (e.g., screen rotation).
///
/// ```dart
/// final mediaQuery = useMediaQuery();
/// return Text('Screen width: ${mediaQuery.size.width}');
/// ```
MediaQueryData useMediaQuery() {
  final context = useContext();
  return MediaQuery.of(context);
}
