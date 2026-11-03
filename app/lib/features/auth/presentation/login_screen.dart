import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Login',
      links: [PlaceholderLink('Sign in', '/invoices', replace: true)],
    );
  }
}
