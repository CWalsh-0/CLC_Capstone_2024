//import 'package:firebase_ui_auth/firebase_ui_auth.dart';
//import 'package:go_router/go_router.dart';
//import 'package:provider/provider.dart'; // new
//import '../app_state.dart'; // new

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;
  void incrementCounterr() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_counter');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyHomePage());
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  State<MyHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage> {
  //parameters goes here
  int count = 0;
  @override
  Widget build(BuildContext context) {
    //var appState = context.watch<MyAppState>();
    void incrementCounter() {
      setState(() {
        count++;
      });
      print("The button was pressed $count times!");
    }

    // Root widget
    // every small thing here is a widget
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Home Page'),
      ),
      body: Center(
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                const Text('Hello, World!'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (incrementCounter),
                  child: Text("This button was pressed $count times"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
