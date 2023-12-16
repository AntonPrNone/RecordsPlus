// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, use_key_in_widget_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_plus/Screens/HomePageSostav/SideDrawer/Basket.dart';
import 'package:records_plus/Screens/HomePageSostav/SideDrawer/SettingsPage.dart';
import 'package:records_plus/Screens/HomePageSostav/SideDrawer/StatisticPage.dart';
import 'package:records_plus/Services/UserService.dart';

class SideDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      surfaceTintColor: Color.fromARGB(0, 0, 0, 0),
      backgroundColor: Color.fromARGB(255, 29, 29, 29),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 24, 24, 24),
            ),
            accountName: Text(
              'Дата регистрации: ${FirebaseAuth.instance.currentUser?.metadata.creationTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(FirebaseAuth.instance.currentUser!.metadata.creationTime!.toLocal()) : "Неизвестно"}', // Отображение даты регистрации
              style: TextStyle(fontSize: 14),
            ),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Color.fromARGB(255, 111, 0, 255),
              child: Icon(
                Icons.person,
                size: 35,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Color.fromARGB(255, 95, 95, 95),
            ), // Значок настроек
            title: Text(
              'Настройки',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(
              Icons.analytics_outlined,
              color: Color.fromARGB(255, 95, 95, 95),
            ), // Значок настроек
            title: Text(
              'Статистика',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              var userService = UserService();
              List<DocumentSnapshot<Object?>> initialRecord =
                  await userService.getAllRecords();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StatisticPage(initialRecords: initialRecord),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.auto_delete_outlined,
              color: Color.fromARGB(255, 95, 95, 95),
            ), // Значок настроек
            title: Text(
              'Корзина',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              var userService = UserService();
              List<DocumentSnapshot<Object?>> initialRecord =
                  await userService.getAllRecords();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BascetPage(
                    initialRecords: initialRecord,
                  ),
                ),
              );
            },
          ),
          // Добавьте другие пункты меню по необходимости
        ],
      ),
    );
  }
}
