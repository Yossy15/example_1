import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/riverpod/provider_page.dart';
import 'package:yossy_test/src/utils/date_utils.dart';

class detailPage extends ConsumerStatefulWidget {
  final Article article;

  const detailPage({super.key, required this.article});

  @override
  ConsumerState<detailPage> createState() => _detailPageState();
}

class _detailPageState extends ConsumerState<detailPage> {
  late RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    ref.refresh(newsProvider);
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Article Details'),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._title(),
              ..._imageTitle(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._sumary(),
                    const SizedBox(height: 24),
                    ..._fullArticle(),
                    const SizedBox(height: 24),
                    ..._source(),
                    const SizedBox(height: 16),
                    ..._articleName(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _title() {
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.article.title ?? 'No title',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  _imageTitle() {
    return [
      if (widget.article.urlToImage != null && widget.article.urlToImage!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox.fromSize(
              // size: const Size.fromRadius(144),
              child: Image.network(
                widget.article.urlToImage!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => Container(
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
          ),
        ),
    ];
  }

  _sumary() {
    return [
      if (widget.article.description != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.article.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
    ];
  }

  _fullArticle() {
    return [
      if (widget.article.content != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full Article',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.article.content!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
    ];
  }

  _source() {
    return [
      if (widget.article.source != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Source',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.article.source!.name ?? 'Unknown Source',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
    ];
  }

  _articleName() {
    return [
      Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.article.author ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ThaiDateUtils.formatThaiDate(widget.article.publishedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}
