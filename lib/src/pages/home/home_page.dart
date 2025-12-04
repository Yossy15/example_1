import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/pages/search/search_page.dart';
import 'package:yossy_test/src/pages/detail/detail_page.dart';
import 'package:yossy_test/src/riverpod/provider_page.dart';
import 'package:yossy_test/src/utils/date_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class homePage extends ConsumerStatefulWidget {
  const homePage({super.key});

  @override
  ConsumerState<homePage> createState() => _homePageState();
}

class _homePageState extends ConsumerState<homePage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    await ref.read(newsStateProvider.notifier).refreshNews();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    final hasMore = await ref.read(newsStateProvider).hasMore;
    if (hasMore) { await ref.read(newsStateProvider.notifier).loadMore(); _refreshController.loadComplete(); }
    else { _refreshController.loadNoData(); }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsStateProvider);
    final sources = state.sources;
    final selectedSource = state.selectSource;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/logo.png', height: 40),
          ],
        ),
        actions: [
          Container(
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
      body: state.displayNews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text('เกิดข้อผิดพลาด: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(newsStateProvider.notifier).refreshNews(),
                child: Text('ลองใหม่', style: GoogleFonts.anuphan()),
              ),
            ],
          ),
        ),
        data: (filteredArticles) {
          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            enablePullUp: true,
            enablePullDown: true,
            header: const MaterialClassicHeader(),

            footer: CustomFooter(
              builder: (BuildContext context, LoadStatus? mode) {
                Widget body;
                if (mode == LoadStatus.idle) { body = Text("pull up load", style: GoogleFonts.anuphan()); }
                else if (mode == LoadStatus.loading) { body = const CupertinoActivityIndicator(); }
                else if (mode == LoadStatus.failed) { body = Text("Load Failed!Click retry!", style: GoogleFonts.anuphan()); }
                else if (mode == LoadStatus.canLoading) { body = Text("release to load more", style: GoogleFonts.anuphan()); }
                else { body = Text("No more Data", style: GoogleFonts.anuphan()); }
                return SizedBox(
                  height: 55.0,
                  child: Center(child: body)
                );
              },
            ),
            child: ListView(
              children: [
                ..._buildHeader(),
                _buildImageScroll(filteredArticles),
                const SizedBox(height: 16),
                _buildFilter(sources, selectedSource),
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
                                builder: (_) => detailPage(article: article)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _buildImgAvatar(article),
                                const SizedBox(width: 12),
                                _bulidInfoNews(article),
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
      ),
    );
  }

//------------------------------------------------------------------------------

  _buildHeader() {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 12),
        child: Text(
          "ข่าวล่าสุด",
          style: GoogleFonts.anuphan(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];
  }

  _buildFilter(List<String> sources, String selected) {
    return SizedBox(
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
              label: Text(src == 'all' ? 'ทั้งหมด' : src , style: GoogleFonts.anuphan(),),
              onSelected: (_) {
                ref.read(newsStateProvider.notifier).selectSource(src);
              },
              selectedColor: Colors.indigoAccent,
            ),
          );
        },
      ),
    );
  }

  _buildImageScroll(List filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    return SizedBox(
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
    );
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
                  style: GoogleFonts.anuphan(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildImgAvatar(Article article) {
    return Container(
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
    );
  }

  _bulidInfoNews(dynamic article) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
        style: GoogleFonts.anuphan(
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),),
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
                    style: GoogleFonts.anuphan( textStyle: const TextStyle(fontSize: 12)),
                    overflow: TextOverflow.ellipsis)
              ),
              const SizedBox(width: 8),
              Text(
                ThaiDateUtils.formatThaiDate(article.publishedAt),
                style: GoogleFonts.anuphan(textStyle: const TextStyle(fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }
}
