import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  group('Utility Hooks', () {
    testWidgets('useIsMounted returns correct value', (tester) async {
      late bool Function() isMounted;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            isMounted = useIsMounted();
            return const SizedBox();
          },
        ),
      );

      expect(isMounted(), true);

      await tester.pumpWidget(const SizedBox());

      expect(isMounted(), false);
    });

    testWidgets('useDebounced delays value updates', (tester) async {
      int value = 0;
      late int debouncedValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            debouncedValue = useDebounced(
              value,
              const Duration(milliseconds: 100),
            );
            return const SizedBox();
          },
        ),
      );

      expect(debouncedValue, 0);

      value = 1;
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            debouncedValue = useDebounced(
              value,
              const Duration(milliseconds: 100),
            );
            return const SizedBox();
          },
        ),
      );

      // Still 0 because of debounce
      expect(debouncedValue, 0);

      await tester.pump(const Duration(milliseconds: 50));
      expect(debouncedValue, 0);

      await tester.pump(const Duration(milliseconds: 60)); // Total 110ms
      expect(debouncedValue, 1);
    });
  });
}
