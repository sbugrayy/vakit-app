// Uygulama içi sayfa yönlendirme yapılandırması.

import 'package:go_router/go_router.dart';
import 'package:vakit/location/view/location_picker_page.dart';
import 'package:vakit/prayer_times/view/home_page.dart';

final GoRouter appRouter = createAppRouter();

GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/konum',
        builder: (context, state) => const LocationPickerPage(),
      ),
    ],
  );
}
