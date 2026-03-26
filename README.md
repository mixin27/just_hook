# just_hook

A lightweight and simple open-source Flutter hooks framework inspired by `flutter_hooks`.

## Features

Provides building blocks to compose reusable behavior and state logic.

- `useState`: Manages mutable state and rebuilds the widget automatically.
- `useEffect`: Manages side effects related to your widget's lifecycle.
- `useMemoized`: Caches a complex computation, recalculating only if dependencies change.

## Getting started

Add `just_hook` to your `pubspec.yaml`:

```yaml
dependencies:
  just_hook:
    path: ../just_hook  # Or publish it to pub.dev and import the version
```

## Usage

Extend `HookWidget` for your widget to use hooks.
Here's a simple example showing you how to recreate the Flutter Demo Counter using `just_hook`.

```dart
import 'package:flutter/material.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  runApp(const MaterialApp(home: CounterApp()));
}

class CounterApp extends HookWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Manages an integer state
    final counter = useState(0);

    // Fires whenever the widget is built and the 'keys' change
    useEffect(() {
      print('Effect triggered: Counter is now ${counter.value}');
      return () => print('Cleanup triggered before next effect');
    }, [counter.value]);

    return Scaffold(
      appBar: AppBar(title: const Text('just_hook Example')),
      body: Center(
        child: Text('Counter: ${counter.value}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
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
