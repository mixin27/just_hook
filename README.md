# just_hook

A lightweight and simple open-source Flutter hooks framework inspired by `flutter_hooks`.

## Features

Provides building blocks to compose reusable behavior and state logic.

### Standard Hooks

- `useState`: Manages mutable state and rebuilds the widget automatically.
- `useEffect`: Manages side effects related to your widget's lifecycle.
- `useMemoized`: Caches a complex computation, recalculating only if dependencies change.

### Advanced Hooks

- `useFuture`: Subscribes to a `Future` and returns the `AsyncSnapshot` state.
- `useStream`: Subscribes to a `Stream` and returns the `AsyncSnapshot` state.
- `useTextEditingController`: Creates an automatically disposable `TextEditingController`.
- `useSearch`: Easily builds a text editing controller and text state listener for building search UIs.

### Controller & Utility Hooks

- `usePrevious`: Returns the previous value given to it, useful for comparing previous vs new state.
- `useScrollController`: Creates an automatically disposable `ScrollController`.
- `usePageController`: Creates an automatically disposable `PageController`.
- `useFocusNode`: Creates an automatically disposable `FocusNode`.
- `useIsMounted`: Returns a function evaluated to true if the widget is currently mounted.
- `useValueListenable`: Subscribes to a `ValueListenable` automatically triggering rebuilds.
- `useListenable`: Subscribes to a `Listenable` maintaining proper disposal/listener attachments.
- `useDebounced`: Returns a debounced version of a value to avoid rapid continuous rebuilds or side-effects.

### Domain-Specific Hooks

- `usePagination`: Easily handle typical infinite-scrolling scenarios. Manages data fetching, appending, refresh, and loading states automatically.
- `useForm`: A robust, uncontrolled form controller pattern for reactive form state handling and validation without heavy internal boilerplate. Easily registers form fields, controls submission loading, and automatically renders validation errors.
- `useAnimationController`: Creates an `AnimationController` seamlessly. Automatically provides a `TickerProvider` to the hook behind the scenes, mimicking the natural Flutter `vsync` requirement without needing Stateful widget mixins.
- `useQuery`: An advanced, React-Query influenced hook designed exclusively for fetching HTTP REST API logic. Completely tracks cache states like `isLoading`, `isFetching`, `data`, `error` and explicit `refetch()` commands globally.
- `useMutation`: The counterpart to `useQuery`, designed to handle POST/PUT updates natively exposing an `isMutating` state. Provides `onSuccess`, `onError`, and `onMutate` bindings automatically!
- `useSubscription`: Tailored heavily toward bidirectional flows like WebSockets and GraphQL subscriptions. Automatically exposes the identical cache structures to queries but updates continuously via a native Dart `Stream` backing.

## Getting started

Add `just_hook` to your `pubspec.yaml`:

```yaml
dependencies:
  just_hook: latest
```

## Usage

Extend `HookWidget` for your widget to use hooks.
Here's an example combining multiple hooks (`useSearch` and `useFuture`):

```dart
import 'package:flutter/material.dart';
import 'package:just_hook/just_hook.dart';

class MyHookPage extends HookWidget {
  const MyHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic state hook
    final counter = useState(0);

    // Advanced search hook automatically gives controller and string text
    final search = useSearch(initialText: 'Hooked Search');

    // Mocks a stream ticking every second
    final stream = useMemoized(() {
      return Stream<int>.periodic(const Duration(seconds: 1), (i) => i).take(10);
    }, []);
    final streamSnapshot = useStream(stream);

    // Mocks a future responding
    final future = useMemoized(() {
      return Future.delayed(const Duration(seconds: 2), () => 'Data Loaded!');
    }, [counter.value]); // the future reloads when the counter increases
    final futureSnapshot = useFuture(future);

    return Scaffold(
      appBar: AppBar(title: const Text('just_hook Examples')),
      body: Center(
        child: Column(
          children: [
            TextField(controller: search.controller),
            Text('You typed: ${search.text}'),

            Text('Stream Ticks: ${streamSnapshot.hasData ? streamSnapshot.data : "..."}'),
            Text('Future Status: ${futureSnapshot.connectionState.name}')
          ],
        ),
      ),
    );
  }
}
```

## How to create your own hook

Hooks are objects that implement the `Hook` config and `HookState` behavior. Ensure you call `use` internally to register it to the current widget.

```dart
import 'package:just_hook/just_hook.dart';

int useMyHook() {
  return use(const _MyHook());
}

class _MyHook extends Hook<int> {
  const _MyHook();
  @override
  _MyHookState createState() => _MyHookState();
}

class _MyHookState extends HookState<int, _MyHook> {
  @override
  int build(BuildContext context) {
    return 42;
  }
}
```
