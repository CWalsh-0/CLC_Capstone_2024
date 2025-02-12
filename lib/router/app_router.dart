import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutterdb/BookingForm.dart';
import 'package:flutterdb/login_page.dart';
import 'package:flutterdb/signup_page.dart';
import 'package:go_router/go_router.dart';
import '../homepage.dart';
import '../SchedulingLandingScreen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(title: "Home"),
      routes: [
        _signInRoute,
        _signUpRoute,
        _profileRoute,
        _forgotPassword,
        schedulingLandingRoute(),
        _algorithmLandingRoute
      ],
    ),
  ],
);

final GoRoute _signInRoute = GoRoute(
    path: 'sign-in',
    builder: (context, state) => const LoginPage(),
    routes: [
      GoRoute(
        path: 'forgot-password',
        builder: (context, state) {
          return ForgotPasswordScreen(
            headerMaxExtent: 200,
          );
        },
      ),
    ]);

final GoRoute _signUpRoute =
    GoRoute(path: 'sign-up', builder: (context, state) => SignupScreen());

final GoRoute _algorithmLandingRoute =
    GoRoute(path: 'algorithm', builder: (context, state) => BookingPage());

final GoRoute _forgotPassword = GoRoute(
  path: 'forgot-password',
  builder: (context, state) {
    return ForgotPasswordScreen(
      headerMaxExtent: 200,
    );
  },
);

// 🔹 Profile Route
final GoRoute _profileRoute = GoRoute(
  path: 'profile',
  builder: (context, state) => ProfileScreen(
    providers: const [],
    actions: [
      SignedOutAction((context) => context.pushReplacement('/')),
    ],
  ),
);

// Remove this later
GoRoute schedulingLandingRoute() {
  return GoRoute(
    path: 'scheduling/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return SchedulingLandingScreen(documentId: id);
    },
  );
}
/** 
GoRoute algorithmLandingRoute() {
  return GoRoute(
    path: 'algorithmsss', // dynamic route with space ID
    builder: (context, state) {
      // TODO FOR DYNAMIC ROOMS
      // room_67890
      final id = state.pathParameters['id']!;
      //return BookingForm();
    },
  );
}
*/
