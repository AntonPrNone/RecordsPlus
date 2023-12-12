import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:records_plus/AppState.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'Screens/AuthPage.dart';
import 'Screens/HomePage.dart';

void main() async {
  await initializeDateFormatting('ru', null);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final backgroundImage = prefs.getString('backgroundImage');

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(backgroundImage: backgroundImage),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      title: 'MessApp',
      debugShowCheckedModeBanner: false,
      home: (FirebaseAuth.instance.currentUser == null)
          ? const AuthPage()
          : HomePage(),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
