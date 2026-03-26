import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHookPage(),
    );
  }
}

class MyHookPage extends HookWidget {
  const MyHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);

    // Advanced search hook automatically gives controller and string text
    final search = useSearch(initialText: 'Hooked Search');

    // Controller hooks
    final focusNode = useFocusNode();
    final scrollController = useScrollController();

    // Mocks a stream ticking every second
    final stream = useMemoized(() {
      return Stream<int>.periodic(const Duration(seconds: 1), (i) => i)
          .take(10);
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
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('useSearch & useFocusNode Example:',
                  style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: search.controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Type something...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => focusNode.requestFocus(),
                    child: const Text('Focus'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('You typed: ${search.text}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 48),
              Text('useStream Example:',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                  'Ticks: ${streamSnapshot.hasData ? streamSnapshot.data : "Waiting..."}'),
              const Divider(height: 48),
              Text('useFuture Example (Refreshes on Fab Tap):',
                  style: Theme.of(context).textTheme.titleLarge),
              if (futureSnapshot.connectionState == ConnectionState.waiting)
                const CircularProgressIndicator()
              else if (futureSnapshot.hasData)
                Text('Result: ${futureSnapshot.data}')
              else
                const Text('Waiting...'),
              const Divider(height: 48),
              Text('useState Example:',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('Button taps: ${counter.value}',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 400),
              Text('Scroll to top...',
                  style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton(
                onPressed: () => scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut),
                child: const Text('Top'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
