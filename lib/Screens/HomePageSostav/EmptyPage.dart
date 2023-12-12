// ignore_for_file: use_key_in_widget_constructors, file_names

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class EmptyPage extends StatelessWidget {
  final String firstText;

  EmptyPage({required this.firstText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Добавьте $firstText с помощью кнопки:',
                textStyle: const TextStyle(color: Colors.white),
                speed: const Duration(milliseconds: 50),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.add,
            size: 50.0,
            color: Color.fromARGB(255, 111, 0, 255),
          ),
          SizedBox(
            height: 120,
            child: AnimatedTextKit(
              animatedTexts: [
                FadeAnimatedText(
                  '↓',
                  textStyle: const TextStyle(fontSize: 92, color: Colors.white),
                ),
              ],
              repeatForever: true,
              pause: const Duration(milliseconds: 200),
            ),
          )
        ],
      ),
    );
  }
}

