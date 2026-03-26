import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'framework.dart';

/// Creates an [AnimationController] that will be disposed automatically.
///
/// The returned [AnimationController] is tied to the [HookWidget] lifecycle.
/// It automatically provides a [TickerProvider] (vsync) from the hook state.
///
/// If [keys] are provided, the controller is recreated whenever [keys] change.
AnimationController useAnimationController({
  Duration? duration,
  Duration? reverseDuration,
  String? debugLabel,
  double initialValue = 0.0,
  double lowerBound = 0.0,
  double upperBound = 1.0,
  AnimationBehavior animationBehavior = AnimationBehavior.normal,
  List<Object?>? keys,
}) {
  return use(_AnimationControllerHook(
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    initialValue: initialValue,
    lowerBound: lowerBound,
    upperBound: upperBound,
    animationBehavior: animationBehavior,
    keys: keys,
  ));
}

class _AnimationControllerHook extends Hook<AnimationController> {
  const _AnimationControllerHook({
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    required this.initialValue,
    required this.lowerBound,
    required this.upperBound,
    required this.animationBehavior,
    super.keys,
  });

  final Duration? duration;
  final Duration? reverseDuration;
  final String? debugLabel;
  final double initialValue;
  final double lowerBound;
  final double upperBound;
  final AnimationBehavior animationBehavior;

  @override
  _AnimationControllerHookState createState() => _AnimationControllerHookState();
}

class _AnimationControllerHookState 
    extends HookState<AnimationController, _AnimationControllerHook> 
    implements TickerProvider {
  late AnimationController _controller;
  Set<Ticker>? _tickers;

  @override
  void initHook() {
    super.initHook();
    _controller = AnimationController(
      vsync: this,
      duration: hook.duration,
      reverseDuration: hook.reverseDuration,
      debugLabel: hook.debugLabel,
      value: hook.initialValue,
      lowerBound: hook.lowerBound,
      upperBound: hook.upperBound,
      animationBehavior: hook.animationBehavior,
    );
  }

  @override
  void didUpdateHook(_AnimationControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.duration != oldHook.duration) {
      _controller.duration = hook.duration;
    }
    if (hook.reverseDuration != oldHook.reverseDuration) {
      _controller.reverseDuration = hook.reverseDuration;
    }
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <Ticker>{};
    final ticker = Ticker(onTick, debugLabel: 'created by just_hook');
    _tickers!.add(ticker);
    return ticker;
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_tickers != null) {
      for (final ticker in _tickers!) {
        ticker.dispose();
      }
    }
    super.dispose();
  }

  @override
  AnimationController build(BuildContext context) => _controller;
}
