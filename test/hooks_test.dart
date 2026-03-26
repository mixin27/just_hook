import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  group('Standard Hooks', () {
    testWidgets('useState updates and triggers rebuild', (tester) async {
      int buildCount = 0;
      late ValueNotifier<int> counter;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            buildCount++;
            counter = useState(0);
            return Text(
              'Count: ${counter.value}',
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      counter.value++;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('useEffect runs on mount and disposes on unmount', (
      tester,
    ) async {
      int initCount = 0;
      int disposeCount = 0;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useEffect(() {
              initCount++;
              return () => disposeCount++;
            }, const []);
            return const SizedBox();
          },
        ),
      );

      expect(initCount, 1);
      expect(disposeCount, 0);

      await tester.pumpWidget(const SizedBox());

      expect(initCount, 1);
      expect(disposeCount, 1);
    });

    testWidgets('useEffect updates when keys change', (tester) async {
      int initCount = 0;
      int key = 0;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useEffect(() {
              initCount++;
              return null;
            }, [key]);
            return const SizedBox();
          },
        ),
      );

      expect(initCount, 1);

      // Rebuild with same key
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useEffect(() {
              initCount++;
              return null;
            }, [key]);
            return const SizedBox();
          },
        ),
      );
      expect(initCount, 1);

      // Rebuild with different key
      key = 1;
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useEffect(() {
              initCount++;
              return null;
            }, [key]);
            return const SizedBox();
          },
        ),
      );
      expect(initCount, 2);
    });

    testWidgets('useMemoized caches value', (tester) async {
      int buildCount = 0;
      int memoCount = 0;
      int key = 0;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            buildCount++;
            useMemoized(() {
              memoCount++;
              return 'value';
            }, [key]);
            return const SizedBox();
          },
        ),
      );

      expect(memoCount, 1);

      // Rebuild with same key
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            buildCount++;
            useMemoized(() {
              memoCount++;
              return 'value';
            }, [key]);
            return const SizedBox();
          },
        ),
      );
      expect(memoCount, 1);

      // Rebuild with different key
      key = 1;
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            buildCount++;
            useMemoized(() {
              memoCount++;
              return 'value';
            }, [key]);
            return const SizedBox();
          },
        ),
      );
      expect(memoCount, 2);
      expect(buildCount, 3);
    });
  });
}
