import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/invoices/presentation/create_invoice_screen.dart';
import '../../features/invoices/presentation/invoice_details_screen.dart';
import '../../features/invoices/presentation/invoice_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

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

final routerProvider =Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
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
          GoRoute(path: 'new', builder: (_, _) => const CreateInvoiceScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                InvoiceDetailsScreen(invoiceId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});
