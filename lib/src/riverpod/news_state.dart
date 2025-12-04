import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yossy_test/src/models/news_model.dart';

class NewsState {
  final AsyncValue<List<Article>> news;
  final String selectSource;
  final String searchKeyword;
  final bool isSearching;
  final int currentPage;
  final int itemsPerPage;

  const NewsState({
    required this.news,
    this.selectSource = 'all',
    this.searchKeyword = '',
    this.isSearching = false,
    this.currentPage = 1,
    this.itemsPerPage = 20,
  });

  factory NewsState.initial() {
    return const NewsState(
      news: AsyncLoading(),
      selectSource: 'all',
      searchKeyword: '',
      isSearching: false,
      currentPage: 1,
      itemsPerPage: 20,
    );
  }

  // อัปเดต state
  NewsState copyWith({
    AsyncValue<List<Article>>? news,
    String? selectedSource,
    String? searchKeyword,
    bool? isSearching,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return NewsState(
      news: news ?? this.news,
      selectSource: selectedSource ?? this.selectSource,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isSearching: isSearching ?? this.isSearching,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  // ดึงข่าวตาม source
  List<Article> get filterNews {
    return news.when(
      data: (articles) {
        if (selectSource == 'all') return articles;
        return articles.where((article) => article.source?.name == selectSource).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // ดึงข่าวที่ค้นหา
  List<Article> get searchResults {
    if (!isSearching || searchKeyword.isEmpty) return [];
    
    return news.when(
      data: (articles) {
        return articles.where((article) {
          final title = article.title ?? '';
          return title.toLowerCase().contains(searchKeyword.toLowerCase());
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // ดึง sources
  List<String> get sources {
    return news.when(
      data: (articles) {
        final set = <String>{'all'};
        for (var article in articles) {
          if (article.source?.name != null) {
            set.add(article.source!.name!);
          }
        }
        return set.toList();
      },
      loading: () => ['all'],
      error: (_, __) => ['all'],
    );
  }

  // ข่าวที่แสดง (แบบ paginated)
  AsyncValue<List<Article>> get displayNews {
    if (isSearching && searchKeyword.isNotEmpty) {
      final results = searchResults;
      final startIndex = 0;
      final endIndex = currentPage * itemsPerPage;
      final paginatedResults = results.length > endIndex
          ? results.sublist(startIndex, endIndex)
          : results;
      return AsyncValue.data(paginatedResults);
    }

    return news.when(
      data: (data) {
        List<Article> filtered;
        if (selectSource == 'all') {
          filtered = data;
        } else {
          filtered = data.where((article) => article.source?.name == selectSource).toList();
        }
        
        // Pagination: แสดงข้อมูลตาม currentPage
        final startIndex = 0;
        final endIndex = currentPage * itemsPerPage;
        final paginatedData = filtered.length > endIndex 
            ? filtered.sublist(startIndex, endIndex)
            : filtered;
        return AsyncValue.data(paginatedData);
      },
      loading: () => const AsyncLoading(),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
    );
  }

  // ตรวจว่ามีข้อมูลเพิ่มไหม
  bool get hasMore {
    return news.when(
      data: (data) {
        List<Article> filtered;
        if (isSearching && searchKeyword.isNotEmpty) {
          filtered = searchResults;
        } else if (selectSource == 'all') {
          filtered = data;
        } else {
          filtered = data.where((article) => article.source?.name == selectSource).toList();
        }
        return filtered.length > currentPage * itemsPerPage;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }
}

