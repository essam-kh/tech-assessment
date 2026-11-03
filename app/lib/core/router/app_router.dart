import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/invoices/presentation/create_invoice_screen.dart';
import '../../features/invoices/presentation/invoice_details_screen.dart';
import '../../features/invoices/presentation/invoice_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
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
