// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, use_build_context_synchronously, library_private_types_in_public_api, sort_child_properties_last

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:records_plus/Model/AppState.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
        backgroundColor:
            const Color.fromARGB(255, 25, 25, 25),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[900], // Фоновый цвет страницы
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Фон приложения',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // Цвет текста
              ),
              SizedBox(height: 16),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: appState.backgroundImage != null &&
                            File(appState.backgroundImage!.path).existsSync()
                        ? Image.file(
                            appState.backgroundImage!,
                            height: 200,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/imgs/bg2.jpg',
                            height: 200,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                  );
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Выравнивание по центру
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(
                      'Выбрать изображение',
                      style:
                          TextStyle(color: Colors.white), // Цвет текста кнопки
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 99, 0,
                          156), // Цвет фона кнопки "Выбрать изображение"
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _resetImage,
                    child: Text(
                      'Сброс',
                      style: TextStyle(
                          color: Colors.white), // Цвет текста кнопки "Сброс"
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                          255, 99, 0, 156), // Цвет фона кнопки "Сброс"
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });

      final appState = Provider.of<AppState>(context, listen: false);
      appState.setBackgroundImage(_selectedImage);

      // Сохранение пути к изображению в SharedPreferences
      saveImageToSharedPreferences(_selectedImage!.path);
    }
  }

  Future<void> _resetImage() async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setBackgroundImage(null);

    // Сброс пути к изображению в SharedPreferences
    saveImageToSharedPreferences(null);
  }

  // Метод для сохранения пути к изображению
  Future<void> saveImageToSharedPreferences(String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('backgroundImage',
        imagePath ?? ''); // Если imagePath null, используйте пустую строку
  }
}
