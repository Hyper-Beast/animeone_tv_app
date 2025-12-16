import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化API客户端
  await ApiClient.initialize();

  runApp(const TvApp());
}

class TvApp extends StatelessWidget {
  const TvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeOne TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF4facfe),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
