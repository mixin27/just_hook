import 'dart:async';
import 'package:flutter/widgets.dart';

import 'framework.dart';
import 'hooks.dart';

/// Creates a [TextEditingController] that will be disposed automatically.
/// Changing the [keys] respects hook lifecycle but recreates the controller.
/// Changes to [text] will NOT update the controller on rebuilds, it's just initial.
TextEditingController useTextEditingController({
  String? text,
  List<Object?>? keys,
}) {
  return use(_TextEditingControllerHook(text: text, keys: keys));
}

class _TextEditingControllerHook extends Hook<TextEditingController> {
  const _TextEditingControllerHook({this.text, super.keys});

  final String? text;

  @override
  _TextEditingControllerHookState createState() =>
      _TextEditingControllerHookState();
}

class _TextEditingControllerHookState
    extends HookState<TextEditingController, _TextEditingControllerHook> {
  late TextEditingController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = TextEditingController(text: hook.text);
  }

  @override
  void didUpdateHook(_TextEditingControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _controller.dispose();
      _controller = TextEditingController(text: hook.text);
    }
  }

  @override
  TextEditingController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Subscribes to a [Future] and returns its current state as an [AsyncSnapshot].
/// If [future] changes, it re-subscribes.
AsyncSnapshot<T> useFuture<T>(
  Future<T>? future, {
  T? initialData,
}) {
  return use(_FutureHook<T>(future: future, initialData: initialData));
}

class _FutureHook<T> extends Hook<AsyncSnapshot<T>> {
  const _FutureHook({required this.future, this.initialData});

  final Future<T>? future;
  final T? initialData;

  @override
  _FutureHookState<T> createState() => _FutureHookState<T>();
}

class _FutureHookState<T> extends HookState<AsyncSnapshot<T>, _FutureHook<T>> {
  late AsyncSnapshot<T> _snapshot;
  Object? _activeCallbackIdentity;

  @override
  void initHook() {
    super.initHook();
    _snapshot = hook.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T);
    _subscribe();
  }

  @override
  void didUpdateHook(_FutureHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.future != hook.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
      }
      _subscribe();
    }
  }

  void _subscribe() {
    if (hook.future == null) {
      _snapshot = AsyncSnapshot<T>.withData(
          ConnectionState.none, hook.initialData as T);
      return;
    }

    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;

    _snapshot = hook.initialData == null
        ? AsyncSnapshot<T>.waiting()
        : AsyncSnapshot<T>.withData(ConnectionState.waiting, hook.initialData as T);

    hook.future!.then<void>((T data) {
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
        });
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.done, error, stackTrace);
        });
      }
    });
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) => _snapshot;
}

/// Subscribes to a [Stream] and returns its current state as an [AsyncSnapshot].
/// If [stream] changes, it re-subscribes.
AsyncSnapshot<T> useStream<T>(
  Stream<T>? stream, {
  T? initialData,
}) {
  return use(_StreamHook<T>(stream: stream, initialData: initialData));
}

class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
  const _StreamHook({required this.stream, this.initialData});

  final Stream<T>? stream;
  final T? initialData;

  @override
  _StreamHookState<T> createState() => _StreamHookState<T>();
}

class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _StreamHook<T>> {
  late AsyncSnapshot<T> _snapshot;
  StreamSubscription<T>? _subscription;

  @override
  void initHook() {
    super.initHook();
    _snapshot = hook.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T);
    _subscribe();
  }

  @override
  void didUpdateHook(_StreamHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.stream != hook.stream) {
      if (_subscription != null) {
        _unsubscribe();
      }
      _subscribe();
    }
  }

  void _subscribe() {
    if (hook.stream == null) {
      _snapshot = AsyncSnapshot<T>.withData(
          ConnectionState.none, hook.initialData as T);
      return;
    }

    _snapshot = hook.initialData == null
        ? AsyncSnapshot<T>.waiting()
        : AsyncSnapshot<T>.withData(ConnectionState.waiting, hook.initialData as T);

    _subscription = hook.stream!.listen(
      (T data) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, data);
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.active, error, stackTrace);
        });
      },
      onDone: () {
        setState(() {
          _snapshot = _snapshot.inState(ConnectionState.done);
        });
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) => _snapshot;
}

/// A convenience hook for search state. 
/// It creates a [TextEditingController], attaches a listener, 
/// and returns the current text.
/// It rebuilds the widget whenever the text changes.
class SearchState {
  SearchState({required this.controller, required this.text});
  final TextEditingController controller;
  final String text;
}

SearchState useSearch({String? initialText}) {
  final controller = useTextEditingController(text: initialText);
  // Rebuild whenever the text changes using `useState` and `useEffect`.
  // Wait, `useTextEditingController` doesn't rebuild. 
  final text = useState(controller.text);

  useEffect(() {
    void listener() {
      text.value = controller.text;
    }
    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }, [controller]);

  return SearchState(controller: controller, text: text.value);
}

/// Returns the previous value passed into [usePrevious].
/// On the first build, it returns null.
T? usePrevious<T>(T value) {
  return use(_PreviousHook<T>(value));
}

