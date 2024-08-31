import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';

import 'di/di_setup.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => getIt<MaskStoreViewModel>(),
        child: MaskStoreScreen(),
      ),
    ),
  ],
);
