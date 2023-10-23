// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Users');
  final User? user = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot> getUserDocument() async {
    return await usersCollection.doc(user?.uid).get();
  }

  Future<List<DocumentSnapshot>> getAllRecords(
      {String? orderBy = 'Timestamp', bool reverseOrder = false}) async {
    Query query = usersCollection.doc(user?.uid).collection('Records');

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: reverseOrder);
    }

    QuerySnapshot querySnapshot = await query.get();
    return querySnapshot.docs;
  }

  Future<void> addRecord(String title, String subtitle) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await usersCollection.doc(user?.uid).collection('Records').add({
      'Title': title,
      'Subtitle': subtitle,
      'Timestamp': timestamp,
    });
  }

  Future<void> updateRecordById(String recordId,
      {String? newTitle, String? newSubtitle, bool? newActive}) async {
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .update({
      'Title': newTitle,
      'Subtitle': newSubtitle,
    });
  }

  Future<void> deleteRecordById(String recordId) async {
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .delete();
  }

  Future<int> getRecordCount() async {
    // Возвращает количество записей пользователя
    List<DocumentSnapshot> records = await getAllRecords();
    return records.length;
  }

  Future<double> getAverageTitleLength() async {
    // Возвращает среднюю длину заголовков записей пользователя
    List<DocumentSnapshot> records = await getAllRecords();
    if (records.isEmpty) {
      return 0.0;
    }

    double totalTitleLength = 0;
    for (DocumentSnapshot record in records) {
      String title = record['Title'] ?? '';
      totalTitleLength += title.length;
    }

    return totalTitleLength / records.length;
  }

  Future<double> getAverageSubtitleLength() async {
    // Возвращает среднюю длину подзаголовков записей пользователя
    List<DocumentSnapshot> records = await getAllRecords();
    if (records.isEmpty) {
      return 0.0;
    }

    double totalSubtitleLength = 0;
    for (DocumentSnapshot record in records) {
      String subtitle = record['Subtitle'] ?? '';
      totalSubtitleLength += subtitle.length;
    }

    return totalSubtitleLength / records.length;
  }

  Future<List<String>> getFrequentKeywords() async {
    // Возвращает наиболее часто используемые ключевые слова из заголовков и подзаголовков
    List<DocumentSnapshot> records = await getAllRecords();
    Map<String, int> keywordCountMap = {};

    for (DocumentSnapshot record in records) {
      // Рассматриваем как заголовок, так и подзаголовок
      String title = record['Title'] ?? '';
      String subtitle = record['Subtitle'] ?? '';

      // Объединяем заголовок и подзаголовок
      String combinedText = '$title $subtitle';

      // Разделяем объединенный текст на слова
      List<String> keywords = combinedText.split(' ');

      for (String keyword in keywords) {
        keywordCountMap[keyword] = (keywordCountMap[keyword] ?? 0) + 1;
      }
    }

    // Сортируем ключевые слова по частоте использования
    List<String> frequentKeywords = keywordCountMap.keys.toList();
    frequentKeywords
        .sort((a, b) => keywordCountMap[b]!.compareTo(keywordCountMap[a]!));

    // Ограничиваем список наиболее часто используемых ключевых слов, например, 10 словами
    if (frequentKeywords.length > 10) {
      frequentKeywords = frequentKeywords.sublist(0, 10);
    }

    return frequentKeywords;
  }

  Future<Map<String, int>> getKeywordCounts() async {
    List<DocumentSnapshot> records = await getAllRecords();
    Map<String, int> keywordCountMap = {};

    for (DocumentSnapshot record in records) {
      String title = record['Title'] ?? '';
      String subtitle = record['Subtitle'] ?? '';
      String combinedText = '$title $subtitle';
      List<String> keywords = combinedText.split(' ');

      for (String keyword in keywords) {
        keywordCountMap[keyword] = (keywordCountMap[keyword] ?? 0) + 1;
      }
    }

    return keywordCountMap;
  }
}
