import 'package:flutter/material.dart';
import 'package:hackathon/core/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackathon/feature/splash/splash_screen.dart';
import 'package:hackathon/feature/food/product/logic/cubit/product_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize OpenFoodFacts
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'Health Companion',
    version: '1.0.0',
    system: 'Android',
  );

  await SharedPreferences.getInstance();
  await setupInjection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => getIt<ProductCubit>())],
      child: MaterialApp(
        title: 'Garbh',
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          textTheme: GoogleFonts.robotoTextTheme(),
          useMaterial3: true,
        ),
      ),
    );
  }
}
