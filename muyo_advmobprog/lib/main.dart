import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
 
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ), // ChangeNotifierProvider
  );
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
 
    return MaterialApp(
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const MyHomePage(), // starts on the counter screen
    ); // MaterialApp
  }
}
 
class ThemeModel with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
 
  // switches the theme and tells all widgets listening to rebuild
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
 
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
 
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // local state, only exists here
 
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          // button to go to the theme toggle screen
          IconButton(
            icon: const Icon(Icons.settings_brightness),
            tooltip: 'Go to theme settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyHome()),
              );
            },
          ), // IconButton
        ],
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), // Text
          ], // <Widget>[]
        ), // Column
      ), // Center
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // FloatingActionButton
    ); // Scaffold
  }
}
 
class MyHome extends StatelessWidget {
  const MyHome({super.key});
 
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
        actions: [
          // switch to toggle dark mode on/off
          Switch(
            value: themeModel.isDark,
            onChanged: (_) => themeModel.toggleTheme(),
          ), // Switch
        ],
      ), // AppBar
      body: Center(
        child: const Text('Toggles the theme using the switch in the app bar.'),
      ), // Center
    ); // Scaffold
  }
}
 