import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'features/home/presentation/screens/home.dart';
import 'features/category_editor/presentation/screens/category_editor.dart';
import 'shared/provider/category_provider.dart';
import 'features/statistics/presentation/screens/statistics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './features/auth/presentation/screens/auth.dart';
import 'dart:async';
import './core/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env', isOptional: true);

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is missing from .env');
  assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is missing from .env');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  supabase.auth.onAuthStateChange.listen((data) {
    print('AUTH STATE: ${data.event} SESSION: ${data.session}');
  });
  runApp(const MyApp());
}

// ─── Router ───────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/home',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) {
    final isAuthenticated = supabase.auth.currentSession != null;
    final isOnAuth = state.matchedLocation == '/auth';

    if (!isAuthenticated && !isOnAuth) return '/auth';
    if (isAuthenticated && isOnAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/category-editor',
      builder: (context, state) => const CategoryEditorPage(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
  ],
);

// ─── Refresh helper ───────────────────────────────────────────────────────────
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryProvider(),
      child: MaterialApp.router(
        routerConfig: _router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
      ),
    );
  }
}