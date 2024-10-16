import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/favorites_screen.dart';
import 'package:mask_store/ui/main/home_screen.dart';
import 'package:mask_store/ui/main/main_screen.dart';
import 'package:mask_store/ui/main/map_view_screen.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:mask_store/ui/setting/settings_screen.dart';
import 'package:provider/provider.dart';

import 'di/di_setup.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => getIt<MaskStoreViewModel>(),
        child: const HomeScreen(),
      ),
    ),

    GoRoute(
      path: '/maskStoreScreen',
      builder: (context, state) => const MaskStoreScreen(),
    ),
    GoRoute(
      path: '/favoritesScreen', // 추가된 부분
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/settingsScreen',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);



