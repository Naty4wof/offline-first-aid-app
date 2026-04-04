import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Data Layer
import 'package:offline_first_aid_app/features/guides/data/datasources/guide_local_datasource.dart';
import 'package:offline_first_aid_app/features/guides/data/repositories/guide_repository_impl.dart';

// BLoC
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';

// REAL UI
import 'package:offline_first_aid_app/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dataSource = GuideLocalDataSource();
  final repository = GuideRepositoryImpl(dataSource);

  runApp(
    BlocProvider(
      create: (_) => GuideBloc(repository),
      child: const MyApp(),
    ),
  );
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
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
      ),
      home: const HomeScreen(),
    );
  }
}