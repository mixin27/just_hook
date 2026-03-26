import 'package:flutter/widgets.dart';

/// The base class for a Hook.
///
/// [Hook] is a configuration object that defines how a hook should behave.
/// It works similarly to [Widget] in Flutter.
/// Every [Hook] must implement [createState] to return a corresponding [HookState].
abstract class Hook<R> {
  /// Creates a [Hook]. [keys] can be provided to determine when the hook should
  /// trigger lifecycle updates like [HookState.didUpdateHook].
  const Hook({this.keys});

  /// A list of objects that determine if the hook should be updated.
  final List<Object?>? keys;

  /// Creates its corresponding [HookState].
  HookState<R, Hook<R>> createState();
}

/// The state associated with a [Hook].
///
/// [HookState] manages the lifecycle and internal state of a hook.
/// It works similarly to [State] in Flutter.
abstract class HookState<R, T extends Hook<R>> {
  T? _hook;

  /// The current [Hook] configuration.
  T get hook => _hook!;

  BuildContext? _context;

  /// The [BuildContext] of the [HookWidget] currently using this hook.
  BuildContext get context => _context!;

  /// Called when the hook is first created.
  void initHook() {}

  /// Called whenever the [HookWidget] rebuilds with a new [Hook] that has
  /// different keys or if no keys were provided.
  void didUpdateHook(T oldHook) {}

  /// Builds the value returned by the hook.
  /// Called on every rebuild of the [HookWidget].
  R build(BuildContext context);

  /// Called when the [HookWidget] is disposed or when this hook is no longer used.
  void dispose() {}

  /// Triggers a rebuild of the [HookWidget] that uses this hook.
  void setState(VoidCallback fn) {
    fn();
    (context as Element).markNeedsBuild();
  }
}

/// An element that builds a [HookWidget] and manages [HookState] instances.
///
/// This is the internal engine that tracks hook registration order and lifecycles.
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

/// Registers a [Hook] and returns its produced value.
///
/// This function must be called only within the `build` method of a [HookWidget].
/// It handles hook creation, lifecycle management, and state persistence across builds.
R use<R>(Hook<R> hook) {
  final element = HookElement._currentHookElement;
  if (element == null) {
    throw StateError(
        'Hooks can only be called inside the build method of a HookWidget.');
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
    final hookState =
        element._hooks![element._hookIndex] as HookState<R, Hook<R>>;
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
