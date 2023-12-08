// ignore_for_file: prefer_const_constructors, file_names, use_key_in_widget_constructors, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../Services/UserService.dart';

class NoteDetailPage extends StatelessWidget {
  final UserService userService = UserService();
  String noteId;
  final String jsonContent;

  NoteDetailPage({required this.noteId, required this.jsonContent});

  @override
  Widget build(BuildContext context) {
    final quillController = QuillController.basic();
    if (noteId != ' ') {
      final delta = Delta.fromJson(jsonDecode(jsonContent!));
      quillController.document = Document.fromDelta(delta);
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible:
                    false, // Чтобы пользователь не мог закрыть диалог жестом
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color.fromARGB(255, 22, 22, 22),
                    title: Text(
                      'Подтвердите удаление',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Вы действительно хотите удалить эту запись?',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Отмена'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text(
                          'Удалить',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () async {
                          await userService.deleteNoteFromFirestore(noteId);
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Заметка удалена!'),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Icon(Icons.delete),
            backgroundColor: Colors.red,
            heroTag: null,
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () async {
              // Получаем контент Quill в формате JSON
              final quillContent =
                  jsonEncode(quillController.document.toDelta().toJson());

              var res = await userService.saveQuillContentToFirestore(
                  noteId, quillContent);
              if (noteId == " ") {
                noteId = res!;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Content saved to Firestore!'),
                ),
              );
            },
            child: Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(4),
        child: QuillProvider(
          configurations: QuillConfigurations(
            controller: quillController,
            sharedConfigurations: const QuillSharedConfigurations(
              locale: Locale('ru'),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: 80, left: 10, right: 10, bottom: 10),
                  child: QuillEditor.basic(
                    configurations: const QuillEditorConfigurations(
                      readOnly: false,
                    ),
                  ),
                ),
              ),
              const QuillToolbar(),
            ],
          ),
        ),
      ),
    );
  }
}
