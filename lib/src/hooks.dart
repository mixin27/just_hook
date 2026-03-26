import 'package:flutter/widgets.dart';

import 'framework.dart';

/// Mutable state hook.
/// It holds a [value] and triggers a widget rebuild when changed.
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
    _notifier = ValueNotifier<T>(hook.initialData)
      ..addListener(_listener);
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

/// A side-effect hook.
/// The [effect] runs on the first build and when [keys] change.
/// It can return a cleanup function.
void useEffect(
  void Function()? Function() effect,
  [List<Object?>? keys]
) {
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

/// Caches a complex computation.
/// Recomputes only when [keys] change.
T useMemoized<T>(
  T Function() valueBuilder,
  [List<Object?>? keys]
) {
  return use(_MemoizedHook(valueBuilder: valueBuilder, keys: keys));
}

class _MemoizedHook<T> extends Hook<T> {
  const _MemoizedHook({
    required this.valueBuilder,
    super.keys,
  });

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
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _value = hook.valueBuilder();
    }
  }

  @override
  T build(BuildContext context) => _value;
}
