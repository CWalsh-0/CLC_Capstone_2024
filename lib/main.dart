import 'package:flutterdb/homeassistant/ha_start.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // new
import 'app_state.dart'; // new
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'router/app_router.dart'; // Import your new router file

void main() {
  print("I'M ALIVE");
  //Moved Home Assistant Inits to ha_start.dart
  //fetchData(homeAssistant);
  WidgetsFlutterBinding.ensureInitialized();
  //Provider: ChangeNotifierProvider is responsible for init the app state & for state management
  runApp(ChangeNotifierProvider(
    //create app state
    create: (context) => ApplicationState(),
    //call back interface to parent widget to return a child of that widget i.e ChangeNotifierProvider
    builder: ((context, child) => const MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Firebase Meetup',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.lightGreen,
            ),
        primarySwatch: Colors.lightGreen,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: appRouter, // new
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
}

/** old -> move new routes to app_router.dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(title: "Home"),
      routes: [
        GoRoute(
          path: 'sign-in',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: 'sign-up',
          builder: (context, state) => SignupScreen(),
        ),
        GoRoute(
          path: 'forgot-password',
          builder: (context, state) {
            return ForgotPasswordScreen(
              headerMaxExtent: 200,
            );
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) {
            return ProfileScreen(
              providers: const [],
              actions: [
                SignedOutAction((context) {
                  context.pushReplacement('/');
                }),
              ],
            );
          },
        ),
      ],
    ),
  ],
);
*/
