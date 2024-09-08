import 'package:flutter/material.dart';
import 'package:mask_store/data/repository/mask_store_repository_impl.dart';
import 'package:mask_store/data/repository/my_location_repository_impl.dart';
import 'package:mask_store/di/di_setup.dart';
import 'package:mask_store/routes.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';



void main() {
  diSetup();
  runApp(
    ChangeNotifierProvider(
      create: (_) => MaskStoreViewModel(
        maskStoreRepository: MaskStoreRepositoryImpl(),
        myLocationRepository: MyLocationRepositoryImpl(),
      ),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();
    return MaterialApp.router(
      routerConfig: router,
      title: 'Mask Store',
      theme: ThemeData.light(), // 라이트 모드 테마
      darkTheme: ThemeData.dark(), // 다크 모드 테마
      themeMode: maskStoreViewModel.isDarkMode
          ? ThemeMode.dark // 다크 모드 설정
          : ThemeMode.light, // 기본 라이트 모드
    );
  }
}
