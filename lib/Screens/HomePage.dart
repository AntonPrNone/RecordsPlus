// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, file_names, library_private_types_in_public_api
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import '../RandomPointsPainter.dart';
import 'AuthPage.dart';
import '/Services/AuthService.dart';
import '/Services/UserService.dart';

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
  List<int> dates = [];
  List<String> recordIds = [];

  final List<PhoneApp> _apps = [
    PhoneApp('Messages', Icons.message),
    PhoneApp('Phone', Icons.phone),
    PhoneApp('Camera', Icons.camera_alt),
    PhoneApp('Photos', Icons.photo_library),
    PhoneApp('Maps', Icons.map),
    PhoneApp('Music', Icons.music_note),
    PhoneApp('Settings', Icons.settings),
    PhoneApp('Calendar', Icons.calendar_today),
    PhoneApp('Clock', Icons.access_time),
    PhoneApp('Contacts', Icons.contacts),
    PhoneApp('Calculator', Icons.calculate),
    PhoneApp('Weather', Icons.wb_sunny),
    PhoneApp('Notes', Icons.note),
    PhoneApp('Reminders', Icons.notifications_none),
    PhoneApp('Safari', Icons.web),
    PhoneApp('Mail', Icons.mail),
  ];

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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[900],
      body: Stack(children: [
        RandomPointsPainter(
          color: Colors.white,
        ),
        PageView(
          controller: _pageController,
          children: [
            titles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Добавьте записи с помощью кнопки:',
                              textStyle: TextStyle(color: Colors.white),
                              speed: Duration(milliseconds: 50),
                            ),
                          ],
                          isRepeatingAnimation: false,
                        ),
                        SizedBox(height: 20),
                        Icon(
                          Icons.add,
                          size: 50.0,
                          color: Color.fromARGB(255, 111, 0, 255),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          height: 100,
                          child: AnimatedTextKit(
                            animatedTexts: [
                              FadeAnimatedText(
                                '↓',
                                textStyle: TextStyle(
                                    fontSize: 92, color: Colors.white),
                              ),
                            ],
                            repeatForever: true,
                            pause: Duration(milliseconds: 200),
                          ),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filterList().length,
                    itemBuilder: (BuildContext context, int index) {
                      final int itemIndex = filterList()[index];
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(dates[itemIndex]);
                      final formattedDate =
                          DateFormat.yMMMMd('ru').add_jms().format(date);
                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            deleteRecord(itemIndex);
                          }
                        },
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          color: Color.fromARGB(255, 30, 30, 30),
                          margin: const EdgeInsets.all(10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4.0,
                          child: ListTile(
                            onTap: () {
                              editRecord(index);
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              titles[itemIndex],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subtitles[itemIndex],
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Создано: $formattedDate',
                                  style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10.0,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete,
                                  color: Color.fromARGB(255, 143, 10, 0)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor:
                                          const Color.fromARGB(255, 22, 22, 22),
                                      title: Text(
                                        'Подтвердите удаление',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
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
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            deleteRecord(index);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: GridView.count(
                crossAxisCount: 4,
                children: List.generate(_apps.length, (index) {
                  Color color =
                      Color((Random().nextDouble() * 0xFFFFFF).toInt())
                          .withOpacity(1.0);
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _apps[index].icon,
                          color: color,
                        ),
                        SizedBox(height: 3),
                        Text(
                          _apps[index].name,
                          style: TextStyle(color: color),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
          onPageChanged: (int index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
        ),
      ]),
      bottomNavigationBar: bottomNavBar,
      floatingActionButton: FloatingActionButton(
        backgroundColor: isBottomSheetOpen
            ? const Color.fromARGB(255, 255, 17, 0)
            : Color.fromARGB(255, 111, 0, 255),
        onPressed: () {
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
        },
        child: isBottomSheetOpen
            ? Icon(
                Icons.clear,
                color: Colors.black,
              )
            : Icon(
                Icons.add,
                color: Colors.black,
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Убираем кнопку назад
        backgroundColor: Colors.grey[900],
        actions: [
          Center(
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 10),
              child: Text(
                'Home',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Theme(
              data: ThemeData.dark(), // Используем тему тёмной темы
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
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                angle: _animation.value * 2 * 3.14159,
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh,
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
                          color: Colors.white, fontWeight: FontWeight.bold),
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
          )
        ],
      ),
    );
  }

  final _kBottmonNavBarItems = <BottomNavigationBarItem>[
    // Нижняя панель-меню
    const BottomNavigationBarItem(
        icon: Icon(Icons.notes_outlined), label: 'Записи'),
    const BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'TabRandom'),
  ];

  Future<void> loadTitlesAndSubtitles() async {
    // Загрузка или обновление данных списков
    final records = await firestoreService.getAllRecords();
    setState(() {
      titles = records.map((record) => record['Title'] as String).toList();
      subtitles =
          records.map((record) => record['Subtitle'] as String).toList();
      dates = records.map((record) => record['Timestamp'] as int).toList();
      recordIds = records.map((record) => record.id).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    loadTitlesAndSubtitles();
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
    loadTitlesAndSubtitles();
    _startRotationAnimation();
  }

  void addRecord(String title, String subtitle) {
    // Добавить запись
    firestoreService.addRecord(title, subtitle).then((_) {
      loadTitlesAndSubtitles();
    });
  }

  void deleteRecord(int index) {
    // Удалить запись
    final recordIdToDelete = recordIds[index];
    firestoreService.deleteRecordById(recordIdToDelete).then((_) {
      loadTitlesAndSubtitles();
    });
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
              ElevatedButton(
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

  // Метод для фильтрации списка по ключевому слову
  List<int> filterList() {
    List<int> filteredIndexes = [];
    for (int i = 0; i < titles.length; i++) {
      if (titles[i].toLowerCase().contains(searchKeyword.toLowerCase()) ||
          subtitles[i].toLowerCase().contains(searchKeyword.toLowerCase())) {
        filteredIndexes.add(i);
      }
    }
    if (searchKeyword.isEmpty) {
      myFocusNode.unfocus();
    }
    return filteredIndexes;
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
}

class PhoneApp {
  final String name;
  final IconData icon;
  PhoneApp(this.name, this.icon);
}

// Фон -----------------------------------------------------------------------

