import 'dart:async';
import 'package:flutter/widgets.dart';

import 'framework.dart';

/// A validation function for a form field.
/// Returns an error message if invalid, or null if valid.
typedef HookValidator = String? Function(String? value);

/// A controller that manages form state, validation, and submission.
class FormController {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<HookValidator>> _validators = {};
  final Map<String, String?> _errors = {};
  
  bool _isSubmitting = false;

  /// Returns the current validation errors across all fields.
  Map<String, String?> get errors => Map.unmodifiable(_errors);

  /// True if a submission is currently in progress.
  bool get isSubmitting => _isSubmitting;

  /// True if there are currently no validation errors.
  bool get isValid => _errors.values.every((e) => e == null);

  /// Helper to get the current string values for all fields.
  Map<String, String> get values =>
      _controllers.map((key, c) => MapEntry(key, c.text));

  final void Function() _rebuild;

  FormController(this._rebuild);

  /// Registers a text field by [name] and creates a [TextEditingController] for it.
  /// You can provide [validators] to automatically track error states.
  TextEditingController register(String name, {
    List<HookValidator> validators = const [],
    String? initialValue,
  }) {
    if (!_controllers.containsKey(name)) {
      final controller = TextEditingController(text: initialValue);
      _controllers[name] = controller;
      controller.addListener(() {
        final error = _validateField(name, controller.text);
        if (_errors[name] != error) {
          _errors[name] = error;
          _rebuild();
        }
      });
    }
    _validators[name] = validators;
    return _controllers[name]!;
  }

  /// Sets an explicit error on a field and triggers a rebuild.
  void setError(String name, String error) {
    _errors[name] = error;
    _rebuild();
  }

  /// Clears all validation errors and triggers a rebuild.
  void clearErrors() {
    _errors.clear();
    _rebuild();
  }

  String? _validateField(String name, String? value) {
    if (!_validators.containsKey(name)) return null;
    for (final validator in _validators[name]!) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Runs all validators across registered fields.
  /// Returns `true` if all fields are valid.
  bool validate() {
    bool valid = true;
    _errors.clear();
    for (final entry in _controllers.entries) {
      final error = _validateField(entry.key, entry.value.text);
      if (error != null) {
        _errors[entry.key] = error;
        valid = false;
      }
    }
    _rebuild();
    return valid;
  }

  /// Submits the form if it is valid. 
  /// The [onSubmit] callback is invoked with the current form values.
  /// Automatically manages [isSubmitting] states during the asynchronous gap.
  Future<void> submit(FutureOr<void> Function(Map<String, String> data) onSubmit) async {
    if (!validate()) return;

    _isSubmitting = true;
    _rebuild();

    try {
      await onSubmit(values);
    } finally {
      // isSubmitting could be aborted if unmounted, but _rebuild is protected.
      _isSubmitting = false;
      _rebuild();
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }
}

/// A hook that provides a [FormController] for effortless form validation
/// and submission handling. Think of it as a flutter equivalent to React-Hook-Form.
FormController useForm() {
  return use(const _FormHook());
}

class _FormHook extends Hook<FormController> {
  const _FormHook();

  @override
  _FormHookState createState() => _FormHookState();
}

class _FormHookState extends HookState<FormController, _FormHook> {
  late FormController _formController;
  bool _isDisposed = false;

  @override
  void initHook() {
    super.initHook();
    _formController = FormController(() {
      if (!_isDisposed) setState(() {});
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _formController.dispose();
    super.dispose();
  }

  @override
  FormController build(BuildContext context) => _formController;
}
