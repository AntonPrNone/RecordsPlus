// ignore_for_file: file_names
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Users');
  final User? user = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot> getUserDocument() async {
    return await usersCollection.doc(user?.uid).get();
  }

  Future<List<DocumentSnapshot>> getAllRecords({
    String? orderBy = 'Timestamp',
    bool reverseOrder = false,
  }) async {
    Query query = usersCollection.doc(user?.uid).collection('Records');

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: reverseOrder);
    }

    QuerySnapshot querySnapshot = await query.get();
    List<DocumentSnapshot> records = querySnapshot.docs;

    // Добавим поле isChecked со значением false, цвет по умолчанию и статус удаленности в каждую запись, если его нет
    for (var record in records) {
      Map<String, dynamic> data = record.data() as Map<String, dynamic>;

      if (!data.containsKey('isChecked')) {
        record.reference.update({'isChecked': false});
      }

      // Добавим цвет по умолчанию, если его нет
      if (!data.containsKey('Color')) {
        record.reference
            .update({'Color': const Color.fromARGB(255, 111, 0, 255).value});
      }

      // Добавим статус удаленности со значением false, если его нет
      if (!data.containsKey('isDeleted')) {
        record.reference.update({'isDeleted': false});
      }
    }

    return records;
  }

  Stream<List<DocumentSnapshot>> getAllRecordsStream({
    SortType currentSortType = SortType.title,
    bool currentAscending = true,
  }) {
    Query query = usersCollection.doc(user?.uid).collection('Records');

    String orderByField = _getOrderByField(currentSortType);

    if (orderByField.isNotEmpty) {
      query = query.orderBy(orderByField, descending: !currentAscending);
    }

    return query.snapshots().map((querySnapshot) {
      List<DocumentSnapshot> records = querySnapshot.docs;

      // Добавим поле isChecked со значением false, цвет по умолчанию и статус удаленности в каждую запись, если его нет
      for (var record in records) {
        Map<String, dynamic> data = record.data() as Map<String, dynamic>;

        if (!data.containsKey('isChecked')) {
          record.reference.update({'isChecked': false});
        }

        // Добавим цвет по умолчанию, если его нет
        if (!data.containsKey('Color')) {
          record.reference
              .update({'Color': const Color.fromARGB(255, 111, 0, 255).value});
        }

        // Добавим статус удаленности со значением false, если его нет
        if (!data.containsKey('isDeleted')) {
          record.reference.update({'isDeleted': false});
        }
      }

      return records;
    });
  }

  Future<void> saveSortSettings(
      SortType currentSortType, bool currentAscending) async {
    try {
      if (user != null) {
        await usersCollection
            .doc(user?.uid)
            .collection('Settings')
            .doc('Global')
            .set({
          'currentSortType': currentSortType.index,
          'currentAscending': currentAscending,
        });
      }
    } catch (e) {
      print('Error saving sort settings: $e');
    }
  }

  Future<Map<String, dynamic>> getSortSettings() async {
    try {
      if (user != null) {
        DocumentSnapshot documentSnapshot = await usersCollection
            .doc(user?.uid)
            .collection('Settings')
            .doc('Global')
            .get();

        if (documentSnapshot.exists) {
          return documentSnapshot.data() as Map<String, dynamic>;
        }
      }

      return {};
    } catch (e) {
      print('Error getting sort settings: $e');
      return {};
    }
  }

  String _getOrderByField(SortType sortType) {
    switch (sortType) {
      case SortType.title:
        return 'Title';
      case SortType.subtitle:
        return 'Subtitle';
      case SortType.isChecked:
        return 'isChecked';
      case SortType.date:
        return 'Timestamp';
      case SortType.color:
        return 'Color';
      default:
        return '';
    }
  }

  Future<void> addRecord(
    String title,
    String subtitle, {
    bool newActive = false,
    Color? customColor, // Добавляем параметр для пользовательского цвета
  }) async {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    await usersCollection.doc(user?.uid).collection('Records').add({
      'Title': title,
      'Subtitle': subtitle,
      'Timestamp': timestamp,
      'isChecked': newActive,
      'Color':
          customColor?.value ?? const Color.fromARGB(255, 111, 0, 255).value,
      'isDeleted':
          false, // Добавляем новое поле и устанавливаем значение по умолчанию
    });
  }

  Future<void> updateRecordById(
    String recordId, {
    String? newTitle,
    String? newSubtitle,
    bool? newActive,
    Color? customColor, // Добавляем параметр для пользовательского цвета
    bool? isDeleted, // Добавляем параметр для статуса удаленности
  }) async {
    DocumentReference recordRef =
        usersCollection.doc(user?.uid).collection('Records').doc(recordId);

    Map<String, dynamic> existingData =
        (await recordRef.get()).data() as Map<String, dynamic>;

    Map<String, dynamic> updateData = {
      'Title': newTitle ?? existingData['Title'],
      'Subtitle': newSubtitle ?? existingData['Subtitle'],
      'isChecked': newActive ?? existingData['isChecked'],
      'Color': customColor?.value ?? existingData['Color'],
      'isDeleted': isDeleted ?? existingData['isDeleted'] ?? false,
    };

    await recordRef.update(updateData);
  }

  Future<void> deleteRecordById(String recordId) async {
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .delete();
  }

  Future<void> deleteRecordsWithIsDeleted() async {
    try {
      if (user != null) {
        QuerySnapshot recordsSnapshot = await usersCollection
            .doc(user!.uid)
            .collection('Records')
            .where('isDeleted', isEqualTo: true)
            .get();

        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (QueryDocumentSnapshot record in recordsSnapshot.docs) {
          batch.delete(record.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error deleting records with isDeleted: $e');
    }
  }

  Future<void> softDeleteRecordById(String recordId) async {
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .update({'isDeleted': true});
  }

  Future<void> restoreRecordById(String recordId) async {
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .update({'isDeleted': false});
  }

  Future<void> updateCheckboxState(String recordId, bool newState) async {
    // Обновление состояния чекбокса в базе данных
    await usersCollection
        .doc(user?.uid)
        .collection('Records')
        .doc(recordId)
        .update({'isChecked': newState});
  }

  // --------------------------- Статистика ----------------------------------

  int getRecordCount(List<DocumentSnapshot> records) {
    // Возвращает количество записей пользователя
    return records.length;
  }

  double getAverageTitleLength(List<DocumentSnapshot> records) {
    // Возвращает среднюю длину заголовков записей пользователя
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

  double getAverageSubtitleLength(List<DocumentSnapshot> records) {
    // Возвращает среднюю длину подзаголовков записей пользователя
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

  List<String> getFrequentKeywords(List<DocumentSnapshot> records) {
    // Возвращает наиболее часто используемые ключевые слова из заголовков и подзаголовков
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

  Future<Map<String, int>> getKeywordCounts(
      List<DocumentSnapshot> records) async {
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

  // ----------------------------- Заметки ------------------------------------

  Future<String?> saveQuillContentToFirestore(
      String noteId, String quillContent) async {
    try {
      final userDocRef = usersCollection.doc(user?.uid);
      final noteDocRef = userDocRef.collection('Notes').doc(noteId);

      // Проверяем, существует ли документ с заданным идентификатором
      final noteSnapshot = await noteDocRef.get();

      if (noteSnapshot.exists) {
        // Если документ существует, обновляем его содержимое
        await noteDocRef.update({
          'content': quillContent,
          'editAt': DateTime.now().toUtc().millisecondsSinceEpoch
        });
      } else {
        // Если документ не существует, создаем новый документ с уникальным идентификатором
        final newNoteDocRef = userDocRef.collection('Notes').doc();
        await newNoteDocRef.set({
          'content': quillContent,
          'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
          'editAt': DateTime.now().toUtc().millisecondsSinceEpoch
        });

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
    Query query =
        usersCollection.doc(user?.uid).collection('Notes').orderBy('createdAt');

    return query.snapshots().map((querySnapshot) {
      List<Map<String, dynamic>> notes = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Добавим поле createdAt со значением текущей даты, если его нет
        if (!data.containsKey('createdAt')) {
          doc.reference.update({
            'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
          });
          data['createdAt'] = DateTime.now().toUtc().millisecondsSinceEpoch;
        }

        // Добавим поле editAt со значением текущей даты, если его нет
        if (!data.containsKey('editAt')) {
          doc.reference.update({
            'editAt': data['createdAt'],
          });
          data['editAt'] = data['createdAt'];
        }

        return {
          'id': doc.id,
          'content': data['content'] as String,
          'createdAt': data['createdAt'],
          'editAt': data['editAt'],
        };
      }).toList();

      return notes;
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

enum SortType {
  title,
  subtitle,
  isChecked,
  date,
  color,
}
