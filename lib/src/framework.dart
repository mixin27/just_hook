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

/// A mixin that provides hook functionality to an [Element].
mixin HookElementMixin on Element {
  List<HookState<dynamic, Hook<dynamic>>>? _hooks;
  int _hookIndex = 0;
  bool _isFirstBuild = true;

  /// The internal engine that tracks hook registration order and lifecycles.
  Widget useHookElement(Widget Function(BuildContext context) build) {
    _hookIndex = 0;
    final oldElement = _currentHookElement;
    _currentHookElement = this;
    try {
      final result = build(this);
      _isFirstBuild = false;

      if (_hooks != null && _hookIndex != _hooks!.length) {
        throw StateError(
          'Hooks were added or removed during build. '
          'Hooks must be called in the exact same order on every build.',
        );
      }
      return result;
    } finally {
      _currentHookElement = oldElement;
    }
  }

  /// Disposes all hooks associated with this element.
  void unmountHooks() {
    if (_hooks != null) {
      for (final hookState in _hooks!) {
        hookState.dispose();
      }
    }
  }

  static Element? _currentHookElement;
}

/// An element that builds a [HookWidget] and manages [HookState] instances.
class HookElement extends StatelessElement with HookElementMixin {
  HookElement(HookWidget super.widget);

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  // ignore: invalid_use_of_protected_member
  Widget build() => useHookElement((context) => widget.build(context));

  @override
  void unmount() {
    unmountHooks();
    super.unmount();
  }
}

/// A widget that uses Hooks.
abstract class HookWidget extends StatelessWidget {
  const HookWidget({super.key});

  @override
  StatelessElement createElement() => HookElement(this);
}

/// A widget that builds a [HookWidget] from a builder function.
class HookBuilder extends HookWidget {
  const HookBuilder({super.key, required this.builder});

  /// The builder function that uses hooks.
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

/// A [StatefulWidget] that supports hooks in its build method.
abstract class StatefulHookWidget extends StatefulWidget {
  const StatefulHookWidget({super.key});

  @override
  StatefulHookElement createElement() => StatefulHookElement(this);
}

/// An element for [StatefulHookWidget].
class StatefulHookElement extends StatefulElement with HookElementMixin {
  StatefulHookElement(StatefulHookWidget super.widget);

  @override
  // ignore: invalid_use_of_protected_member
  Widget build() => useHookElement((context) => super.build());

  @override
  void unmount() {
    unmountHooks();
    super.unmount();
  }
}

/// Registers a [Hook] and returns its produced value.
///
/// This function must be called only within the `build` method of a [HookWidget].
/// It handles hook creation, lifecycle management, and state persistence across builds.
R use<R>(Hook<R> hook) {
  final element = HookElementMixin._currentHookElement;
  if (element == null) {
    throw StateError(
      'Hooks can only be called inside the build method of a HookWidget, '
      'HookBuilder, or StatefulHookWidget.',
    );
  }

  final hooksElement = element as HookElementMixin;
  hooksElement._hooks ??= [];

  if (hooksElement._isFirstBuild ||
      hooksElement._hookIndex >= hooksElement._hooks!.length) {
    final hookState = hook.createState();
    hookState._hook = hook;
    hookState._context = element;
    hookState.initHook();

    if (hooksElement._hookIndex >= hooksElement._hooks!.length) {
      hooksElement._hooks!.add(hookState);
    } else {
      hooksElement._hooks![hooksElement._hookIndex] = hookState;
    }
  } else {
    final hookState =
        hooksElement._hooks![hooksElement._hookIndex] as HookState<R, Hook<R>>;
    final oldHook = hookState.hook;
    hookState._hook = hook;

    // We notify if keys change, otherwise some hooks might not need to do update logic
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      hookState.didUpdateHook(oldHook);
    }
  }

  final state =
      hooksElement._hooks![hooksElement._hookIndex] as HookState<R, Hook<R>>;
  hooksElement._hookIndex++;
  return state.build(element);
}

/// A hook that returns the [BuildContext] of the [HookWidget].
///
/// This is useful for building other hooks that need access to the context.
BuildContext useContext() => use(const _ContextHook());

class _ContextHook extends Hook<BuildContext> {
  const _ContextHook();
  @override
  _ContextHookState createState() => _ContextHookState();
}

class _ContextHookState extends HookState<BuildContext, _ContextHook> {
  @override
  BuildContext build(BuildContext context) => context;
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
