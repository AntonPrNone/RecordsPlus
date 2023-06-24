import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'Screens/AuthPage.dart';
import 'Screens/HomePage.dart';

void main() async {
  await initializeDateFormatting('ru', null);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
