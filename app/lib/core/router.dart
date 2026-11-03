import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../invoices/details_screen.dart';
import '../invoices/form_screen.dart';
import '../invoices/list_screen.dart';
import '../settings/settings_screen.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<bool> stream) {
    _sub = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<bool> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

String _safeReturnPath(String? from) {
  final isLocalPath =
      from != null && from.startsWith('/') && !from.startsWith('//');
  if (!isLocalPath || from.startsWith('/login')) return '/invoices';
  return from;
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final refresh = _AuthRefresh(auth.authChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!auth.isSignedIn) {
        if (atLogin) return null;
        return Uri(
          path: '/login',
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (!atLogin) return null;
      return _safeReturnPath(state.uri.queryParameters['from']);
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/invoices',
        builder: (_, _) => const InvoiceListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const InvoiceFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                InvoiceDetailsScreen(invoiceId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) =>
                    InvoiceFormScreen(invoiceId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});
