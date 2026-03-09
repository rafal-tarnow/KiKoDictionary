import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  // ProviderScope przechowuje stan wszystkich providerów
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Learning App',
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}


//---------------------------------------------------------------------

// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Responsywna animacja Flutter',
//       home: AnimationScreen(),
//     );
//   }
// }

// // Używamy StatefulWidget, ponieważ musimy pamiętać, w jakim stanie 
// // znajduje się aplikacja (isTop = true/false).
// class AnimationScreen extends StatefulWidget {
//   const AnimationScreen({super.key});

//   @override
//   State<AnimationScreen> createState() => _AnimationScreenState();
// }

// class _AnimationScreenState extends State<AnimationScreen> {
//   // Zmienna trzymająca nasz stan (odpowiednik state = "TOP" w QML)
//   bool isTop = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFFFFF), // Tło aplikacji
      
//       // LayoutBuilder pozwala nam poznać dokładne wymiary dostępnego ekranu
//       // Potrzebujemy tego, aby obliczyć "horizontalCenter" tak jak w QML
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return Stack(
//             children: [
//               // --- NASZ ANIMOWANY OBIEKT ---
//               // AnimatedPositioned odpowiada za AnchorChanges i AnchorAnimation z QML
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeOutBack, // Odpowiednik Easing.OutBack
                
//                 // --- LOGIKA POZYCJONOWANIA (Odpowiednik Anchors) ---
//                 // Jeśli isTop: wyliczamy środek ekranu minus połowa szerokości (30)
//                 // W przeciwnym razie przytulamy do lewej (0)
//                 left: isTop ? (constraints.maxWidth / 2) - 30 : 0,
                
//                 // Jeśli isTop: 20px marginesu od góry. W przeciwnym razie: 0px.
//                 top: isTop ? 20 : 0,
                
//                 // Szerokość: 60 w stanie TOP, 120 w domyślnym
//                 width: isTop ? 60 : 120,
                
//                 // Wysokość: 60 w stanie TOP, w domyślnym rozciągamy na cały ekran (maxHeight)
//                 height: isTop ? 60 : constraints.maxHeight,

//                 // --- OBSŁUGA KLIKNIĘCIA I WYGLĄD ---
//                 // GestureDetector to odpowiednik TapHandler z QML
//                 child: GestureDetector(
//                   onTap: () {
//                     // Przełączamy stan i odświeżamy UI (odpowiednik box.state = ...)
//                     setState(() {
//                       isTop = !isTop;
//                     });
//                   },
                  
//                   // AnimatedContainer odpowiada za PropertyChanges i Number/ColorAnimation
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 250),
//                     curve: Curves.easeOutBack,
//                     decoration: BoxDecoration(
//                       // Animacja koloru
//                       color: isTop 
//                           ? const Color(0xFF00BFA5) 
//                           : const Color(0xFF6200EA),
//                       // Animacja zaokrąglenia (radius)
//                       borderRadius: BorderRadius.circular(isTop ? 30 : 0),
//                     ),
//                   ),
//                 ),
//               ),

//               // --- INSTRUKCJA DLA UŻYTKOWNIKA ---
//               // Align to najprostszy sposób na zakotwiczenie tekstu na dole na środku
//               const Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Padding(
//                   padding: EdgeInsets.only(bottom: 30),
//                   child: Text(
//                     "Kliknij na prostokąt!",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

//---------------------------------------------------------

// import 'dart:ui'; // Wymagane dla ImageFilter.blur
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Glassmorphism Animacja',
//       home: AnimationScreen(),
//     );
//   }
// }

// class AnimationScreen extends StatefulWidget {
//   const AnimationScreen({super.key});

//   @override
//   State<AnimationScreen> createState() => _AnimationScreenState();
// }

// class _AnimationScreenState extends State<AnimationScreen> {
//   bool isTop = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // --- KOLOROWE TŁO ---
//       // Żeby szkło miało co rozmywać, dodajemy ładny gradient w tle
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF), Color(0xFFA18CD1)],
//           ),
//         ),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
//                 // --- NASZ ANIMOWANY PANEL SZKLANY ---
//                 AnimatedPositioned(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeOutBack,
//                   left: isTop ? (constraints.maxWidth / 2) - 40 : 0,
//                   top: isTop ? 40 : 0,
//                   width: isTop ? 80 : 120,
//                   height: isTop ? 80 : constraints.maxHeight,
                  
//                   child: GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         isTop = !isTop;
//                       });
//                     },
                    
//                     // --- MAGIA SZKŁA (GLASSMORPHISM) ---
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeOutBack,
                      
//                       // INŻYNIERSKI SEKRET: To sprawia, że rozmycie (blur) 
//                       // nie wylewa się poza zaokrąglone rogi podczas animacji!
//                       clipBehavior: Clip.antiAlias, 
                      
