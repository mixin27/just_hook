import 'dart:async';
import 'package:flutter/widgets.dart';

import 'framework.dart';
import 'advanced_hooks.dart';

/// The state of an asynchronous operation returned by [useQuery].
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

  /// `true` during the first-ever fetching cycle (when no data exists).
  final bool isLoading;

  /// `true` anytime the fetcher is yielding, including background refetches.
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
  return use(
    _QueryHook<T>(
      fetcher: fetcher,
      keys: keys,
      initialData: initialData,
      enabled: enabled,
    ),
  );
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
    } else if (hook.enabled &&
        HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
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

/// The state of a mutation returned by [useMutation].
class MutationState<TData, TVariables> {
  const MutationState({
    this.data,
    this.error,
    required this.isMutating,
    required this.mutate,
  });

  final TData? data;
  final Object? error;
  final bool isMutating;
  final Future<TData?> Function(TVariables variables) mutate;
}

/// A hook for operations that modify server-side data (POST, PUT, DELETE).
///
/// It exposes [MutationState.isMutating] status and a [MutationState.mutate]
/// function to trigger the operation.
MutationState<TData, TVariables> useMutation<TData, TVariables>({
  required Future<TData> Function(TVariables variables) mutationFn,
  void Function(TData data, TVariables variables)? onSuccess,
  void Function(Object error, TVariables variables)? onError,
  void Function(TVariables variables)? onMutate,
}) {
  return use(
    _MutationHook<TData, TVariables>(
      mutationFn: mutationFn,
      onSuccess: onSuccess,
      onError: onError,
      onMutate: onMutate,
    ),
  );
}

class _MutationHook<TData, TVariables>
    extends Hook<MutationState<TData, TVariables>> {
  const _MutationHook({
    required this.mutationFn,
    this.onSuccess,
    this.onError,
    this.onMutate,
  });

  final Future<TData> Function(TVariables variables) mutationFn;
  final void Function(TData data, TVariables variables)? onSuccess;
  final void Function(Object error, TVariables variables)? onError;
  final void Function(TVariables variables)? onMutate;

  @override
  _MutationHookState<TData, TVariables> createState() =>
      _MutationHookState<TData, TVariables>();
}

class _MutationHookState<TData, TVariables>
    extends
        HookState<
          MutationState<TData, TVariables>,
          _MutationHook<TData, TVariables>
        > {
  TData? _data;
  Object? _error;
  bool _isMutating = false;
  bool _isDisposed = false;

  Future<TData?> _mutate(TVariables variables) async {
    setState(() {
      _isMutating = true;
      _error = null;
    });

    hook.onMutate?.call(variables);

    try {
      final result = await hook.mutationFn(variables);
      if (_isDisposed) return null;

      setState(() {
        _data = result;
        _isMutating = false;
      });

      hook.onSuccess?.call(result, variables);
      return result;
    } catch (e) {
      if (_isDisposed) return null;

      setState(() {
        _error = e;
        _isMutating = false;
      });

      hook.onError?.call(e, variables);
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  MutationState<TData, TVariables> build(BuildContext context) {
    return MutationState<TData, TVariables>(
      data: _data,
      error: _error,
      isMutating: _isMutating,
      mutate: _mutate,
    );
  }
}

/// The state of a subscription returned by [useSubscription].
class SubscriptionState<T> {
  const SubscriptionState({
    required this.data,
    required this.error,
    required this.isConnected,
  });

  /// The most recently emitted value from the stream.
  final T? data;

  /// The last error emitted by the stream, if any.
  final Object? error;

  /// `true` if the stream is actively delivering events.
  final bool isConnected;
}

/// A hook designed to subscribe to real-time APIs like WebSockets or GraphQL Subscriptions.
/// It wraps around an underlying stream but exposes state semantics identical to [useQuery].
SubscriptionState<T> useSubscription<T>(Stream<T> stream, {T? initialData}) {
  final snapshot = useStream(stream, initialData: initialData);
  return SubscriptionState<T>(
    data: snapshot.data,
    error: snapshot.error,
    isConnected: snapshot.connectionState == ConnectionState.active,
  );
}
