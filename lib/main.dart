import 'package:flutter/material.dart';
import 'package:cinema/pages/Home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Starter Template',
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
        ),
        home: Home()
    );
  }
}