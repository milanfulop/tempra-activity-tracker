import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/presentation/screen/home.dart';
import 'features/statistics/presentation/screen/statistics.dart';
void main() {
  runApp(const MyApp());
}

// ─── Router ───────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
  ],
);

// ─── App ──────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}