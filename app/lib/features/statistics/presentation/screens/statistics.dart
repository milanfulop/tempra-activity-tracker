import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hi from Statistics'),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}