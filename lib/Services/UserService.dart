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
    List<DocumentSnapshot> records = querySnapshot.docs;

    // Добавим поле isChecked со значением false в каждую запись, если его нет
    for (var record in records) {
      Map<String, dynamic> data = record.data() as Map<String, dynamic>;

      if (!data.containsKey('isChecked')) {
        record.reference.update({'isChecked': false});
      }
    }

    return records;
  }

  Future<void> addRecord(String title, String subtitle,
      {bool newActive = false}) async {
    final timestamp =
        DateTime.now().toUtc().add(const Duration(hours: 3)).millisecondsSinceEpoch;
    await usersCollection.doc(user?.uid).collection('Records').add({
      'Title': title,
      'Subtitle': subtitle,
      'Timestamp': timestamp,
      'isChecked':
          newActive, // Установка значения isChecked из параметра newActive
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
      'isChecked':
          newActive ?? false, // Обновление или установка значения isChecked
    });
  }

  Future<void> deleteRecordById(String recordId) async {
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .delete();
  }

  Future<void> updateCheckboxState(String recordId, bool newState) async {
    // Обновление состояния чекбокса в базе данных
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .update({'isChecked': newState});
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

  Future<String?> saveQuillContentToFirestore(
      String noteId, String quillContent) async {
    try {
      final userDocRef = usersCollection.doc(user?.uid);
      final noteDocRef = userDocRef.collection('Notes').doc(noteId);

      // Проверяем, существует ли документ с заданным идентификатором
      final noteSnapshot = await noteDocRef.get();

      if (noteSnapshot.exists) {
        // Если документ существует, обновляем его содержимое
        await noteDocRef.update({'content': quillContent});
      } else {
        // Если документ не существует, создаем новый документ с уникальным идентификатором
        final newNoteDocRef = userDocRef.collection('Notes').doc();
        await newNoteDocRef.set({'content': quillContent});

        // Возвращаем идентификатор нового документа
        return newNoteDocRef.id;
      }
      // Возвращаем идентификатор существующего документа
      return noteDocRef.id;
    } catch (error) {
      print('Error saving/updating Quill content to Firestore: $error');
      // В случае ошибки возвращаем null или другое значение, чтобы указать на неудачу
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> get quillContentStream {
    return usersCollection
        .doc(user?.uid)
        .collection('Notes')
        .snapshots()
        .map((querySnapshot) {
      // Преобразование списка документов в список содержимого и их идентификаторов
      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'content': doc['content'] as String,
        };
      }).toList();
    });
  }

  Future<void> deleteNoteFromFirestore(String noteId) async {
    try {
      await usersCollection
          .doc(user?.uid)
          .collection('Notes')
          .doc(noteId)
          .delete();
    } catch (error) {
      print('Error deleting note from Firestore: $error');
    }
  }
}
