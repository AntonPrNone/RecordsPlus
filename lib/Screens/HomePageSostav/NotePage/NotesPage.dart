// ignore_for_file: file_names, prefer_const_constructors, use_key_in_widget_constructors, prefer_is_empty

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_plus/Screens/HomePageSostav/EmptyPage.dart';
import '../../../Services/UserService.dart';
import 'package:flutter_quill/quill_delta.dart';

import 'NoteDetailPage.dart';

class NotesPage extends StatelessWidget {
  final UserService userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.quillContentStream,
      builder: (context, snapshot) {
        List<Map<String, dynamic>>? quillContentList = snapshot.data;
        return quillContentList?.length == 0 || quillContentList == null
            ? EmptyPage(
                firstText: 'заметки',
              )
            : Padding(
                padding: const EdgeInsets.all(8.0), // Увеличенные отступы
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.7),
                  itemCount: quillContentList.length,
                  itemBuilder: (context, index) {
                    String noteId = quillContentList[index]['id'] ?? '';
                    String jsonContent =
                        quillContentList[index]['content'] ?? '';

                    final dateCreate = DateTime.fromMillisecondsSinceEpoch(
                        quillContentList[index]['createdAt']);
                    final formattedDateCreate =
                        DateFormat.yMMMMd('ru').add_jms().format(dateCreate);

                    final dateEdit = DateTime.fromMillisecondsSinceEpoch(
                        quillContentList[index]['editAt']);
                    final formattedDateEdit =
                        DateFormat.yMMMMd('ru').add_jms().format(dateEdit);

                    return NoteCard(
                        jsonContent: jsonContent,
                        noteId: noteId,
                        formattedDateCreate: formattedDateCreate,
                        formattedDateEdit: formattedDateEdit);
                  },
                ),
              );
      },
    );
  }
}

class NoteCard extends StatelessWidget {
  final String? jsonContent;
  final String noteId;
  final String formattedDateCreate;
  final String formattedDateEdit;

  const NoteCard({
    required this.jsonContent,
    required this.noteId,
    required this.formattedDateCreate,
    required this.formattedDateEdit,
  });

  @override
  Widget build(BuildContext context) {
    String previewText = jsonContent != null
        ? deltaToPlainText(Delta.fromJson(jsonDecode(jsonContent!)))
        : 'No Content';

    return Container(
      margin: EdgeInsets.all(0.0),
      child: Material(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            // Обработка нажатия
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailPage(
                  noteId: noteId,
                  jsonContent: jsonContent ?? "",
                  formattedDateEdit: formattedDateEdit,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.black,
                width: 2.0,
              ),
              gradient: LinearGradient(
                colors: [Color.fromARGB(128, 111, 0, 255), Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      previewText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        shadows: [
                          Shadow(
                            offset: Offset(2.0, 2.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Создано: $formattedDateCreate',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String deltaToPlainText(Delta delta) {
    return delta.toList().map((op) => op.data.toString()).join(' ');
  }
}
