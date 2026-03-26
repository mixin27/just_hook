import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  group('Advanced Hooks', () {
    testWidgets('useFuture updates with loading and data', (tester) async {
      final completer = Completer<String>();
      late AsyncSnapshot<String> snapshot;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            snapshot = useFuture(completer.future);
            return const SizedBox();
          },
        ),
      );

      expect(snapshot.connectionState, ConnectionState.waiting);

      completer.complete('done');
      await tester.pump(Duration.zero);

      expect(snapshot.connectionState, ConnectionState.done);
      expect(snapshot.data, 'done');
    });

    testWidgets('useFuture updates with error', (tester) async {
      final completer = Completer<String>();
      late AsyncSnapshot<String> snapshot;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            snapshot = useFuture(completer.future);
            return const SizedBox();
          },
        ),
      );

      completer.completeError('error');
      await tester.pump(Duration.zero);

      expect(snapshot.connectionState, ConnectionState.done);
      expect(snapshot.error, 'error');
    });

    testWidgets('useStream updates when stream emits', (tester) async {
      final controller = StreamController<int>();
      late AsyncSnapshot<int> snapshot;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            snapshot = useStream(controller.stream, initialData: 0);
            return const SizedBox();
          },
        ),
      );

      expect(snapshot.data, 0);

      controller.add(1);
      await tester.pump(Duration.zero);

      expect(snapshot.data, 1);

      controller.close();
      await tester.pump(Duration.zero);
      expect(snapshot.connectionState, ConnectionState.done);
    });

    testWidgets('usePrevious returns the value from the previous build', (
      tester,
    ) async {
      int value = 0;
      int? previousValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            previousValue = usePrevious(value);
            return const SizedBox();
          },
        ),
      );

      expect(previousValue, isNull);

      value = 1;
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            previousValue = usePrevious(value);
            return const SizedBox();
          },
        ),
      );

      expect(previousValue, 0);

      value = 2;
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            previousValue = usePrevious(value);
            return const SizedBox();
          },
        ),
      );

      expect(previousValue, 1);
    });
  });
}
