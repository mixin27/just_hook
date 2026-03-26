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
