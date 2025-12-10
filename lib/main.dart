import 'package:flutter/material.dart';
import 'package:anantata/xelauikit/xela_color.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anantata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: XelaColor.Ananta,
          primary: XelaColor.Ananta,
          onPrimary: XelaColor.AnantaWhite,
        ),
        fontFamily: 'NunitoSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: XelaColor.Ananta,
          foregroundColor: XelaColor.AnantaWhite,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: XelaColor.Ananta,
          foregroundColor: XelaColor.AnantaWhite,
        ),
      ),
      home: const MyHomePage(title: 'Anantata Career Coach'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Anantata!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: XelaColor.Ananta,
              ),
            ),
            const SizedBox(height: 20),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: XelaColor.Ananta,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}