import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../homepage.dart';
import '../SchedulingLandingScreen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(title: "Home"),
      routes: [_signInRoute, _profileRoute, schedulingLandingRoute()],
    ),
  ],
);

final GoRoute _signInRoute = GoRoute(
    path: 'sign-in',
    builder: (context, state) {
      return SignInScreen(
        //actions available
        actions: [
          ForgotPasswordAction(((context, email) {
            final uri = Uri(
              path: '/sign-in/forgot-password',
              queryParameters: <String, String?>{
                'email': email,
              },
            );
            context.push(uri.toString());
          })),
          AuthStateChangeAction(((context, state) {
            final user = switch (state) {
              SignedIn state => state.user,
              UserCreated state => state.credential.user,
              _ => null
            };
            if (user == null) {
              return;
            }
            if (state is UserCreated) {
              user.updateDisplayName(user.email!.split('@')[0]);
            }
            if (!user.emailVerified) {
              user.sendEmailVerification();
              const snackBar = SnackBar(
                  content: Text(
                      'Please check your email to verify your email address'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            context.pushReplacement('/');
          })),
        ],
      );
    },
    routes: [
      GoRoute(
        path: 'forgot-password',
        builder: (context, state) {
          final arguments = state.uri.queryParameters;
          return ForgotPasswordScreen(
            email: arguments['email'],
            headerMaxExtent: 200,
          );
        },
      ),
    ]);

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
