import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/cart_screen.dart';
import 'package:mask_store/ui/main/customer_support_screen.dart';
import 'package:mask_store/ui/main/favorites_screen.dart';
import 'package:mask_store/ui/main/home_screen.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:mask_store/ui/setting/settings_screen.dart';
import 'package:provider/provider.dart';
import 'di/di_setup.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
      builder: (context, state) => const ContactUsScreen(),
    ),
    GoRoute(
      path: '/favoritesScreen',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/settingsScreen',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/cartScreen',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/customerSupportScreen',
      builder: (context, state) => const CustomerSupportScreen(),
    ),
  ],
);



