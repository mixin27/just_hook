import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  group('HookElement / Core Engine', () {
    testWidgets('hooks are called in order and values are preserved', (
      tester,
    ) async {
      late int state1;
      late String state2;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            state1 = useState(10).value;
            state2 = useState('hello').value;
            return const SizedBox();
          },
        ),
      );

      expect(state1, 10);
      expect(state2, 'hello');

      // Rebuild with new values
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final s1 = useState(10);
            final s2 = useState('hello');

            useEffect(() {
              s1.value = 20;
              s2.value = 'world';
              return null;
            }, const []);

            state1 = s1.value;
            state2 = s2.value;
            return const SizedBox();
          },
        ),
      );

      await tester.pump(); // Trigger rebuild from setState in useEffect

      expect(state1, 20);
      expect(state2, 'world');
    });

    testWidgets('throwing error if hooks are called conditionally', (
      tester,
    ) async {
      bool callHook = true;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useState(0);
            if (callHook) {
              useState(1);
            }
            return const SizedBox();
          },
        ),
      );

      callHook = false;
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useState(0);
            if (callHook) {
              useState(1);
            }
            return const SizedBox();
          },
        ),
      );

      expect(tester.takeException(), isStateError);
    });

    testWidgets('hooks are disposed correctly on unmount', (tester) async {
      bool disposed = false;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useEffect(() {
              return () => disposed = true;
            }, const []);
            return const SizedBox();
          },
        ),
      );

      expect(disposed, false);

      await tester.pumpWidget(const SizedBox());

      expect(disposed, true);
    });

    testWidgets('useContext returns current BuildContext', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            capturedContext = useContext();
            return const SizedBox();
          },
        ),
      );

      expect(capturedContext, isNotNull);
      expect(capturedContext, isA<Element>());
    });
  });
}
