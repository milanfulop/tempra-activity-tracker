import 'package:flutter/material.dart';
import '../../../../core/config.dart';
import 'package:go_router/go_router.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    await supabase.auth.getSessionFromUrl(Uri.parse(Uri.base.toString()));
    
    final session = supabase.auth.currentSession;
    print("Session after callback: $session");
    
    if (mounted) {
      if (session != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}