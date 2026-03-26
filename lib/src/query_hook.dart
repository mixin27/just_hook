import 'dart:async';
import 'package:flutter/widgets.dart';

import 'framework.dart';

/// The state of a [useQuery] request.
class QueryState<T> {
  const QueryState({
    required this.data,
    required this.error,
    required this.isLoading,
    required this.isFetching,
    required this.refetch,
  });

  /// The most recently successfully fetched data. Null if none is available.
  final T? data;

  /// The error thrown by the fetcher during the latest attempt.
  final Object? error;

  /// True during the first-ever fetching cycle (when no data exists).
  final bool isLoading;

  /// True anytime the fetcher is yielding, including background refetches.
  final bool isFetching;

  /// Explicitly trigger a refetch of the data. 
  /// The [isFetching] state will turn true whilst waiting.
  final Future<void> Function() refetch;
}

/// A hook tailored for fetching, caching, and serving asynchronous requests,
/// especially identical to fetching HTTP REST APIs.
/// 
/// It mimics `useQuery` from popular fetching libraries by providing
/// discrete [QueryState.isLoading], [QueryState.isFetching], and [QueryState.refetch] flags.
QueryState<T> useQuery<T>({
  required Future<T> Function() fetcher,
  List<Object?> keys = const [],
  T? initialData,
  bool enabled = true,
}) {
  return use(_QueryHook<T>(
    fetcher: fetcher,
    keys: keys,
    initialData: initialData,
    enabled: enabled,
  ));
}

class _QueryHook<T> extends Hook<QueryState<T>> {
  const _QueryHook({
    required this.fetcher,
    super.keys,
    this.initialData,
    required this.enabled,
  });

  final Future<T> Function() fetcher;
  final T? initialData;
  final bool enabled;

  @override
  _QueryHookState<T> createState() => _QueryHookState<T>();
}

class _QueryHookState<T> extends HookState<QueryState<T>, _QueryHook<T>> {
  T? _data;
  Object? _error;
  bool _isLoading = false;
  bool _isFetching = false;
  int _fetchCount = 0;
  bool _isDisposed = false;

  @override
  void initHook() {
    super.initHook();
    _data = hook.initialData;
    if (hook.enabled) {
      _fetchData(isInitial: _data == null);
    }
  }

  @override
  void didUpdateHook(_QueryHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (!oldHook.enabled && hook.enabled) {
      _fetchData(isInitial: _data == null);
    } else if (hook.enabled && HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _fetchData(isInitial: _data == null);
    }
  }

  Future<void> _fetchData({bool isInitial = false}) async {
    final currentFetchId = ++_fetchCount;

    setState(() {
      if (isInitial) _isLoading = true;
      _isFetching = true;
      _error = null;
    });

    try {
      final result = await hook.fetcher();
      if (_isDisposed || currentFetchId != _fetchCount) return;

      setState(() {
        _data = result;
        _isLoading = false;
        _isFetching = false;
      });
    } catch (e) {
      if (_isDisposed || currentFetchId != _fetchCount) return;

      setState(() {
        _error = e;
        _isLoading = false;
        _isFetching = false;
      });
    }
  }

  Future<void> _refetch() => _fetchData(isInitial: false);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  QueryState<T> build(BuildContext context) {
    return QueryState<T>(
      data: _data,
      error: _error,
      isLoading: _isLoading,
      isFetching: _isFetching,
      refetch: _refetch,
    );
  }
}
