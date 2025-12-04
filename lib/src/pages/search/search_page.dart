import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/pages/detail/detail_page.dart';
import 'package:yossy_test/src/riverpod/provider_page.dart';
import 'package:yossy_test/src/utils/date_utils.dart';

class searchPage extends ConsumerStatefulWidget {
  const searchPage({super.key});

  @override
  ConsumerState<searchPage> createState() => _searchPageState();
}

class _searchPageState extends ConsumerState<searchPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController controller = TextEditingController();

  void _onRefresh() async {
    await ref.read(newsStateProvider.notifier).refreshNews();
    _refreshController.loadComplete();
  }

  void _onLoading() async {
    final hasMore = await ref.read(newsStateProvider).hasMore;
    if (hasMore) {
      await ref.read(newsStateProvider.notifier).loadMore();
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyword = ref.read(searchKeywordProvider);
      controller.text = keyword;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsStateProvider);
    final keyword = state.searchKeyword;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
            controller.clear();
            ref.read(newsStateProvider.notifier).clearSearch();
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
                              ref.read(newsStateProvider.notifier).clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    hintText: "ค้นหา",
                  ),
                  onChanged: (value) {
                    ref.read(newsStateProvider.notifier).performSearch(value);
                  },
                ),
              ),
            )
          ],
        ),
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
                child: Text('ลองใหม่', style: GoogleFonts.anuphan(),),
              ),
            ],
          ),
        ),
        data: (articles) {
          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            enablePullDown: true,
            enablePullUp: true,
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
            child: articles.isEmpty
                ? Center(
                    child: Text(
                      'ไม่พบผลการค้นหา',
                      style: GoogleFonts.anuphan(textStyle: const TextStyle(fontSize: 16, color: Colors.grey),),
                    ),
                  )
                : ListView.builder(
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

//------------------------------------------------------------------------------

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
              _img(article),
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
        style: GoogleFonts.anuphan(textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }

  _author(Article article) {
    return Container(
      child: Text(
        article.author ?? 'Unknown',
        style: GoogleFonts.anuphan(textStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),),
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
              style: GoogleFonts.anuphan(textStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),),
            ),
          ],
        ),
      ),
    ];
  }

  _img(Article article) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: (article.urlToImage != null && article.urlToImage!.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article.urlToImage!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image,
                    color: Colors.grey[600],
                    size: 40,
                  ),
                ),
              ),
            )
          : Icon(Icons.image, color: Colors.grey[600], size: 40),
    );
  }
}
