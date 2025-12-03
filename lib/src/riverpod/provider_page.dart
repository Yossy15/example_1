import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yossy_test/src/services/api_service.dart';
import 'package:yossy_test/src/models/news_model.dart';

/*
----------------------------------------------------------------------------
- ref.watch(provider) ฟังค่า, rebuild UI
- ref.read(provider.notifier) แก้ไขค่า, ไม่ rebuild UI
- ทุกครั้งที่แก้ state ผ่าน notifier โดย UI ที่ watch provider จะ rebuild อัตโนมัติ
----------------------------------------------------------------------------
- Provider ค่าคงที่, ไม่ rebuild UI
- StateProvider ค่าที่เปลี่ยนแปลง, rebuild UI
- FutureProvider ค่าที่เปลี่ยนแปลง, rebuild UI
- family ใช้รับค่าเพิ่มเติม
----------------------------------------------------------------------------
*/

// Provider = ค่าคงที่, ไม่ rebuild UI
// ref.watch(apiServiceProvider) เรียก API
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// State เก็บแหล่งข่าว
// ref.watch(selectedSourceAll)
final selectedSourceAll = StateProvider<String>((ref) => 'all');

// FutureProvider = ค่าที่เปลี่ยนแปลง, rebuild UI
// ref.watch(newsProvider)
final newsProvider = FutureProvider<List<Article>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.fetchNews();
  return response.articles ?? [];
});

// family รับค่าเพื่อกรองข่าว
// ref.watch(filteredNewsProvider)
final filteredNewsProvider = FutureProvider.family<List<Article>, String>((ref, source) async {
  final allNewsAsync = await ref.watch(newsProvider.future);
  if (source == 'all') return allNewsAsync;
  return allNewsAsync.where((article) => article.source?.name == source).toList();
});

// ref.watch(sourcesProvider) ดึงข่าว
final sourcesProvider = FutureProvider<List<String>>((ref) async {
  final allNewsAsync = await ref.watch(newsProvider.future);
  final set = <String>{'all'};
  for (var article in allNewsAsync) {
    if (article.source?.name != null) set.add(article.source!.name!);
  }
  return set.toList();
});

// ref.watch(searchKeywordProvider) เก็บคำค้นหา
final searchKeywordProvider = StateProvider<String>((ref) => '');

// ref.watch(searchResultsProvider) ดึงข้อมูลผลค้น
// AsyncValue → จัดการ loading/data/error
final searchResultsProvider = StateProvider<AsyncValue<List<Article>>>((ref) {
  return const AsyncData([]);
});

// ref.watch(isSearchingProvider) สถานะการค้น
final isSearchingProvider = StateProvider<bool>((ref) => false);

// ref.watch(initialNewsProvider) ดึงข้อมูลข่าวเริ่มต้น
// final initialNewsProvider = FutureProvider<List<Article>>((ref) async {
//   final apiService = ref.watch(apiServiceProvider);
//   final response = await apiService.fetchNews();
//   return response.articles ?? [];
// });

void performSearch(WidgetRef ref, String keyword) {
  ref.read(searchKeywordProvider.notifier).state = keyword; // เก็บค่า keyword

  ref.read(isSearchingProvider.notifier).state = keyword.isNotEmpty; // สถานะการค้น

  if (keyword.isEmpty) { // ถ้าไม่มีค่า keyword
    ref.read(searchResultsProvider.notifier).state = const AsyncData([]);
    return;
  }

  ref.read(searchResultsProvider.notifier).state = const AsyncLoading();
  try {
    final allArticlesAsync = ref.read(newsProvider);
    allArticlesAsync.when(
      data: (allArticles) {
        final filteredArticles = allArticles.where((article) {
          final title = article.title ?? '';
          return title.toLowerCase().contains(keyword.toLowerCase());
        }).toList();

        ref.read(searchResultsProvider.notifier).state = AsyncData(filteredArticles);
      },
      loading: () => ref.read(searchResultsProvider.notifier).state = const AsyncLoading(),
      error: (error, stackTrace) => ref.read(searchResultsProvider.notifier).state = AsyncError(error, stackTrace),
    );
  } catch (e, st) {
    ref.read(searchResultsProvider.notifier).state = AsyncError(e, st);
  }
}

void clearSearch(WidgetRef ref) {
  ref.read(searchKeywordProvider.notifier).state = '';
  ref.read(isSearchingProvider.notifier).state = false;
  ref.read(searchResultsProvider.notifier).state = const AsyncData([]);
  ref.read(newsProvider);
}