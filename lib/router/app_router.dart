import 'package:firebase_ui_auth/firebase_ui_auth.dart';
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
        schedulingLandingRoute()
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

GoRoute schedulingLandingRoute() {
  return GoRoute(
    path: 'scheduling/:id', // 🔹 Dynamic route with document ID
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return SchedulingLandingScreen(documentId: id);
    },
  );
}
