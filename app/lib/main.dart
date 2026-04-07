import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'features/home/presentation/screens/home.dart';
import 'features/category_editor/presentation/screens/category_editor.dart';
import 'shared/provider/category_provider.dart';
import 'features/statistics/presentation/screens/statistics.dart';
import 'features/profile/presentation/screens/profile_page.dart';
import 'features/statistics/models/statistics_models.dart';
import 'features/statistics/statistics_details/presentation/screens/statistics_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './features/auth/presentation/screens/auth.dart';
import 'dart:async';
import './core/config.dart';
import './shared/main_scaffold.dart';

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

// ─── Token validation helper ──────────────────────────────────────────────────

bool _isTokenValid() {
  final session = supabase.auth.currentSession;
  if (session == null) return false;

  // expiresAt is in seconds since epoch
  final expiresAt = session.expiresAt;
  if (expiresAt == null) return false;

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return expiresAt > now;
}

// ─── Router ───────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/home',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) async {
    final isOnAuth = state.matchedLocation == '/auth';

    // No session at all
    if (supabase.auth.currentSession == null) {
      return isOnAuth ? null : '/auth';
    }

    // Session exists but token is expired — try to refresh first
    if (!_isTokenValid()) {
      try {
        await supabase.auth.refreshSession();
        // Refresh succeeded, token is valid now
        if (isOnAuth) return '/home';
        return null;
      } catch (_) {
        // Refresh failed — sign out and redirect to auth
        await supabase.auth.signOut();
        return '/auth';
      }
    }

    // Token is valid
    if (isOnAuth) return '/home';
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/statistics',
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
    GoRoute(
      path: '/statistics-details',
      builder: (context, state) => StatisticsDetailsScreen(
        stats: state.extra as StatsResponse?,
      ),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/category-editor',
      builder: (context, state) => const CategoryEditorPage(),
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
          navigationBarTheme: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.all(
              const IconThemeData(size: 32),
            ),
          ),
        ),
      ),
    );
  }
}