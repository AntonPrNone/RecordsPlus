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
}
