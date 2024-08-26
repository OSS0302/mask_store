import 'package:flutter/material.dart';
import 'package:mask_store/data/repository/mock_mask_store_repository.dart';
import 'package:mask_store/data/repository/mock_my_location_repository.dart';
import 'package:mask_store/ui/main/mask_store_screen.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';

void main() {
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
      home: MaskStoreScreen(
        maskStoreViewModel: MaskStoreViewModel(
            maskStoreRepository: MockMaskStoreRepository(),
            myLocationRepository: MockMyLocationRepository()),
      ),
    );
  }
}
