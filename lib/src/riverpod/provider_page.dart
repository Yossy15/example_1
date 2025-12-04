import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/services/api_service.dart';
import 'package:yossy_test/src/riverpod/news_notifier.dart';
import 'package:yossy_test/src/riverpod/news_state.dart';

/*
- ref.watch(newsStateProvider) → ดู state ทั้งหมด
- ref.read(newsStateProvider.notifier) → แก้ไข state
----------------------------------------------------------------------------
*/

// provider apiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// provider News State
final newsStateProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NewsNotifier(apiService);
});

// ดึงข้อมูลจาก state
// ref.watch(newsProvider) ดูทั้งหมด
final newsProvider = Provider<AsyncValue<List<Article>>>((ref) {
  return ref.watch(newsStateProvider).news;
});

// ref.watch(filteredNewsProvider) ดูข่าวที่กรอง
final filteredNewsProvider = Provider<List<Article>>((ref) {
  return ref.watch(newsStateProvider).filterNews;
});

// ref.watch(sourcesProvider) ดู sources
final sourcesProvider = Provider<List<String>>((ref) {
  return ref.watch(newsStateProvider).sources;
});

// ref.watch(selectedSourceProvider) ดู source ที่เลือก
final selectedSourceProvider = Provider<String>((ref) {
  return ref.watch(newsStateProvider).selectSource;
});

// ref.watch(searchKeywordProvider) ดูคำค้นหา
final searchKeywordProvider = Provider<String>((ref) {
  return ref.watch(newsStateProvider).searchKeyword;
});

// ref.watch(isSearchingProvider) ดูสถานะการค้นหา
final isSearchingProvider = Provider<bool>((ref) {
  return ref.watch(newsStateProvider).isSearching;
});

// ref.watch(displayNewsProvider) ข่าวที่แสดงจากการค้นหาและกรอง)
final displayNewsProvider = Provider<AsyncValue<List<Article>>>((ref) {
  return ref.watch(newsStateProvider).displayNews;
});