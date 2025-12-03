import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yossy_test/src/pages/home/home_page.dart';
import 'package:yossy_test/src/pages/search/search_page.dart';

class YossyApp extends ConsumerWidget {
  const YossyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/homePage',
  routes: <RouteBase>[
    GoRoute(
      name: 'homePage',
      path: '/homePage',
      builder: (context, state) => const homePage(),
    ),
    GoRoute(
      name: 'searchPage',
      path: '/searchPage',
      builder: (context, state) => const searchPage(),
    ),
    GoRoute(
      name: 'detailPage',
      path: '/detailPage',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('fail'),
        ),
      ),
    ),
  ],
);
