import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_hook/just_hook.dart';

void main() {
  group('Domain Hooks', () {
    testWidgets('useForm manages field values and validation', (tester) async {
      late FormController form;
      late TextEditingController nameController;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(
            builder: (context) {
              form = useForm();
              nameController = form.register(
                'name',
                initialValue: 'John',
                validators: [(v) => v == null || v.isEmpty ? 'Required' : null],
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(form.values['name'], 'John');
      expect(form.errors.isEmpty, true);

      // Update field
      nameController.text = '';
      await tester.pump();

      expect(form.values['name'], '');
      expect(form.errors['name'], 'Required');

      // Submit
      bool submitted = false;
      await form.submit((values) => submitted = true);
      expect(submitted, false); // Validation failed

      nameController.text = 'Jane';
      await tester.pump();
      await form.submit((values) => submitted = true);
      expect(submitted, true);
    });

    testWidgets('usePagination manages loading and data states', (
      tester,
    ) async {
      final completer = Completer<List<String>>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(
            builder: (context) {
              final pagination = usePagination<String>(
                initialPage: 0,
                fetcher: (page) => completer.future,
              );
              return Text(pagination.isLoading ? 'Loading' : 'Done');
            },
          ),
        ),
      );

      expect(find.text('Loading'), findsOneWidget);

      completer.complete(['a', 'b']);
      await tester.pump(Duration.zero);
      await tester.pump(); // Rebuild after setState

      expect(find.text('Done'), findsOneWidget);
    });
  });
}
