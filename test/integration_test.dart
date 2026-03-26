import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_hook/just_hook.dart';

class MyStatefulHookWidget extends StatefulHookWidget {
  const MyStatefulHookWidget({super.key, required this.onBuild});
  final VoidCallback onBuild;

  @override
  State<MyStatefulHookWidget> createState() => _MyStatefulHookWidgetState();
}

class _MyStatefulHookWidgetState extends State<MyStatefulHookWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    final hookState = useState(0);
    return Column(
      children: [
        Text('State: $_counter', textDirection: TextDirection.ltr),
        Text('Hook: ${hookState.value}', textDirection: TextDirection.ltr),
        GestureDetector(
          onTap: () {
            setState(() => _counter++);
            hookState.value++;
          },
          child: const Text('Tap', textDirection: TextDirection.ltr),
        ),
      ],
    );
  }
}

void main() {
  group('Integration Tests', () {
    testWidgets('HookBuilder works inside any widget', (tester) async {
      int? hookValue;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(
            builder: (context) {
              hookValue = useState(100).value;
              return Text('Hook: $hookValue');
            },
          ),
        ),
      );

      expect(hookValue, 100);
      expect(find.text('Hook: 100'), findsOneWidget);
    });

    testWidgets('StatefulHookWidget combines State and Hooks', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MyStatefulHookWidget(onBuild: () => buildCount++),
      );

      expect(buildCount, 1);
      expect(find.text('State: 0'), findsOneWidget);
      expect(find.text('Hook: 0'), findsOneWidget);

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('State: 1'), findsOneWidget);
      expect(find.text('Hook: 1'), findsOneWidget);
    });
  });
}
