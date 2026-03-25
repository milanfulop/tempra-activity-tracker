import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hi from Home'),
            TextButton(
              onPressed: () => context.go('/statistics'),
              child: const Text('Go to Statistics'),
            ),
          ],
        ),
      ),
    );
  }
}