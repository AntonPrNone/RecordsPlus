// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, prefer_const_constructors, file_names, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:records_plus/Services/UserService.dart';

class StatisticPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Фоновый цвет страницы,
      appBar: AppBar(
        title: Text('Статистика'),
        backgroundColor: Color.fromARGB(255, 25, 25, 25),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<int>(
                future: UserService().getRecordCount(),
                builder: (context, snapshot) {
                  final recordCount = snapshot.data ?? 0;
                  return StatisticWidget(
                    title: 'Количество записей:',
                    value: recordCount.toString(),
                  );
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<double>(
                future: UserService().getAverageTitleLength(),
                builder: (context, snapshot) {
                  final averageTitleLength = snapshot.data ?? 0.0;
                  return StatisticWidget(
                    title: 'Средняя длина заголовка:',
                    value: averageTitleLength.toStringAsFixed(2),
                  );
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<double>(
                future: UserService().getAverageSubtitleLength(),
                builder: (context, snapshot) {
                  final averageSubtitleLength = snapshot.data ?? 0.0;
                  return StatisticWidget(
                    title: 'Средняя длина подзаголовка:',
                    value: averageSubtitleLength.toStringAsFixed(2),
                  );
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, int>>(
                future: UserService().getKeywordCounts(),
                builder: (context, snapshot) {
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildErrorWidget(dynamic error) {
    return Text(
      'Ошибка: $error',
      style: TextStyle(fontSize: 18, color: Colors.white),
    );
  }
}

// Остальной код остается без изменений

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
            fontSize: 16, // Уменьшенный размер текста
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
            fontSize: 22, // Уменьшенный размер текста
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
            fontSize: 16, // Уменьшенный размер текста
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

              final parts = keyword.split(' ');
              final word = parts[0];
              final rest = parts.sublist(1).join(' ');

              return Row(
                children: [
                  Text(
                    word,
                    style: TextStyle(
                      fontSize: 14, // Уменьшенный размер текста
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
                      fontSize: 14, // Уменьшенный размер текста
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
