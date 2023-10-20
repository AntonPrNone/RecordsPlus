// ignore_for_file: file_names, use_build_context_synchronously
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../RandomPointsPainter.dart';
import '/Services/AuthService.dart';
import 'HomePage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String email = '';
  String password = '';
  bool obscurePassword = true;
  bool showLogin = true;
  static const colorizeColors = [
    Colors.purple,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];
  static const colorizeTextStyle = TextStyle(
    shadows: [
      Shadow(
        color: Colors.black,
        blurRadius: 5,
        offset: Offset(-3, 3),
      ),
    ],
    fontSize: 64.0,
    fontFamily: 'Horizon',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          const RandomPointsPainter(
            color: Color.fromARGB(255, 119, 0, 255),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: logo(),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (showLogin) ...[
                  form(
                      'Вход',
                      () async => authButtonAction(
                          await authService.signInWithEmailAndPassword(
                              emailController.text.trim(),
                              passwordController.text.trim()))),
                  buildSwitchText('Регистрация'),
                ] else ...[
                  form(
                      'Регистрация',
                      () async => authButtonAction(
                          await authService.registerWithEmailAndPassword(
                              emailController.text.trim(),
                              passwordController.text.trim()))),
                  buildSwitchText('Вход'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget logo() {
    // Лого
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: SizedBox(
          child: AnimatedTextKit(animatedTexts: [
            ColorizeAnimatedText(
              'Records',
              textStyle: colorizeTextStyle,
              colors: colorizeColors,
            ),
            ColorizeAnimatedText(
              'Plus',
              textStyle: colorizeTextStyle,
              colors: colorizeColors,
            ),
            ColorizeAnimatedText('Records+',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
                speed: const Duration(milliseconds: 500)),
          ], isRepeatingAnimation: false),
        ),
      ),
    );
  }

  Widget form(String label, void Function() func) {
    // Форма
    return SizedBox(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: inputLogin(
                  const Icon(
                    Icons.email,
                    color: Colors.blue,
                  ),
                  'Email',
                  emailController,
                  false),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: inputLogin(
                  const Icon(
                    Icons.lock,
                    color: Colors.red,
                  ),
                  'Password',
                  passwordController,
                  true),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20, left: 20),
              child: SizedBox(
                height: 50,
                width: MediaQuery.of(context).size.width,
                child: button(label, func),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSwitchText(String text) {
    // Смена способа авторизации
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            showLogin = !showLogin;
          });
        },
        child: Text(
          text,
          style: const TextStyle(
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
                offset: Offset(-2, 2),
              ),
            ],
            fontSize: 16,
            color: Colors.white,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

Widget inputLogin(Icon icon, String hint, TextEditingController controller, bool obscure) {
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 20),
    child: TextFormField(
      controller: controller,
      obscureText: obscure && obscurePassword,
      style: const TextStyle(fontSize: 20, color: Colors.white),
      decoration: InputDecoration(
        hintStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white30),
        hintText: hint,
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 3)),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54, width: 1)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: icon,
          ),
        ),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              )
            : null,
      ),
      onFieldSubmitted: (value) async {
        if (value.isNotEmpty) {
          // Выполнить проверку данных, если поле не пустое
          authButtonAction(await authService.signInWithEmailAndPassword(
            emailController.text.trim(),
            passwordController.text.trim(),
          ));
        }
      },
    ),
  );
}


  Widget button(String text, void Function() func) {
    // Кнопка авторизации
    return TextButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        overlayColor: MaterialStateProperty.all<Color?>(
          Colors.white.withOpacity(0.5),
        ),
        backgroundColor: MaterialStateProperty.all<Color>(
          const Color.fromARGB(255, 84, 0, 133),
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black; // Цвет текста при нажатии
            }
            return Colors.white; // Цвет текста по умолчанию
          },
        ),
      ),
      onPressed: func,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Future<bool?> toast(String msg, Color color) {
    // Уведомление об ошибке
    return Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: color,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<void> authButtonAction(User? userS) async {
    // Обработка нажатия на кнопку авторизации
    User? user = userS;
    email = emailController.text;
    password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      toast('Поля(е) пустые(ое)', Colors.grey);
      return;
    }

    if (user == null) {
      toast(
          'Не удаётся авторизоваться, проверьте корректность/валидность email/пароля',
          Colors.red);
    } else {
      emailController.clear();
      passwordController.clear();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.ease;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }
}
