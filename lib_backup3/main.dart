import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/reward_service.dart';
import 'services/locale_service.dart';
import 'services/progress_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RewardService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
        ChangeNotifierProvider(create: (_) => ProgressService()),
      ],
      child: const ZukeiPuzzleApp(),
    ),
  );
}

class ZukeiPuzzleApp extends StatelessWidget {
  const ZukeiPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'かんがえるん',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
