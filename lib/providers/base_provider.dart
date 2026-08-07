import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_response.dart';

abstract class BaseProvider<T> extends ChangeNotifier {
  ApiResponse<T> _state = ApiResponse.empty();
  ApiResponse<T> get state => _state;

  // Pagination parameters
  int _page = 1;
  int _pageSize = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  int get page => _page;
  int get pageSize => _pageSize;
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  // Search parameters
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  Timer? _searchDebounceTimer;

  // Request & Lifecycle safety
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  CancelToken? _cancelToken;
  CancelToken? get cancelToken => _cancelToken;

  // Refresh Throttling
  DateTime? _lastRefreshTime;
  static const Duration _refreshThrottleDuration = Duration(seconds: 2);

  /// Helper to generate a new CancelToken, automatically cancelling any active preceding request
  CancelToken getNewCancelToken() {
    _cancelToken?.cancel('Request superseded by newer query.');
    _cancelToken = CancelToken();
    return _cancelToken!;
  }

  /// Sets state and notifies listeners, ensuring the provider is active
  void setState(ApiResponse<T> newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  /// Checks if the refresh action should be throttled to prevent spamming
  bool shouldThrottleRefresh() {
    if (_lastRefreshTime == null) return false;
    final now = DateTime.now();
    return now.difference(_lastRefreshTime!) < _refreshThrottleDuration;
  }

  /// Updates the timestamp of the last successful refresh action
  void updateRefreshTimestamp() {
    _lastRefreshTime = DateTime.now();
  }

  /// Executes a single asynchronous task with loading/error handling.
  /// Prevents duplicate requests if already loading.
  @protected
  Future<void> executeTask(
    Future<T> Function(CancelToken token) task, {
    bool isRefresh = false,
  }) async {
    if (_state.isLoading) return; // Prevent multiple clicks / double requests

    if (isRefresh) {
      if (shouldThrottleRefresh()) return;
      updateRefreshTimestamp();
      resetPagination();
    }

    setState(ApiResponse.loading());
    final token = getNewCancelToken();

    try {
      final T result = await task(token);
      
      if (_isDisposed) return;

      if (result == null || (result is List && result.isEmpty)) {
        setState(ApiResponse.empty());
      } else {
        setState(ApiResponse.success(result));
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      setState(ApiResponse.error(e.toString()));
    }
  }

  /// Executes a paginated task. Automatically updates pages and limits duplicate fetching.
  @protected
  Future<void> executePaginatedTask({
    required Future<List<dynamic>> Function(int page, int pageSize, CancelToken token) fetchTask,
    required void Function(List<dynamic> items, bool isRefresh) onDataLoaded,
    bool isRefresh = false,
  }) async {
    if (_state.isLoading || _isFetchingMore) return;

    if (isRefresh) {
      if (shouldThrottleRefresh()) return;
      updateRefreshTimestamp();
      _page = 1;
      _hasMore = true;
      setState(ApiResponse.loading());
    } else {
      if (!_hasMore) return;
      _isFetchingMore = true;
      notifyListeners();
    }

    final token = getNewCancelToken();

    try {
      final List<dynamic> items = await fetchTask(_page, _pageSize, token);
      
      if (_isDisposed) return;

      if (items.length < _pageSize) {
        _hasMore = false;
      } else {
        _page++;
      }

      onDataLoaded(items, isRefresh);
      _isFetchingMore = false;
      
      if (isRefresh && items.isEmpty) {
        setState(ApiResponse.empty());
      } else {
        notifyListeners();
      }
    } catch (e) {
      _isFetchingMore = false;
      if (e is DioException && CancelToken.isCancel(e)) return;
      
      if (isRefresh) {
        setState(ApiResponse.error(e.toString()));
      } else {
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    }
  }

  /// Debounce wrapper for search queries to avoid firing APIs on every keystroke
  void debounceSearch(
    String query,
    void Function(String query) onSearch, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _searchQuery = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(duration, () {
      if (!_isDisposed) {
        onSearch(query);
      }
    });
  }

  /// Resets pagination page indexes
  void resetPagination() {
    _page = 1;
    _hasMore = true;
    _isFetchingMore = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounceTimer?.cancel();
    _cancelToken?.cancel('Provider disposed, cancellation token destroyed.');
    super.dispose();
  }
}
