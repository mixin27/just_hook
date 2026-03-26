import 'package:flutter/widgets.dart';

/// The base class for a Hook.
abstract class Hook<R> {
  const Hook({this.keys});

  final List<Object?>? keys;

  HookState<R, Hook<R>> createState();
}

/// The state associated with a [Hook].
abstract class HookState<R, T extends Hook<R>> {
  T? _hook;
  T get hook => _hook!;

  BuildContext? _context;
  BuildContext get context => _context!;

  void initHook() {}

  void didUpdateHook(T oldHook) {}

  R build(BuildContext context);

  void dispose() {}

  void setState(VoidCallback fn) {
    fn();
    (context as Element).markNeedsBuild();
  }
}

/// An element that builds a [HookWidget] and manages [HookState] instances.
class HookElement extends StatelessElement {
  HookElement(HookWidget super.widget);

  List<HookState<dynamic, Hook<dynamic>>>? _hooks;
  int _hookIndex = 0;
  bool _isFirstBuild = true;

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  Widget build() {
    _hookIndex = 0;
    HookElement._currentHookElement = this;
    final result = super.build();
    HookElement._currentHookElement = null;
    _isFirstBuild = false;

    if (_hooks != null && _hookIndex != _hooks!.length) {
      throw StateError(
          'Hooks were added or removed during build. '
          'Hooks must be called in the exact same order on every build.',
      );
    }
    return result;
  }

  @override
  void unmount() {
    if (_hooks != null) {
      for (final hookState in _hooks!) {
        hookState.dispose();
      }
    }
    super.unmount();
  }

  static HookElement? _currentHookElement;
}

/// A widget that uses Hooks.
abstract class HookWidget extends StatelessWidget {
  const HookWidget({super.key});

  @override
  StatelessElement createElement() => HookElement(this);
}

/// Registers a hook.
R use<R>(Hook<R> hook) {
  final element = HookElement._currentHookElement;
  if (element == null) {
    throw StateError('Hooks can only be called inside the build method of a HookWidget.');
  }

  element._hooks ??= [];

  if (element._isFirstBuild || element._hookIndex >= element._hooks!.length) {
    final hookState = hook.createState();
    hookState._hook = hook;
    hookState._context = element;
    hookState.initHook();

    if (element._hookIndex >= element._hooks!.length) {
      element._hooks!.add(hookState);
    } else {
      element._hooks![element._hookIndex] = hookState;
    }
  } else {
    final hookState = element._hooks![element._hookIndex] as HookState<R, Hook<R>>;
    final oldHook = hookState.hook;
    hookState._hook = hook;
    
    // We notify if keys change, otherwise some hooks might not need to do update logic
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      hookState.didUpdateHook(oldHook);
    }
  }

  final state = element._hooks![element._hookIndex] as HookState<R, Hook<R>>;
  element._hookIndex++;
  return state.build(element);
}

/// Helper methods for comparing hook keys.
class HookKeys {
  static bool didKeysChange(List<Object?>? oldKeys, List<Object?>? newKeys) {
    if (identical(oldKeys, newKeys)) return false;
    if (oldKeys == null || newKeys == null) return true;
    if (oldKeys.length != newKeys.length) return true;
    for (int i = 0; i < oldKeys.length; i++) {
      if (oldKeys[i] != newKeys[i]) return true;
    }
    return false;
  }
}
