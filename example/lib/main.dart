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
    final debouncedSearch =
        useDebounced(search.text, const Duration(milliseconds: 500));

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
              Text('Debounced: $debouncedSearch',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
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
              const SizedBox(height: 32),
              _ExampleButton(
                title: 'Pagination Example',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaginationExample()),
                ),
              ),
              _ExampleButton(
                title: 'Form Hooks Example',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormExample()),
                ),
              ),
              _ExampleButton(
                title: 'Query & Animation Hooks',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const QueryAndAnimationExample()),
                ),
              ),
              _ExampleButton(
                title: 'Roadmap Hooks (Theme, Lifecycle, etc.)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoadmapHooksExample()),
                ),
              ),
              const SizedBox(height: 100),
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

class _ExampleButton extends StatelessWidget {
  const _ExampleButton({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: onTap,
        child: Text(title),
      ),
    );
  }
}

class QueryAndAnimationExample extends HookWidget {
  const QueryAndAnimationExample({super.key});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    useEffect(() {
      animationController.repeat(reverse: true);
      return null;
    }, const []);
    
    final animationValue = useValueListenable(animationController);

    final fetcher = useMemoized(() => () async {
      await Future.delayed(const Duration(seconds: 1));
      if (DateTime.now().second % 4 == 0) {
        throw Exception('Network error');
      }
      return 'Server Data: ${DateTime.now().toIso8601String()}';
    }, []);

    final httpQuery = useQuery<String>(
      fetcher: fetcher,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Animation & HTTP Query')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Animation Controller Hook', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Container(
              width: 100 * (1.0 + animationValue),
              height: 100 * (1.0 + animationValue),
              color: Colors.blueAccent,
            ),
            const Divider(height: 64),
            const Text('HTTP useQuery Hook', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            if (httpQuery.isLoading)
              const CircularProgressIndicator()
            else if (httpQuery.error != null)
              Column(
                children: [
                   Text('Error: ${httpQuery.error}', style: const TextStyle(color: Colors.red)),
                   const SizedBox(height: 8),
                   ElevatedButton(
                     onPressed: httpQuery.refetch,
                     child: const Text('Retry'),
                   ),
                ]
              )
            else
              Column(
                children: [
                   Text(httpQuery.data ?? 'No Data'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: httpQuery.isFetching ? null : httpQuery.refetch,
                     child: httpQuery.isFetching
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Refetch'),
                   ),
                ]
              )
          ],
        ),
      ),
    );
  }
}

class FormExample extends HookWidget {
  const FormExample({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm();
    final nameController = form.register('name', validators: [
      (value) => value == null || value.isEmpty ? 'Name is required' : null,
      (value) => value != null && value.length < 3 ? 'Name too short' : null,
    ]);

    final emailController = form.register('email', validators: [
      (value) => value == null || value.isEmpty ? 'Email is required' : null,
      (value) => value != null && !value.contains('@') ? 'Invalid email' : null,
    ]);

    final onSubmit = useMemoized(
        () => (Map<String, String> data) async {
              await Future.delayed(const Duration(seconds: 2));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Submitted: ${data["name"]} / ${data["email"]}')),
              );
            },
        []);

    return Scaffold(
      appBar: AppBar(title: const Text('Form Hook')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: form.errors['name'],
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: form.errors['email'],
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: form.isSubmitting ? null : () => form.submit(onSubmit),
              child: form.isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
            if (!form.isValid && !form.isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text('Please fix errors.',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

class PaginationExample extends HookWidget {
  const PaginationExample({super.key});

  @override
  Widget build(BuildContext context) {
    final fetchDummyData = useMemoized(
        () => (int page) async {
              await Future.delayed(const Duration(seconds: 1));
              if (page >= 5) return <String>[];
              return List.generate(
                  15, (i) => 'Item ${(page - 1) * 15 + i + 1}');
            },
        []);

    final pagination = usePagination<String>(
      fetcher: fetchDummyData,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pagination Hook')),
      body: RefreshIndicator(
        onRefresh: pagination.refresh,
        child: ListView.builder(
          itemCount: pagination.items.length + (pagination.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == pagination.items.length) {
              if (!pagination.isLoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  pagination.fetchMore();
                });
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final item = pagination.items[index];
            return ListTile(title: Text(item));
          },
        ),
      ),
    );
  }
}

class RoadmapHooksExample extends HookWidget {
  const RoadmapHooksExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = useTheme();
    final mediaQuery = useMediaQuery();
    final lifecycle = useAppLifecycleState();

    final controller = useStreamController<int>();
    final count = useStream(controller.stream, initialData: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roadmap Hooks'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('useTheme'),
              subtitle: Text('Primary Color: ${theme.primaryColor}'),
              trailing: Icon(Icons.palette, color: theme.primaryColor),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('useMediaQuery'),
              subtitle: Text(
                  'Size: ${mediaQuery.size.width.toInt()} x ${mediaQuery.size.height.toInt()}'),
              trailing: const Icon(Icons.aspect_ratio),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('useAppLifecycleState'),
              subtitle: Text('Current State: ${lifecycle.name}'),
              trailing: Icon(
                lifecycle == AppLifecycleState.resumed
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('useStreamController'),
                  subtitle: Text('Stream Value: ${count.data}'),
                  trailing: const Icon(Icons.reorder),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => controller.add((count.data ?? 0) + 1),
                    child: const Text('Add to Stream'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