//                       decoration: BoxDecoration(
//                         // Używamy kolorów z lekką przezroczystością (Opacity 0.3 = 30% widoczności)
//                         color: isTop 
//                             ? Colors.tealAccent.withOpacity(0.3) 
//                             : Colors.deepPurpleAccent.withOpacity(0.3),
                        
//                         borderRadius: BorderRadius.circular(isTop ? 40 : 0),
                        
//                         // Dodajemy bardzo cienką, półprzezroczystą ramkę, 
//                         // która odbija wirtualne "światło" na krawędzi szkła
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.4),
//                           width: 1.5,
//                         ),
//                       ),
                      
//                       // BackdropFilter aplikuje efekt rozmycia na wszystko, co jest pod nim
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Siła rozmycia
//                         child: const Center(
//                           // Pusty kontener, BackdropFilter wymaga jakiegoś dziecka
//                           child: SizedBox(), 
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // --- INSTRUKCJA ---
//                 const Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Padding(
//                     padding: EdgeInsets.only(bottom: 30),
//                     child: Text(
//                       "Kliknij na szkło!",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


//-----------------------------------------------------------

// import 'dart:ui';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Szkło na szachownicy',
//       home: AnimationScreen(),
//     );
//   }
// }

// class AnimationScreen extends StatefulWidget {
//   const AnimationScreen({super.key});

//   @override
//   State<AnimationScreen> createState() => _AnimationScreenState();
// }

// class _AnimationScreenState extends State<AnimationScreen> {
//   bool isTop = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return Stack(
//             children: [
//               // --- 1. TŁO: GENEROWANA SZACHOWNICA ---
//               // Positioned.fill rozciąga tło na cały ekran
//               Positioned.fill(
//                 child: CustomPaint(
//                   painter: CheckerboardPainter(),
//                 ),
//               ),

//               // --- 2. ANIMOWANY SZKLANY PANEL ---
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 400), // Lekko wydłużone, by podziwiać rozmycie
//                 curve: Curves.easeOutBack,
                
//                 // Pozycjonowanie i rozmiary (jak w poprzednim kodzie)
//                 left: isTop ? (constraints.maxWidth / 2) - 60 : 20,
//                 top: isTop ? 40 : 20,
//                 bottom: isTop ? null : 20, // Jeśli na górze odpinamy dół, inaczej margines 20px
//                 width: 120, // Stała szerokość dla lepszego efektu szkła
//                 height: isTop ? 120 : constraints.maxHeight - 40,
                
//                 child: GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       isTop = !isTop;
//                     });
//                   },
                  
//                   // --- 3. MAGIA SZKŁA NA SZACHOWNICY ---
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 400),
//                     curve: Curves.easeOutBack,
//                     clipBehavior: Clip.antiAlias, // Ścina rozmycie do zaokrągleń!
                    
//                     decoration: BoxDecoration(
//                       // Półprzezroczysty biały kolor udający zmatowienie szyby
//                       color: Colors.white.withOpacity(0.15),
                      
//                       // Animacja zaokrągleń: Pasek -> Kółko
//                       borderRadius: BorderRadius.circular(isTop ? 60 : 20),
                      
//                       // Cienka ramka imitująca odbicie światła na krawędzi szkła
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.5),
//                         width: 1.5,
//                       ),
                      
//                       // Opcjonalny, bardzo delikatny cień rzucany przez sam panel
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           blurRadius: 15,
//                           spreadRadius: 2,
//                         )
//                       ]
//                     ),
                    
//                     // Filtr rozmywający to, co jest pod spodem (szachownicę)
//                     child: BackdropFilter(
//                       filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
//                       child: Center(
//                         // Zawartość na szkle (Tekst/Ikona)
//                         child: Icon(
//                           isTop ? Icons.touch_app : Icons.swipe_up,
//                           color: Colors.white,
//                           size: 40,
//                           // Cień pod ikoną, by była widoczna na czarno-białym tle
//                           shadows: const [Shadow(color: Colors.black87, blurRadius: 10)],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// // --- NARZĘDZIE INŻYNIERSKIE: RYSOWNIK SZACHOWNICY ---
// // Rysuje idealną siatkę kwadratów bezpośrednio na Canvasie.
// class CheckerboardPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paintBlack = Paint()..color = const Color(0xFF222222); // Ciemny szary
//     final paintWhite = Paint()..color = const Color(0xFFDDDDDD); // Jasny szary
    
//     const double squareSize = 30.0; // Rozmiar pojedynczego kwadratu w pikselach

//     for (double y = 0; y < size.height; y += squareSize) {
//       for (double x = 0; x < size.width; x += squareSize) {
//         int row = (y / squareSize).floor();
//         int col = (x / squareSize).floor();
        
//         // Co drugi kwadrat ma inny kolor
//         final paint = (row + col) % 2 == 0 ? paintBlack : paintWhite;
        
//         canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
//       }
//     }
//   }

//   // Szachownica jest statyczna, nie musi się przerysowywać co klatkę
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }