// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, prefer_const_constructors, file_names, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_plus/Services/UserService.dart';

class StatisticPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email пользователя: ${FirebaseAuth.instance.currentUser!.email}', // Отображение email пользователя
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Дата регистрации: ${FirebaseAuth.instance.currentUser?.metadata.creationTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(FirebaseAuth.instance.currentUser!.metadata.creationTime!.toLocal()) : "Неизвестно"}', // Отображение даты регистрации
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Количество записей
          FutureBuilder<int>(
            future: UserService().getRecordCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Ошибка: ${snapshot.error}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                );
              } else {
                final recordCount = snapshot.data ?? 0;
                return StatisticWidget(
                  title: 'Количество записей:',
                  value: recordCount.toString(),
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // Средняя длина заголовка
          FutureBuilder<double>(
            future: UserService().getAverageTitleLength(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Ошибка: ${snapshot.error}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                );
              } else {
                final averageTitleLength = snapshot.data ?? 0.0;
                return StatisticWidget(
                  title: 'Средняя длина заголовка:',
                  value: averageTitleLength.toStringAsFixed(2),
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // Средняя длина подзаголовка
          FutureBuilder<double>(
            future: UserService().getAverageSubtitleLength(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Ошибка: ${snapshot.error}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                );
              } else {
                final averageSubtitleLength = snapshot.data ?? 0.0;
                return StatisticWidget(
                  title: 'Средняя длина подзаголовка:',
                  value: averageSubtitleLength.toStringAsFixed(2),
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // Часто используемые ключевые слова
          FutureBuilder<Map<String, int>>(
            future: UserService().getKeywordCounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Ошибка: ${snapshot.error}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                );
              } else {
                final keywordCountMap = snapshot.data ?? {};
                final frequentKeywords = keywordCountMap.keys.toList();
                frequentKeywords.sort((a, b) =>
                    keywordCountMap[b]!.compareTo(keywordCountMap[a]!));
                if (frequentKeywords.isNotEmpty) {
                  return StatisticListWidget(
                    title: 'Часто используемые ключевые слова:',
                    keywords: frequentKeywords,
                    keywordCountMap: keywordCountMap,
                  );
                } else {
                  return const Text('Нет данных',
                      style: TextStyle(fontSize: 18, color: Colors.white));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class StatisticWidget extends StatelessWidget {
  final String title;
  final String value;

  StatisticWidget({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black,
                blurRadius: 3,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black,
                blurRadius: 3,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatisticListWidget extends StatelessWidget {
  final String title;
  final List<String> keywords;
  final Map<String, int> keywordCountMap;

  StatisticListWidget(
      {required this.title,
      required this.keywords,
      required this.keywordCountMap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black,
                blurRadius: 3,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        if (keywords.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: keywords.map((keyword) {
              final count = keywordCountMap[keyword] ?? 0;

              // Разделяем текст на две части: слово и число
              final parts = keyword.split(' ');
              final word = parts[0]; // Слово
              final rest =
                  parts.sublist(1).join(' '); // Остальной текст (число)

              return Row(
                children: [
                  Text(
                    word,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      shadows: <Shadow>[
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ' $rest ($count)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      shadows: <Shadow>[
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}
