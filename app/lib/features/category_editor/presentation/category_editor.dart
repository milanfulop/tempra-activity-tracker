import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryEditorPage extends StatelessWidget {
  const CategoryEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category editor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('TODO: implement category editor'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

