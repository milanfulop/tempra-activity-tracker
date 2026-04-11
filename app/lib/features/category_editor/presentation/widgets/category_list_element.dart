import 'package:flutter/material.dart';
import 'category_editor_panel.dart';

class CategoryListElement extends StatelessWidget {
  final String name;
  final Color color;
  final String categoryId;
  final bool isProductive;
  // Callbacks so CategoryEditorPage can update its own state
  final void Function(Map<String, dynamic> updated)? onEdited;
  final void Function()? onDelete;

  const CategoryListElement({
    Key? key,
    required this.name,
    required this.color,
    required this.categoryId,
    this.isProductive = false,
    this.onEdited,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(categoryId),
      background: _buildEditBackground(),
      secondaryBackground: _buildDeleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit — open panel, do NOT dismiss
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            builder: (_) => CategoryEditorPanel(
              categoryId: categoryId,
              initialName: name,
              initialColor: color,
              initialIsProductive: isProductive,
            ),
          );
          if (result != null) onEdited?.call(result);
          return false; // never dismiss on edit
        } else {
          // Delete — confirm then notify parent
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete category?'),
              content: Text('Delete "$name"? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onDelete?.call(); // parent calls API + removes from list
            return true;      // Dismissible animates the tile away
          }
          return false;
        }
      },
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (isProductive)
              const Icon(Icons.bolt, color: Colors.amber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEditBackground() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}