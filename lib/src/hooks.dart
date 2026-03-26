import 'package:flutter/widgets.dart';

import 'framework.dart';

/// A hook that manages a mutable state value.
///
/// It returns a [ValueNotifier] that holds the current value. Any change to
/// [ValueNotifier.value] will automatically trigger a rebuild of the
/// [HookWidget] that uses this hook.
///
/// ```dart
/// final counter = useState(0);
/// return Text('${counter.value}');
/// ```
ValueNotifier<T> useState<T>(T initialData) {
  return use(_StateHook(initialData: initialData));
}

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  const _StateHook({required this.initialData});

  final T initialData;

  @override
  _StateHookState<T> createState() => _StateHookState<T>();
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
  late ValueNotifier<T> _notifier;

  @override
  void initHook() {
    super.initHook();
    _notifier = ValueNotifier<T>(hook.initialData)..addListener(_listener);
  }

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_listener);
    _notifier.dispose();
    super.dispose();
  }

  @override
  ValueNotifier<T> build(BuildContext context) => _notifier;
}

/// A side-effect hook that runs code after layout.
///
/// The [effect] runs on the first build and whenever any value in [keys] changes.
/// If [keys] is null, the effect runs on every build.
/// If [keys] is empty `[]`, the effect runs only once (on mount).
///
/// [effect] can optionally return a cleanup function `void Function()` which
/// will be called when the hook is disposed or before the effect runs again.
///
/// ```dart
/// useEffect(() {
///   print('Mounted');
///   return () => print('Unmounted');
/// }, []);
/// ```
void useEffect(void Function()? Function() effect, [List<Object?>? keys]) {
  use(_EffectHook(effect: effect, keys: keys));
}

class _EffectHook extends Hook<void> {
  const _EffectHook({required this.effect, super.keys});

  final void Function()? Function() effect;

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  void Function()? _disposeEffect;
  bool _isDisposed = false;

  @override
  void initHook() {
    super.initHook();
    _scheduleEffect();
  }

  @override
  void didUpdateHook(_EffectHook oldHook) {
    super.didUpdateHook(oldHook);
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _disposeEffect?.call();
      _scheduleEffect();
    }
  }

  void _scheduleEffect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _disposeEffect = hook.effect();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeEffect?.call();
    super.dispose();
  }

  @override
  void build(BuildContext context) {}
}

/// Caches the result of a complex computation.
///
/// The [valueBuilder] is called on the first build and whenever any value in
/// [keys] changes. Subsequent calls return the cached value.
///
/// ```dart
/// final expensiveValue = useMemoized(() => computeSomething(), [deps]);
/// ```
T useMemoized<T>(T Function() valueBuilder, [List<Object?>? keys]) {
  return use(_MemoizedHook(valueBuilder: valueBuilder, keys: keys));
}

class _MemoizedHook<T> extends Hook<T> {
  const _MemoizedHook({required this.valueBuilder, super.keys});

  final T Function() valueBuilder;

  @override
  _MemoizedHookState<T> createState() => _MemoizedHookState<T>();
}

class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
  late T _value;

  @override
  void initHook() {
    super.initHook();
    _value = hook.valueBuilder();
  }

  @override
  void didUpdateHook(_MemoizedHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.keys != null && HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _value = hook.valueBuilder();
    }
  }

  @override
  T build(BuildContext context) => _value;
}
