import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_info.dart';
import '../data/app_repository.dart';
import '../core/constants.dart';

/// 搜索状态
class SearchState {
  final String query;
  final List<AppInfo> results;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<AppInfo>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// 搜索提供者
class SearchNotifier extends StateNotifier<SearchState> {
  Timer? _debounce;

  SearchNotifier() : super(const SearchState());

  /// 更新搜索查询
  void updateQuery(String query) {
    state = state.copyWith(query: query, isSearching: true);

    // 取消之前的去抖定时器
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => _performSearch(query),
    );

    // 如果查询为空，立即返回空结果
    if (query.trim().isEmpty) {
      _debounce?.cancel();
      state = state.copyWith(results: [], isSearching: false);
    }
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }

    try {
      final results = await AppRepository.searchApps(query);
      if (query == state.query) {
        state = state.copyWith(results: results, isSearching: false);
      }
    } catch (e) {
      if (query == state.query) {
        state = state.copyWith(isSearching: false);
      }
    }
  }

  /// 清除搜索
  void clearSearch() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});
