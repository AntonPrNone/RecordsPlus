// ignore_for_file: file_names, prefer_const_constructors, use_key_in_widget_constructors

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Services/UserService.dart';
import 'package:flutter_quill/quill_delta.dart';

import 'NoteDetailPage.dart';

class NotesPage extends StatelessWidget {
  final UserService userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userService.quillContentStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<Map<String, dynamic>>? quillContentList = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(8.0), // Увеличенные отступы
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: quillContentList?.length ?? 0,
              itemBuilder: (context, index) {
                String noteId = quillContentList?[index]['id'] ?? '';
                String jsonContent = quillContentList?[index]['content'] ?? '';
                return NoteCard(jsonContent: jsonContent, noteId: noteId);
              },
            ),
          );
        }
      },
    );
  }
}

class NoteCard extends StatelessWidget {
  final String? jsonContent;
  final String noteId;

  const NoteCard({required this.jsonContent, required this.noteId});

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
              ), // Добавленная рамка
              gradient: LinearGradient(
                colors: [Color.fromARGB(128, 111, 0, 255), Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text(
                previewText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
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
        ),
      ),
    );
  }

  String deltaToPlainText(Delta delta) {
    return delta.toList().map((op) => op.data.toString()).join(' ');
  }
}
