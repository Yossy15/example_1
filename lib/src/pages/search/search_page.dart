import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/pages/detail/detail_page.dart';
import 'package:yossy_test/src/riverpod/provider_page.dart';
import 'package:yossy_test/src/utils/date_utils.dart';
import 'package:extended_image/extended_image.dart';
// import 'package:yossy_test/src/providers/search_provider.dart';

class searchPage extends ConsumerStatefulWidget {
  const searchPage({super.key});

  @override
  ConsumerState<searchPage> createState() => _searchPageState();
}

class _searchPageState extends ConsumerState<searchPage> {
  final RefreshController _refreshController = RefreshController(
      initialRefresh: false);
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyword = ref.read(searchKeywordProvider);
      controller.text = keyword;

      if (keyword.isNotEmpty) {
        performSearch(ref, keyword);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = ref.watch(searchKeywordProvider);
    final isSearching = ref.watch(isSearchingProvider);
    final searchResultsState = ref.watch(searchResultsProvider);
    final initialNewsState = ref.watch(newsProvider);

    final AsyncValue<List<Article>> displayState = isSearching
        ? searchResultsState
        : initialNewsState.when(
      data: (data) => AsyncData(data),
      loading: () => const AsyncLoading(),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
            controller.clear();
            clearSearch(ref);
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey[200],
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: keyword.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        clearSearch(ref);
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    hintText: "ค้นหา",
                  ),
                  onChanged: (value) {
                    performSearch(ref, value);
                  },
                ),
              ),
            )
          ],
        ),
      ),
      body: displayState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (articles) {
          return SmartRefresher(
            controller: _refreshController,
            onRefresh: () {
              ref.refresh(newsProvider);
              if (keyword.isNotEmpty) {
                performSearch(ref, keyword);
              }
              _refreshController.refreshCompleted();
            },
            // enablePullDown: true,
            // enablePullUp: true,
            child: ListView.builder(
              itemCount: articles.length,
              itemBuilder: (_, index) {
                final article = articles[index];
                return _buildArticleItem(article);
              },
            ),
          );
        },
      ),
    );
  }

  _buildArticleItem(Article article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => detailPage(article: article),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ..._img(article),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._title(article),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ..._avatar(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _author(article),
                        ),
                        const SizedBox(width: 8),
                        ..._date(article),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _title(Article article) {
    return [
      Text(
        article.title ?? 'No title',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }

  _author(Article article) {
    return Container(
      child: Text(
        article.author ?? 'Unknown',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  _avatar() {
    return [
      CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600], size: 16),
      ),
    ];
  }

  _date(Article article) {
    return [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              ThaiDateUtils.formatThaiDate(article.publishedAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  _img(Article article) {
    return [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: (article.urlToImage != null && article.urlToImage!.isNotEmpty)
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.fromSize(
            // size: const Size.fromRadius(144),
            child: Image.network(
              article.urlToImage!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image,
                      color: Colors.grey[600],
                      size: 50,
                    ),
                  ),
            ),
          ),
        )
            : Icon(Icons.image, color: Colors.grey[600]),
      ),
    ];
  }
}
