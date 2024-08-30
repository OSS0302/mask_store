import 'package:get_it/get_it.dart';
import 'package:mask_store/data/repository/mask_store_repository_impl.dart';
import 'package:mask_store/data/repository/my_location_repository.dart';
import 'package:mask_store/data/repository/my_location_repository_impl.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';

import '../data/repository/mask_store_repository.dart';

final getIt = GetIt.instance;

void diSetup() {
  getIt.registerSingleton<MaskStoreRepository>(MaskStoreRepositoryImpl());
  getIt.registerSingleton<MyLocationRepository>(MyLocationRepositoryImpl());

  getIt.registerFactory<MaskStoreViewModel>(
          () => MaskStoreViewModel(maskStoreRepository: getIt<MaskStoreRepository>(), myLocationRepository: getIt<MyLocationRepository>()));
}