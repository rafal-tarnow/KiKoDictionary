import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

void main() {
  runApp(const MyApp());
}

 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // --- TUTAJ JEST KLUCZOWA ZMIANA ---
      builder: (context, child) {
        return Container(
          // 1. Ustawiamy kolor tła "przeglądarki" (szary, żeby odróżnić od aplikacji)
          color: Colors.grey[200], 
          // 2. Centrujemy zawartość
          alignment: Alignment.center, 
          child: ConstrainedBox(
            // 3. Narzucamy maksymalną szerokość (np. 500 pikseli - jak duży telefon)
            constraints: const BoxConstraints(maxWidth: 500),
            // 4. Jeśli 'child' jest null (rzadko), wstawiamy pusty widget, w przeciwnym razie Twoją aplikację
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      // ----------------------------------
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoggedIn = false; 
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions:[
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Odstęp od krawędzi ekranu
            child: PopupMenuButton<String>(
              offset: Offset(0, 50),

              // Wygląd przycisku (Ikona SVG w kółku)
              icon: CircleAvatar(
                radius: 18, // Rozmiar kółka
                backgroundColor: Colors.grey[200], // Kolor tła kółka
                child: SvgPicture.asset(
                  '/icons/user.svg', // Ścieżka do Twojego SVG
                  width: 20, // Dopasuj rozmiar samej ikony
                  height: 20,
                  // Opcjonalnie: zmień kolor ikony jeśli SVG na to pozwala
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn), 
                ),
              ),

                            // Logika po wybraniu opcji z menu
              onSelected: (value) {
                if (value == 'login') {
                  setState(() => isLoggedIn = true);
                  // Tu dodaj nawigację do ekranu logowania
                } else if (value == 'logout') {
                  setState(() => isLoggedIn = false);
                  // Tu logika wylogowania
                } else if (value == 'profile') {
                  // Nawigacja do profilu
                }
              },

              itemBuilder: (BuildContext context){
                if (isLoggedIn) {
                  // Menu dla zalogowanego użytkownika
                  return [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('Mój Profil (Status: OK)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Wyloguj'),
                        ],
                      ),
                    ),
                  ];
                } else {
                  // Menu dla niezalogowanego (gościa)
                  return [
                    PopupMenuItem(
                      value: 'login',
                      child: Row(
                        children: [
                          Icon(Icons.login, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Zaloguj się'),
                        ],
                      ),
                    ),
                  ];
                }
              },
            ),
          )
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
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

