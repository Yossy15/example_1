import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yossy_test/src/riverpod/news_state.dart';
import 'package:yossy_test/src/services/api_service.dart';

class NewsNotifier extends StateNotifier<NewsState> {
  final ApiService _apiService;

  NewsNotifier(this._apiService) : super(NewsState.initial()) {
    _loadNews();
  }

  // ดึงข้อมูลจาก api
  Future<void> _loadNews() async {
    state = state.copyWith(news: const AsyncLoading());
    
    try {
      final response = await _apiService.fetchNews();
      final articles = response.articles ?? [];
      state = state.copyWith(news: AsyncValue.data(articles));
    } catch (error, stackTrace) {
      state = state.copyWith(news: AsyncValue.error(error, stackTrace));
    }
  }

  // รีข่าว
  Future<void> refreshNews() async {
    _resetPagination();
    await _loadNews();
    
    // ค้นหาใหม่
    if (state.isSearching && state.searchKeyword.isNotEmpty) {
      performSearch(state.searchKeyword);
    }
  }

  // แหล่งข่าวที่เลือก
  void selectSource(String source) {
    _resetPagination();
    state = state.copyWith(selectedSource: source);
  }

  // ค้นหา
  void performSearch(String keyword) {
    _resetPagination();
    state = state.copyWith(
      searchKeyword: keyword,
      isSearching: keyword.isNotEmpty,
    );
  }

  // รีการค้นหา
  void clearSearch() {
    state = state.copyWith(
      searchKeyword: '',
      isSearching: false,
    );
  }

  // โหลดข้อมูล pagination
  Future<void> loadMore() async {
    if (!state.hasMore) return;
    
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  // รี pagination เมื่อเปลี่ยน source/refresh
  void _resetPagination() {
    state = state.copyWith(currentPage: 1);
  }
}
