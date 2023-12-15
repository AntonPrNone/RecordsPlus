// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, file_names, library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:records_plus/AppState.dart';
import 'package:records_plus/Screens/HomePageSostav/EmptyPage.dart';
import '/Services/AuthService.dart';
import '/Services/UserService.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BascetPage extends StatefulWidget {
  final List<DocumentSnapshot> initialRecords;
  const BascetPage({required this.initialRecords});
  @override
  State<StatefulWidget> createState() =>
      BascetPageState(initialRecords: initialRecords);
}

class BascetPageState extends State<BascetPage>
    with SingleTickerProviderStateMixin {
  final List<DocumentSnapshot> initialRecords;
  BascetPageState({required this.initialRecords});
  SortType currentSortType = SortType.date; // Изначально сортируем по заголовку
  bool currentAscending = true; // Изначально по возрастанию
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

  String searchKeyword = '';
  bool isBottomSheetOpen = false;
  FocusNode myFocusNode = FocusNode();
  UserService firestoreService = UserService();
  AuthService authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> titles = [];
  List<String> subtitles = [];
  List<bool> isCheckedList = [];
  List<int> dates = [];
  List<String> recordIds = [];
  List<Color> recordColors = [];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[900],
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
            initialData: initialRecords,
            stream: UserService().getAllRecordsStream(
              currentSortType: currentSortType,
              currentAscending: currentAscending,
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
                      data['isDeleted'] == true) {
                    titles.add(data['Title']);
                    subtitles.add(data['Subtitle']);
                    isCheckedList.add(data['isChecked']);
                    dates.add(data['Timestamp']);
                    recordIds.add(recordSnapshot.id);
                    recordColors.add(Color(data['Color']));
                  }
                }
                return Container(
                  child: titles.isEmpty
                      ? Center(
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Корзина пуста!',
                                textStyle: const TextStyle(color: Colors.white),
                                speed: const Duration(milliseconds: 50),
                              ),
                            ],
                            isRepeatingAnimation: false,
                          ),
                        )
                      : ListView.builder(
                          itemCount: titles.length,
                          itemBuilder: (BuildContext context, int index) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                dates[index]);
                            final formattedDate =
                                DateFormat.yMMMMd('ru').add_jms().format(date);

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
                                                              ? Colors.grey[400]
                                                              : null,
                                                      decoration:
                                                          isCheckedList[index]
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : TextDecoration
                                                                  .none,
                                                      fontStyle:
                                                          isCheckedList[index]
                                                              ? FontStyle.italic
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
                                                            : FontStyle.normal,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Создано: $formattedDate',
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 10.0,
                                                    fontStyle: FontStyle.italic,
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
                                            icon: Icon(Icons.restore_from_trash,
                                                color: Colors.blue),
                                            onPressed: () {
                                              restoreRecord(index);
                                            },
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
                                                    content: RichText(
                                                      text: TextSpan(
                                                        children: const <TextSpan>[
                                                          TextSpan(
                                                              text:
                                                                  'Вы действительно хотите '),
                                                          TextSpan(
                                                            text:
                                                                'безвозвратно',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .redAccent),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                ' удалить эту запись? Восстановить в будущем будет невозможно',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: Text('Отмена'),
                                                        onPressed: () {
                                                          Navigator.of(context)
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
                                                          Navigator.of(context)
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
                );
              }
            },
          )
        ]),
        appBar: AppBarHomePage(context));
  }

  @override
  void initState() {
    super.initState();
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

  void restoreRecord(int index) {
    // "Удалить" запись
    final recordIdToDelete = recordIds[index];
    firestoreService.restoreRecordById(recordIdToDelete).then((_) {});
  }

  void deleteRecord(int index) {
    // Удалить запись
    final recordIdToDelete = recordIds[index];
    firestoreService.deleteRecordById(recordIdToDelete).then((_) {});
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

  AppBar AppBarHomePage(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.grey[900],
      shadowColor: Color.fromARGB(115, 0, 0, 0),
      elevation: 4.0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            // Добавьте вашу логику для кнопки "назад" здесь
            Navigator.of(context).pop();
          },
        ),
        Center(
          child: Container(
            margin: EdgeInsets.only(left: 0, right: 10),
            child: Text(
              'Basket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
        Expanded(
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
        ), // Добавил условие, чтобы избежать ошибки
        _buildSortIcon(),
      ],
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
          _onSortSelected(context, _sortValue(sortType, true));
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
          _onSortSelected(context, _sortValue(sortType, false));
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

  void _onSortSelected(BuildContext context, int sortValue) {
    setState(() {
      currentSortType = SortType.values[sortValue ~/ 2];
      currentAscending = sortValue % 2 == 1;
    });
  }
  // -------------------------------------------------------------------------
}
