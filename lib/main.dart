import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // new
import 'app_state.dart'; // new
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
// Home Assistant Imports
import 'package:home_assistant/home_assistant.dart';
import 'src/home_assistant_config.dart'; // new
import 'router/app_router.dart'; // Import your new router file

void main() {
  print("I'M ALIVE");
  //Home Assistant Inits
  final HomeAssistant homeAssistant = HomeAssistant(
      baseUrl: HomeAssistantConfig.baseUrl,
      bearerToken: HomeAssistantConfig.token);
  fetchData(homeAssistant);

  WidgetsFlutterBinding.ensureInitialized();
  //Provider: ChangeNotifierProvider is responsible for init the app state & for state management
  runApp(ChangeNotifierProvider(
    //create app state
    create: (context) => ApplicationState(),
    //call back interface to parent widget to return a child of that widget i.e ChangeNotifierProvider
    builder: ((context, child) => const MyApp()),
  ));
}

fetchData(HomeAssistant homeAssistant) async {
  print("The API is working: ${await homeAssistant.verifyApiIsWorking()}");

  //final Configuration config = await homeAssistant.fetchConfig();
  //print(config.toJson());

  //final List<Entity> entities = await homeAssistant.fetchStates();
  //print(entities.);

  final Entity entity =
      await homeAssistant.fetchState("light.esphome_web_60beb8_test_light");
  print(entity.attributes.brightness);

  //final List<Service> services = await homeAssistant.fetchServices();
  //print(services.first.domain);

  //Dummy Services
  homeAssistant.executeService("light.esphome_web_60beb8_test_light", "turn_on",
      additionalActions: {
        "brightness": 50,
      });

  await Future.delayed(Duration(seconds: 1));
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
