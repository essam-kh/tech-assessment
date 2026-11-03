import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Settings',
      links: [PlaceholderLink('Log out', '/login', replace: true)],
    );
  }
}
