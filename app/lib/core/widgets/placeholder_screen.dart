import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaceholderLink {
  const PlaceholderLink(this.label, this.path, {this.replace = false});

  final String label;
  final String path;

  final bool replace;
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.links = const [],
  });

  final String title;
  final List<PlaceholderLink> links;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final link in links) ...[
            OutlinedButton(
              onPressed: () =>
                  link.replace ? context.go(link.path) : context.push(link.path),
              child: Text(link.label),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
