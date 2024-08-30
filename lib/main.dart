import 'package:flutter/material.dart';
import 'package:mask_store/di/di_setup.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';

import 'data/repository/mask_store_repository_impl.dart';
import 'data/repository/my_location_repository_impl.dart';

void main() {
  diSetup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) => MaskStoreViewModel(
            maskStoreRepository: MaskStoreRepositoryImpl(),
            myLocationRepository: MyLocationRepositoryImpl()),

        child: MaskStoreScreen(),
      ),
    );
  }
}
