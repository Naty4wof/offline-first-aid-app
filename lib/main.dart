import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';

// Data Layer
import 'package:offline_first_aid_app/features/guides/data/datasources/guide_local_datasource.dart';
import 'package:offline_first_aid_app/features/guides/data/repositories/guide_repository_impl.dart';
import 'package:offline_first_aid_app/features/hospitals/data/repositories/hospital_repository_impl.dart';
import 'package:offline_first_aid_app/core/services/map_download_service.dart';

// BLoC
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/hospitals/presentation/bloc/hospital_bloc.dart';

// REAL UI
import 'package:offline_first_aid_app/ui/screens/home_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Make status bar icons/text dark and consistent across all pages
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    await Hive.initFlutter();
    // initialize Hive boxes used by the app
    await StorageService.instance.init();

    // Mock map download on first run
    final mapService = MapDownloadService();
    await mapService.downloadMapTiles();

    final dataSource = GuideLocalDataSource();
    final guideRepository = GuideRepositoryImpl(dataSource);
    final hospitalRepository = HospitalRepositoryImpl();

    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => GuideBloc(guideRepository)),
          BlocProvider(create: (_) => HospitalBloc(hospitalRepository)),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stacktrace) {
    debugPrint('Critical Error during app start: $e');
    debugPrint(stacktrace.toString());
    // Fallback app to show error if possible
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('App failed to start: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'የመጀመሪያ እርዳታ አማካሪ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE14949),
          secondary: Color(0xFF2E9B59),
          surface: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          foregroundColor: Color(0xFF132125),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
      ),
      home: const HomeScreen(),
    );
  }
}
