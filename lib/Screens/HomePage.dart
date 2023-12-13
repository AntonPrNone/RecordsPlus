// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, file_names, library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:records_plus/AppState.dart';
import 'package:records_plus/Screens/HomePageSostav/EmptyPage.dart';
import 'package:records_plus/Screens/HomePageSostav/HomePageRecords/SideDrawer_HomePage.dart';
import 'package:records_plus/Screens/HomePageSostav/NotesPage.dart';
import 'AuthPage.dart';
import '/Services/AuthService.dart';
import '/Services/UserService.dart';
import 'HomePageSostav/NoteDetailPage.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  String searchKeyword = '';
  bool isBottomSheetOpen = false;
  FocusNode myFocusNode = FocusNode();
  UserService firestoreService = UserService();
  AuthService authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> titles = [];
  List<String> subtitles = [];
  List<bool> isCheckedList = [];
  List<int> dates = [];
  List<String> recordIds = [];

  @override
  Widget build(BuildContext context) {
    final bottomNavBar = BottomNavigationBar(
      backgroundColor: Color.fromARGB(255, 22, 22, 22),
      selectedItemColor: Color.fromARGB(255, 111, 0, 255),
      unselectedItemColor: Colors.grey[600],
      items: _kBottmonNavBarItems,
      currentIndex: _currentTabIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          _currentTabIndex = index;
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      },
    );
    final appState = Provider.of<AppState>(context);

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[900],
        drawer: SideDrawer(),
        body: Stack(children: [
          // RandomPointsPainter(
          //   color: Colors.blue,
          // ),
          Positioned.fill(
            child: appState.backgroundImage != null &&
                    File(appState.backgroundImage!.path).existsSync()
                ? Image.file(
                    appState.backgroundImage!,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/imgs/bg2.jpg',
                    fit: BoxFit.cover,
                  ),
          ),
          StreamBuilder<List<DocumentSnapshot>>(
            stream: UserService().getAllRecordsStream(),
            builder: (BuildContext context,
                AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
              if (snapshot.hasError) {
                return Text('Произошла ошибка: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return EmptyPage(firstText: 'записи');
              } else {
                // Очищаем коллекции перед обновлением
                titles.clear();
                subtitles.clear();
                isCheckedList.clear();
                dates.clear();
                recordIds.clear();

                // Обновляем коллекции на основе новых данных
                for (var recordSnapshot in snapshot.data!) {
                  Map<String, dynamic> data =
                      recordSnapshot.data() as Map<String, dynamic>;
                  // Проверяем, соответствует ли запись ключевому слову
                  if (data['Title']
                          .toLowerCase()
                          .contains(searchKeyword.toLowerCase()) ||
                      data['Subtitle']
                          .toLowerCase()
                          .contains(searchKeyword.toLowerCase())) {
                    titles.add(data['Title']);
                    subtitles.add(data['Subtitle']);
                    isCheckedList.add(data['isChecked']);
                    dates.add(data['Timestamp']);
                    recordIds.add(recordSnapshot.id);
                  }
                }
                return PageView(
                  controller: _pageController,
                  children: [
                    titles.isEmpty
                        ? EmptyPage(
                            firstText: 'записи',
                          )
                        : ListView.builder(
                            itemCount: titles.length,
                            itemBuilder: (BuildContext context, int index) {
                              final DocumentSnapshot recordSnapshot =
                                  snapshot.data![index];
                              final Map<String, dynamic> data =
                                  recordSnapshot.data() as Map<String, dynamic>;
                              // final int itemIndex = filterList()[index];
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  data['Timestamp']);
                              final formattedDate = DateFormat.yMMMMd('ru')
                                  .add_jms()
                                  .format(date);

                              return Card(
                                surfaceTintColor: Color.fromARGB(0, 0, 0, 0),
                                color: Color.fromARGB(150, 20, 20, 20),
                                margin: const EdgeInsets.all(10.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                elevation: 4.0,
                                child: InkWell(
                                  onTap: () {
                                    editRecord(index);
                                  },
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: 10, bottom: 10, right: 10),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isCheckedList[index],
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isCheckedList[index] =
                                                      value ?? false;
                                                  firestoreService
                                                      .updateCheckboxState(
                                                    recordIds[index],
                                                    isCheckedList[index],
                                                  );
                                                });
                                              },
                                            ),
                                            SizedBox(width: 10.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  RichText(
                                                    text: TextSpan(
                                                      text: titles[index],
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16.0,
                                                        color:
                                                            isCheckedList[index]
                                                                ? Colors
                                                                    .grey[400]
                                                                : null,
                                                        decoration:
                                                            isCheckedList[index]
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : TextDecoration
                                                                    .none,
                                                        fontStyle:
                                                            isCheckedList[index]
                                                                ? FontStyle
                                                                    .italic
                                                                : FontStyle
                                                                    .normal,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 5.0),
                                                  Text(
                                                    subtitles[index],
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      decoration:
                                                          isCheckedList[index]
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                      fontStyle:
                                                          isCheckedList[index]
                                                              ? FontStyle.italic
                                                              : FontStyle
                                                                  .normal,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    'Создано: $formattedDate',
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 10.0,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      decoration:
                                                          isCheckedList[index]
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Color.fromARGB(
                                                      255, 143, 10, 0)),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                              255, 22, 22, 22),
                                                      title: Text(
                                                        'Подтвердите удаление',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        'Вы действительно хотите удалить эту запись?',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          child: Text('Отмена'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        ),
                                                        TextButton(
                                                          child: Text(
                                                            'Удалить',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            deleteRecord(index);
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: 0,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10.0),
                                              bottomLeft: Radius.circular(10.0),
                                            ),
                                            color: Color.fromARGB(
                                                255, 111, 0, 255),
                                          ),
                                          child: SizedBox(width: 8.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    NotesPage()
                  ],
                  onPageChanged: (int index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                );
              }
            },
          )
        ]),
        bottomNavigationBar: bottomNavBar,
        floatingActionButton: FloatingActionButtonHomePage(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        appBar: AppBarHomePage(context));
  }

  final _kBottmonNavBarItems = <BottomNavigationBarItem>[
    // Нижняя панель-меню
    const BottomNavigationBarItem(
        icon: Icon(Icons.notes_outlined), label: 'Записи'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.pending_actions), label: 'Заметки'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startRotationAnimation() {
    // Анимация кнопки
    _animationController.reset();
    _animationController.forward();
  }

  void _onRefreshPressed() {
    // Обработка кнопки обновления данных
    _startRotationAnimation();
  }

  void addRecord(String title, String subtitle) {
    // Добавить запись
    firestoreService.addRecord(title, subtitle).then((_) {});
  }

  void deleteRecord(int index) {
    // Удалить запись
    final recordIdToDelete = recordIds[index];
    firestoreService.deleteRecordById(recordIdToDelete).then((_) {});
  }

  void editRecord(int index) {
    // Редактировать запись
    _titleController.text = titles[index];
    _subtitleController.text = subtitles[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            brightness: Brightness.dark,
          ),
          child: AlertDialog(
            title: Text(
              'Редактирование записи',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Заголовок',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: null, // Разрешить многострочный ввод
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _subtitleController,
                  decoration: InputDecoration(
                    labelText: 'Подзаголовок',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: null, // Разрешить многострочный ввод
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    saveChanges(index);
                    _titleController.clear();
                    _subtitleController.clear();
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromARGB(255, 99, 0, 156)),
                  ),
                  child: Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        );
      },
    );
  }

  void saveChanges(int index) async {
    // Сохранить обновлённые данные
    final updatedTitle = _titleController.text.trim();
    final updatedSubtitle = _subtitleController.text.trim();

    if (updatedTitle.isNotEmpty && updatedSubtitle.isNotEmpty) {
      final recordIdToUpdate = recordIds[index];

      await firestoreService.updateRecordById(
        recordIdToUpdate,
        newTitle: updatedTitle,
        newSubtitle: updatedSubtitle,
      );

      setState(() {
        titles[index] = updatedTitle;
        subtitles[index] = updatedSubtitle;
      });
    }

    _titleController.clear();
    _subtitleController.clear();
  }

  // Нижняя панель добавления ---------------------------------------------------
  Container _buildBottomSheet(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 16, bottom: 16, right: 8, left: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.blue, width: 2.0),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Theme(
        data: ThemeData(
          brightness: Brightness.dark,
        ),
        child: ListView(
          children: <Widget>[
            const ListTile(title: Text('Добавление записи')),
            _buildTextField(_titleController, Icons.title, 'Заголовок'),
            const SizedBox(height: 16),
            _buildTextField(
                _subtitleController, Icons.subtitles, 'Подзаголовок'),
            const SizedBox(height: 16),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, IconData icon, String labelText) {
    // Текстовые поля - Нижняя панель
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        icon: Icon(icon),
        labelText: labelText,
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    // Кнопка сохранения - Нижняя панель
    return Container(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Color.fromARGB(255, 99, 0, 156);
              }
              return Color.fromARGB(255, 162, 0, 255);
            },
          ),
        ),
        icon: const Icon(Icons.save),
        label: const Text('Сохранить'),
        onPressed: () {
          String title = _titleController.text.trim();
          String subtitle = _subtitleController.text.trim();
          if (title.isNotEmpty && subtitle.isNotEmpty) {
            addRecord(title, subtitle);
          }
          _titleController.clear();
          _subtitleController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  AppBar AppBarHomePage(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.grey[900],
      shadowColor: Color.fromARGB(115, 0, 0, 0),
      elevation: 4.0,
      actions: [
        Center(
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 10),
            child: Text(
              _currentTabIndex == 0 ? 'Home' : 'Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        _currentTabIndex == 0
            ? Expanded(
                child: Theme(
                  data: ThemeData.dark(),
                  child: SizedBox(
                    child: TextField(
                      focusNode: myFocusNode,
                      onChanged: (value) {
                        setState(() {
                          searchKeyword = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Поиск',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              )
            : Expanded(
                child: Container(),
              ), // Добавил условие, чтобы избежать ошибки
        AnimatedBuilder(
          animation: _animationController,
          builder: (BuildContext context, Widget? child) {
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: IconButton(
                icon: const Icon(
                  Icons.auto_delete_outlined,
                  color: Colors.blue,
                ),
                onPressed: _onRefreshPressed,
              ),
            );
          },
        ),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color.fromARGB(255, 22, 22, 22),
                  title: Text(
                    'Подтвердите выход',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Вы действительно хотите выйти из своей учётной записи?',
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
                        'Выход',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        authService.signOut();
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 500),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    AuthPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              var begin = Offset(0.0, 1.0);
                              var end = Offset.zero;
                              var curve = Curves.ease;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
          icon: Icon(Icons.exit_to_app_rounded),
          color: Colors.red,
        ),
      ],
    );
  }

  FloatingActionButton FloatingActionButtonHomePage(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: isBottomSheetOpen
          ? const Color.fromARGB(255, 255, 17, 0)
          : Color.fromARGB(255, 111, 0, 255),
      onPressed: () {
        if (_currentTabIndex == 0) {
          if (isBottomSheetOpen) {
            Navigator.pop(context);
          } else {
            _titleController.clear();
            _subtitleController.clear();
          }
          setState(() {
            isBottomSheetOpen = !isBottomSheetOpen;
          });

          if (isBottomSheetOpen) {
            _scaffoldKey.currentState
                ?.showBottomSheet(
                  backgroundColor: Colors.grey[900],
                  (ctx) => _buildBottomSheet(ctx),
                )
                .closed
                .whenComplete(() {
              setState(() {
                isBottomSheetOpen = false;
              });
            });
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NoteDetailPage(
                      noteId: ' ',
                      jsonContent: ' ',
                    )),
          );
        }
      },
      child: isBottomSheetOpen
          ? Icon(
              Icons.clear,
              color: Colors.black,
            )
          : Icon(
              Icons.favorite,
              color: Colors.red,
            ),
    );
  }
}
