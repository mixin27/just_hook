import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'framework.dart';

/// Returns a function that evaluates to true if the component is mounted.
/// Useful for checking mount state after async operations to avoid calling
/// [setState] or performing work on disposed components.
bool Function() useIsMounted() {
  return use(const _IsMountedHook());
}

class _IsMountedHook extends Hook<bool Function()> {
  const _IsMountedHook();
  @override
  _IsMountedHookState createState() => _IsMountedHookState();
}

class _IsMountedHookState extends HookState<bool Function(), _IsMountedHook> {
  bool _isMounted = false;

  @override
  void initHook() {
    super.initHook();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  bool Function() build(BuildContext context) => () => _isMounted;
}

/// Subscribes to a [ValueListenable] and returns its current value.
/// Automatically triggers a rebuild when the value changes.
T useValueListenable<T>(ValueListenable<T> valueListenable) {
  return use(_ValueListenableHook<T>(valueListenable));
}

class _ValueListenableHook<T> extends Hook<T> {
  const _ValueListenableHook(this.valueListenable);
  final ValueListenable<T> valueListenable;

  @override
  _ValueListenableHookState<T> createState() => _ValueListenableHookState<T>();
}

class _ValueListenableHookState<T> extends HookState<T, _ValueListenableHook<T>> {
  @override
  void initHook() {
    super.initHook();
    hook.valueListenable.addListener(_listener);
  }

  @override
  void didUpdateHook(_ValueListenableHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.valueListenable != oldHook.valueListenable) {
      oldHook.valueListenable.removeListener(_listener);
      hook.valueListenable.addListener(_listener);
    }
  }

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    hook.valueListenable.removeListener(_listener);
    super.dispose();
  }

  @override
  T build(BuildContext context) => hook.valueListenable.value;
}

/// Subscribes to a [Listenable] and triggers a rebuild when it notifies.
void useListenable(Listenable? listenable) {
  use(_ListenableHook(listenable));
}

class _ListenableHook extends Hook<void> {
  const _ListenableHook(this.listenable);
  final Listenable? listenable;

  @override
  _ListenableHookState createState() => _ListenableHookState();
}

class _ListenableHookState extends HookState<void, _ListenableHook> {
  @override
  void initHook() {
    super.initHook();
    hook.listenable?.addListener(_listener);
  }

  @override
  void didUpdateHook(_ListenableHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.listenable != oldHook.listenable) {
      oldHook.listenable?.removeListener(_listener);
      hook.listenable?.addListener(_listener);
    }
  }

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    hook.listenable?.removeListener(_listener);
    super.dispose();
  }

  @override
  void build(BuildContext context) {}
}

/// Debounces a value, returning it only after [delay] has passed without updates.
T useDebounced<T>(T value, Duration delay) {
  return use(_DebouncedHook<T>(value, delay));
}

class _DebouncedHook<T> extends Hook<T> {
  const _DebouncedHook(this.value, this.delay);
  final T value;
  final Duration delay;

  @override
  _DebouncedHookState<T> createState() => _DebouncedHookState<T>();
}

class _DebouncedHookState<T> extends HookState<T, _DebouncedHook<T>> {
  late T _debouncedValue;
  Timer? _timer;

  @override
  void initHook() {
    super.initHook();
    _debouncedValue = hook.value;
  }

  @override
  void didUpdateHook(_DebouncedHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.value != oldHook.value || hook.delay != oldHook.delay) {
      _timer?.cancel();
      _timer = Timer(hook.delay, () {
        setState(() {
          _debouncedValue = hook.value;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  T build(BuildContext context) => _debouncedValue;
}
