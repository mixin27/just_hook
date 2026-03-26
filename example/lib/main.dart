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

    useEffect(() {
      print('Effect triggered: Counter is now ${counter.value}');
      return () => print('Cleanup triggered for counter ${counter.value}');
    }, [counter.value]);

    final doubleValue = useMemoized(() {
      print('Computing double value...');
      return counter.value * 2;
    }, [counter.value]);

    return Scaffold(
      appBar: AppBar(title: const Text('just_hook Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Counter: ${counter.value}',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Doubled: $doubleValue', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
