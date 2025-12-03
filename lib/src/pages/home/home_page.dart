import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/pages/search/search_page.dart';
import 'package:yossy_test/src/pages/detail/detail_page.dart';
import 'package:yossy_test/src/riverpod/provider_page.dart';
import 'package:yossy_test/src/utils/date_utils.dart';

class homePage extends ConsumerStatefulWidget {
  const homePage({super.key});

  @override
  ConsumerState<homePage> createState() => _homePageState();
}

class _homePageState extends ConsumerState<homePage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsProvider);
    final selectedSource = ref.watch(selectedSourceAll);
    final filteredNewsState = ref.watch(filteredNewsProvider(selectedSource));
    final sourcesState = ref.watch(sourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 40),
        actions: [
          Container(
            // color: Colors.grey[300],
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.grey[300],
            ),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const searchPage()));
              },
            ),
          )
        ],
      ),
      body: newsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: ((error, stackTrace) => Text(error.toString())),
        data: (articles) {
          return filteredNewsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text(error.toString()),
            data: (filteredArticles) {
              return sourcesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Text(error.toString()),
                data: (sources) {
                  return SmartRefresher(
                    controller: _refreshController,
                    onRefresh: () {
                      ref.refresh(newsProvider);
                      _refreshController.refreshCompleted();
                    },
                    child: ListView(
                      children: [
                        ..._buildHeader(),
                        ..._buildImageScroll(filteredArticles),
                        const SizedBox(height: 16),
                        ..._buildFilter(sources, selectedSource),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredArticles.length,
                              itemBuilder: (context, index) {
                                final article = filteredArticles[index];
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            detailPage(article: article)),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        ..._buildImgAvatar(article),
                                        const SizedBox(width: 12),
                                        ..._bulidInfoNews(article),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  _buildHeader() {
    return [
      Padding(
        padding: EdgeInsets.only(left: 18, bottom: 12),
        child: Text("ข่าวล่าสุด",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
      ),
    ];
  }

  _buildFilter(List<String> sources, String selected) {
    return [
      SizedBox(
        height: 50,
        child: ListView.builder(
          padding: const EdgeInsets.all(2),
          scrollDirection: Axis.horizontal,
          itemCount: sources.length,
          itemBuilder: (context, index) {
            final src = sources[index];
            return Padding(
              padding: const EdgeInsets.all(4),
              child: FilterChip(
                selected: selected == src,
                label: Text(src == 'all' ? 'ทั้งหมด' : src),
                onSelected: (_) {
                  ref.read(selectedSourceAll.notifier).state = src;
                },
                selectedColor: Colors.indigoAccent,
              ),
            );
          },
        ),
      ),
    ];
  }

  _buildImageScroll(List filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    return [
      SizedBox(
        height: 200,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: filtered.length > 4 ? 4 : filtered.length,
          itemBuilder: (context, index) {
            final article = filtered[index];
            return _newsImageCard(article);
          },
        ),
      ),
    ];
  }

  _newsImageCard(Article article) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              Image.network(
                article.urlToImage!,
                width: 300,
                fit: BoxFit.cover,
                errorBuilder: (
                  _,
                  __,
                  ___,
                ) =>
                    Container(color: Colors.grey[300]),
              )
            else
              Container(color: Colors.grey[300]),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  article.title ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildImgAvatar(Article article) {
    return [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: (article.urlToImage != null && article.urlToImage!.isNotEmpty)
            ? Image.network(article.urlToImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                      Icons.image,
                      color: Colors.grey[600],
                    ))
            : Icon(Icons.image, color: Colors.grey[600]),
      ),
    ];
  }

  _bulidInfoNews(dynamic article) {
    return [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(article.author ?? 'Unknown',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(
                  ThaiDateUtils.formatThaiDate(article.publishedAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            )
          ],
        ),
      )
    ];
  }
}
