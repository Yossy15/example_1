import 'dart:math';

import 'package:dio/dio.dart';
import 'package:yossy_test/src/models/news_model.dart';
import 'package:yossy_test/src/config/config.dart' as config;

class ApiService {
  final Dio _dio = Dio();

  Future<NewsResponse> fetchNews() async {
    final response = await _dio.get(config.url);
      if (response.statusCode == 200) {
        // log((response.data));
        return NewsResponse.fromJson(response.data);
      } else {
        throw Exception('Fail');
      }
  }
}