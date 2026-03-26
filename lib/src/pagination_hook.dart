import 'package:flutter/widgets.dart';

import 'framework.dart';

/// The state returned by [usePagination].
///
/// It contains the current list of [items], status flags ([isLoading], [hasMore]),
/// and methods to fetch more data or refresh the list.
class PaginationState<T> {
  const PaginationState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.page,
    this.error,
    required this.fetchMore,
    required this.refresh,
  });

  /// The current list of items loaded.
  final List<T> items;

  /// Whether a fetch operation is currently in progress.
  final bool isLoading;

  /// Whether more items might be available.
  ///
  /// Usually turns false when the [fetcher] returns an empty list.
  final bool hasMore;

  /// The current page number.
  final int page;

  /// The last error caught during fetching, if any.
  final Object? error;

  /// Requests the next page of items to be loaded and appended.
  final Future<void> Function() fetchMore;

  /// Clears the items and re-fetches the initial page.
  final Future<void> Function() refresh;
}

/// A hook that manages pagination state for infinite lists.
///
/// It tracks a list of [items], [isLoading] status, and a [page] counter.
/// Use [PaginationState.fetchMore] to load the next page and
/// [PaginationState.refresh] to reset and reload the list.
///
/// The [fetcher] is called with the current page number and should return
/// a [Future] with a list of items.
PaginationState<T> usePagination<T>({
  required Future<List<T>> Function(int page) fetcher,
  int initialPage = 1,
  List<Object?>? keys,
}) {
  return use(
    _PaginationHook<T>(fetcher: fetcher, initialPage: initialPage, keys: keys),
  );
}

class _PaginationHook<T> extends Hook<PaginationState<T>> {
  const _PaginationHook({
    required this.fetcher,
    required this.initialPage,
    super.keys,
  });

  final Future<List<T>> Function(int page) fetcher;
  final int initialPage;

  @override
  _PaginationHookState<T> createState() => _PaginationHookState<T>();
}

class _PaginationHookState<T>
    extends HookState<PaginationState<T>, _PaginationHook<T>> {
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  Object? _error;
  bool _isDisposed = false;

  @override
  void initHook() {
    super.initHook();
    _page = hook.initialPage;
    _fetchPage(_page, isRefresh: true);
  }

  @override
  void didUpdateHook(_PaginationHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (HookKeys.didKeysChange(oldHook.keys, hook.keys)) {
      _fetchPage(hook.initialPage, isRefresh: true);
    }
  }

  Future<void> _fetchPage(int pageToFetch, {bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _hasMore = true;
      }
    });

    try {
      final newItems = await hook.fetcher(pageToFetch);

      if (_isDisposed) return;

      setState(() {
        if (isRefresh) {
          _items = newItems;
          _page = hook.initialPage;
        } else {
          _items = [..._items, ...newItems];
        }
        _hasMore = newItems.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    if (!_hasMore || _isLoading) return;
    _page++;
    await _fetchPage(_page);
  }

  Future<void> _refresh() async {
    await _fetchPage(hook.initialPage, isRefresh: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  PaginationState<T> build(BuildContext context) {
    return PaginationState<T>(
      items: _items,
      isLoading: _isLoading,
      hasMore: _hasMore,
      page: _page,
      error: _error,
      fetchMore: _fetchMore,
      refresh: _refresh,
    );
  }
}