class _PreviousHook<T> extends Hook<T?> {
  const _PreviousHook(this.value);
  final T value;

  @override
  _PreviousHookState<T> createState() => _PreviousHookState<T>();
}

class _PreviousHookState<T> extends HookState<T?, _PreviousHook<T>> {
  T? _previous;

  @override
  void initHook() {
    super.initHook();
    _previous = null;
  }

  @override
  void didUpdateHook(_PreviousHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    _previous = oldHook.value;
  }

  @override
  T? build(BuildContext context) => _previous;
}

/// Creates a [ScrollController] that is automatically disposed.
ScrollController useScrollController({
  double initialScrollOffset = 0.0,
  bool keepScrollOffset = true,
  String? debugLabel,
  List<Object?>? keys,
}) {
  return use(_ScrollControllerHook(
    initialScrollOffset: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    debugLabel: debugLabel,
    keys: keys,
  ));
}

class _ScrollControllerHook extends Hook<ScrollController> {
  const _ScrollControllerHook({
    required this.initialScrollOffset,
    required this.keepScrollOffset,
    this.debugLabel,
    super.keys,
  });

  final double initialScrollOffset;
  final bool keepScrollOffset;
  final String? debugLabel;

  @override
  _ScrollControllerHookState createState() => _ScrollControllerHookState();
}

class _ScrollControllerHookState extends HookState<ScrollController, _ScrollControllerHook> {
  late ScrollController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = ScrollController(
      initialScrollOffset: hook.initialScrollOffset,
      keepScrollOffset: hook.keepScrollOffset,
      debugLabel: hook.debugLabel,
    );
  }

  @override
  void didUpdateHook(_ScrollControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _controller.dispose();
      _controller = ScrollController(
        initialScrollOffset: hook.initialScrollOffset,
        keepScrollOffset: hook.keepScrollOffset,
        debugLabel: hook.debugLabel,
      );
    }
  }

  @override
  ScrollController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Creates a [PageController] that is automatically disposed.
PageController usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
  List<Object?>? keys,
}) {
  return use(_PageControllerHook(
    initialPage: initialPage,
    keepPage: keepPage,
    viewportFraction: viewportFraction,
    keys: keys,
  ));
}

class _PageControllerHook extends Hook<PageController> {
  const _PageControllerHook({
    required this.initialPage,
    required this.keepPage,
    required this.viewportFraction,
    super.keys,
  });

  final int initialPage;
  final bool keepPage;
  final double viewportFraction;

  @override
  _PageControllerHookState createState() => _PageControllerHookState();
}

class _PageControllerHookState extends HookState<PageController, _PageControllerHook> {
  late PageController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = PageController(
      initialPage: hook.initialPage,
      keepPage: hook.keepPage,
      viewportFraction: hook.viewportFraction,
    );
  }

  @override
  void didUpdateHook(_PageControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _controller.dispose();
      _controller = PageController(
        initialPage: hook.initialPage,
        keepPage: hook.keepPage,
        viewportFraction: hook.viewportFraction,
      );
    }
  }

  @override
  PageController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Creates a [FocusNode] that is automatically disposed.
FocusNode useFocusNode({
  String? debugLabel,
  bool canRequestFocus = true,
  bool skipTraversal = false,
  bool descendantsAreFocusable = true,
  bool descendantsAreTraversable = true,
  List<Object?>? keys,
}) {
  return use(_FocusNodeHook(
    debugLabel: debugLabel,
    canRequestFocus: canRequestFocus,
    skipTraversal: skipTraversal,
    descendantsAreFocusable: descendantsAreFocusable,
    descendantsAreTraversable: descendantsAreTraversable,
    keys: keys,
  ));
}

class _FocusNodeHook extends Hook<FocusNode> {
  const _FocusNodeHook({
    this.debugLabel,
    this.canRequestFocus = true,
    this.skipTraversal = false,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    super.keys,
  });

  final String? debugLabel;
  final bool canRequestFocus;
  final bool skipTraversal;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;

  @override
  _FocusNodeHookState createState() => _FocusNodeHookState();
}

class _FocusNodeHookState extends HookState<FocusNode, _FocusNodeHook> {
  late FocusNode _focusNode;

  @override
  void initHook() {
    super.initHook();
    _focusNode = FocusNode(
      debugLabel: hook.debugLabel,
      canRequestFocus: hook.canRequestFocus,
      skipTraversal: hook.skipTraversal,
      descendantsAreFocusable: hook.descendantsAreFocusable,
      descendantsAreTraversable: hook.descendantsAreTraversable,
    );
  }

  @override
  void didUpdateHook(_FocusNodeHook oldHook) {
    super.didUpdateHook(oldHook);
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _focusNode.dispose();
      _focusNode = FocusNode(
        debugLabel: hook.debugLabel,
        canRequestFocus: hook.canRequestFocus,
        skipTraversal: hook.skipTraversal,
        descendantsAreFocusable: hook.descendantsAreFocusable,
        descendantsAreTraversable: hook.descendantsAreTraversable,
      );
    }
  }

  @override
  FocusNode build(BuildContext context) => _focusNode;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
