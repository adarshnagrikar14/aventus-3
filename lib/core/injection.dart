import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackathon/feature/food/product/logic/cubit/product_cubit.dart';
import 'package:hackathon/feature/food/product/data/repo/product_repository.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Scanner Controller
  getIt.registerFactory(
    () => MobileScannerController(
      formats: const [BarcodeFormat.all],
      detectionSpeed: DetectionSpeed.normal,
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepository());

  // Cubits
  getIt.registerFactory(() => ProductCubit(getIt()));
}
