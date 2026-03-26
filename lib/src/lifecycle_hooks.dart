import 'package:flutter/widgets.dart';
import 'framework.dart';

/// A hook that returns the current [AppLifecycleState].
///
/// It will automatically trigger a rebuild of the [HookWidget] whenever the
/// app lifecycle state changes (e.g., backgrounded, resumed).
///
/// ```dart
/// final state = useAppLifecycleState();
/// print('Current app state: $state');
/// ```
AppLifecycleState useAppLifecycleState() {
  return use(const _AppLifecycleStateHook());
}

class _AppLifecycleStateHook extends Hook<AppLifecycleState> {
  const _AppLifecycleStateHook();
  @override
  _AppLifecycleStateHookState createState() => _AppLifecycleStateHookState();
}

class _AppLifecycleStateHookState
    extends HookState<AppLifecycleState, _AppLifecycleStateHook>
    with WidgetsBindingObserver {
  late AppLifecycleState _state;

  @override
  void initHook() {
    super.initHook();
    _state =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _state = state;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  AppLifecycleState build(BuildContext context) => _state;
}
