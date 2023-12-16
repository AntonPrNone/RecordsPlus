// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, file_names, library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:records_plus/Model/AppState.dart';
import 'package:records_plus/Screens/HomePageSostav/EmptyPage.dart';
import 'package:records_plus/Screens/HomePageSostav/SideDrawer/SideDrawer_HomePage.dart';
import 'package:records_plus/Screens/HomePageSostav/NotePage/NotesPage.dart';
import 'package:records_plus/Model/Settings.dart';
import '../../Auth/AuthPage.dart';
import '/Services/AuthService.dart';
import '/Services/UserService.dart';
import '../NoteDetailPage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int selectedColorIndex = 0;
  Color selectedColor = Colors.white;
  List<Color> predefinedColors = [
    Colors.red,
    Color.fromARGB(255, 111, 0, 255),
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.white,
    Colors.black,
    Colors.black,
    // Добавьте другие цвета по вашему выбору
  ];

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

  List<String> titles = [];
  List<String> subtitles = [];
  List<bool> isCheckedList = [];
  List<int> dates = [];
  List<String> recordIds = [];
  List<Color> recordColors = [];

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
            stream: UserService().getAllRecordsStream(
              currentSortType: SettingsCustom.currentSortType!,
              currentAscending: SettingsCustom.currentAscending!,
            ),
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
                recordColors.clear();

                // Обновляем коллекции на основе новых данных
                for (var recordSnapshot in snapshot.data!) {
                  Map<String, dynamic> data =
                      recordSnapshot.data() as Map<String, dynamic>;
                  // Проверяем, соответствует ли запись ключевому слову
                  if ((data['Title']
                              .toLowerCase()
                              .contains(searchKeyword.toLowerCase()) ||
                          data['Subtitle']
                              .toLowerCase()
                              .contains(searchKeyword.toLowerCase())) &&
                      data['isDeleted'] == false) {
                    titles.add(data['Title']);
                    subtitles.add(data['Subtitle']);
                    isCheckedList.add(data['isChecked']);
                    dates.add(data['Timestamp']);
                    recordIds.add(recordSnapshot.id);
                    recordColors.add(Color(data['Color']));
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
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  dates[index]);
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
                                    editRecord(index, recordColors[index]);
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
                                                            softDeleteRecord(
                                                                index);
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
                                                bottomLeft:
                                                    Radius.circular(10.0),
                                              ),
                                              color: recordColors[index]),
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void addRecord(String title, String subtitle) {
    // Добавить запись
    firestoreService.addRecord(title, subtitle).then((_) {});
  }

  void softDeleteRecord(int index) {
    // Удалить запись
    final recordIdToDelete = recordIds[index];
    firestoreService.softDeleteRecordById(recordIdToDelete).then((_) {});
  }

  void editRecord(int index, Color customColor) {
    print(customColor);
    // Редактировать запись
    _titleController.text = titles[index];
    _subtitleController.text = subtitles[index];
    selectedColorIndex = predefinedColors.length - 1;
    predefinedColors[predefinedColors.length - 1] = customColor;

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
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
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
                        maxLines: 3, // Разрешить многострочный ввод
                        minLines: 1,
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
                        maxLines: 5, // Разрешить многострочный ввод
                        minLines: 1,
                      ),
                      SizedBox(height: 16.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0;
                                i < predefinedColors.length - 1;
                                i++)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColorIndex = i;
                                  });
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 30.0,
                                      height: 30.0,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      decoration: BoxDecoration(
                                        color: predefinedColors[i],
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Задайте нужный радиус закругления
                                      ),
                                    ),
                                    if (selectedColorIndex == i)
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: Container(
                                          width: 30.0,
                                          height: 30.0,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.0,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    if (selectedColorIndex == i)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(2.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[900],
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 10.0,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(
                                    20.0), // Задай здесь нужный радиус закругления
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedColorIndex =
                                              predefinedColors.length - 1;
                                        });
                                      },
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 30.0,
                                            height: 30.0,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            decoration: BoxDecoration(
                                              color: predefinedColors[
                                                  predefinedColors.length - 1],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (selectedColorIndex ==
                                              predefinedColors.length - 1)
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              child: Container(
                                                width: 30.0,
                                                height: 30.0,
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 8.0),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          if (selectedColorIndex ==
                                              predefinedColors.length - 1)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                padding: EdgeInsets.all(2.0),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.grey[900],
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 12.0,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _pickCustomColor(context, setState);
                                        selectedColorIndex =
                                            predefinedColors.length - 1;
                                      },
                                      child: Container(
                                        width: 30.0,
                                        height: 30.0,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[
                                                600]!, // Добавляй восклицательный знак для преобразования null в non-null
                                            width: 2.0,
                                          ),
                                        ),
                                        child: ShaderMask(
                                          shaderCallback: (Rect bounds) {
                                            return LinearGradient(
                                              colors: const [
                                                Color(0xFFE040FB),
                                                Color(0xFF673AB7)
                                              ], // Задайте нужные цвета градиента
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ).createShader(bounds);
                                          },
                                          child: Icon(
                                            Icons.palette,
                                            color: Colors
                                                .white, // Цвет иконки после применения градиента
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    saveChanges(index, predefinedColors[selectedColorIndex]);
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

// Функция для отображения диалога выбора цвета из палитры
  void _pickCustomColor(BuildContext context, StateSetter setState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: StatefulBuilder(
            builder: (context, innerSetState) {
              return SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) {
                    innerSetState(() {
                      selectedColor = color;
                    });
                    setState(() {
                      predefinedColors[predefinedColors.length - 1] =
                          selectedColor;
                    });
                  },
                  colorPickerWidth: 300.0,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha:
                      true, // Разрешить использование альфа-канала (прозрачности)
                  displayThumbColor: true,
                  hexInputBar: true,
                  showLabel: false,
                  paletteType: PaletteType.hsv,
                  pickerAreaBorderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2.0),
                    topRight: Radius.circular(2.0),
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ОК'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          backgroundColor: Colors.grey[900],
        );
      },
    );
  }

  void saveChanges(int index, Color customColor) async {
    // Сохранить обновлённые данные
    final updatedTitle = _titleController.text.trim();
    final updatedSubtitle = _subtitleController.text.trim();
    final color = customColor;

    if (updatedTitle.isNotEmpty && updatedSubtitle.isNotEmpty) {
      final recordIdToUpdate = recordIds[index];

      await firestoreService.updateRecordById(recordIdToUpdate,
          newTitle: updatedTitle,
          newSubtitle: updatedSubtitle,
          customColor: color);

      setState(() {
        titles[index] = updatedTitle;
        subtitles[index] = updatedSubtitle;
        recordColors[index] = color;
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
        IconButton(
          icon: Icon(
            Icons.menu_open,
            color: Colors.white,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        Center(
          child: Container(
            margin: EdgeInsets.only(left: 0, right: 10),
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
        _buildSortIcon(),
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
                    noteId: ' ', jsonContent: ' ', formattedDateEdit: ' ')),
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

  // --------------------------- Сортировка ----------------------------------

  Widget _buildSortIcon() {
    return IconButton(
      icon: Icon(
        Icons.sort,
        color: Colors.blue,
      ),
      onPressed: () {
        _showSortOptions(context);
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    final RenderBox appBarRenderBox = context.findRenderObject() as RenderBox;
    final Offset appBarPosition = appBarRenderBox.localToGlobal(Offset.zero);

    showMenu(
      surfaceTintColor: Color.fromARGB(0, 0, 0, 0),
      color: Colors.grey[900], // Цвет фона для тёмной темы
      context: context,
      position: RelativeRect.fromLTRB(
        appBarPosition.dx + appBarRenderBox.size.width,
        appBarPosition.dy + AppBar().preferredSize.height * 1.5,
        0,
        0,
      ),
      items: [
        ..._buildSortMenuItem(Icons.title, SortType.title),
        _buildDivider(),
        ..._buildSortMenuItem(Icons.subtitles, SortType.subtitle),
        _buildDivider(),
        ..._buildSortMenuItem(Icons.check_circle, SortType.isChecked),
        _buildDivider(),
        ..._buildSortMenuItem(Icons.date_range, SortType.date),
        _buildDivider(),
        ..._buildSortMenuItem(Icons.color_lens, SortType.color),
      ],
    );
  }

  List<PopupMenuEntry<dynamic>> _buildSortMenuItem(
      IconData iconData, SortType sortType) {
    return [
      PopupMenuItem<int>(
        onTap: () {
          saveSortSettings(context, _sortValue(sortType, true));
        },
        value: _sortValue(sortType, true),
        child: IgnorePointer(
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(iconData, color: Colors.blue), // Цвет иконки
                    SizedBox(width: 8),
                    Text(
                      _getSortTypeName(sortType),
                      style: TextStyle(color: Colors.white), // Цвет текста
                    ),
                  ],
                ),
                Icon(Icons.arrow_upward, color: Colors.blue), // Стрелка вверх
              ],
            ),
          ),
        ),
      ),
      PopupMenuItem<int>(
        onTap: () {
          saveSortSettings(context, _sortValue(sortType, false));
        },
        value: _sortValue(sortType, false),
        child: IgnorePointer(
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(iconData, color: Colors.blue), // Цвет иконки
                    SizedBox(width: 8),
                    Text(
                      _getSortTypeName(sortType),
                      style: TextStyle(color: Colors.white), // Цвет текста
                    ),
                  ],
                ),
                Icon(Icons.arrow_downward, color: Colors.blue), // Стрелка вниз
              ],
            ),
          ),
        ),
      ),
    ];
  }

  PopupMenuItem<dynamic> _buildDivider() {
    return PopupMenuItem(
      height: 2,
      enabled: false,
      child: Divider(
        color: Colors.grey,
      ),
    );
  }

  int _sortValue(SortType sortType, bool ascending) {
    return sortType.index * 2 + (ascending ? 1 : 0);
  }

  String _getSortTypeName(SortType sortType) {
    switch (sortType) {
      case SortType.title:
        return 'Заголовок';
      case SortType.subtitle:
        return 'Подзаголовок';
      case SortType.isChecked:
        return 'Выполненность';
      case SortType.date:
        return 'Дата создания';
      case SortType.color:
        return 'Цвет';
      default:
        return '';
    }
  }

  Future<void> saveSortSettings(BuildContext context, int sortValue) async {
    setState(() {
      SettingsCustom.currentSortType = SortType.values[sortValue ~/ 2];
      SettingsCustom.currentAscending = sortValue % 2 == 1;
    });
    await UserService().saveSortSettings(
        SettingsCustom.currentSortType!, SettingsCustom.currentAscending!);
  }
  // -------------------------------------------------------------------------
}
