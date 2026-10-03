// Uygulama içi sayfa yönlendirme yapılandırması ve geçici ana sayfa.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = createAppRouter();

GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePlaceholderPage(),
      ),
    ],
  );
}

class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Vakit'),
      ),
    );
  }
}
