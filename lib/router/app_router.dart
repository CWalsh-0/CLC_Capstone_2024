import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutterdb/BookingForm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterdb/forgot_password_page.dart';
import 'package:flutterdb/login_page.dart';
import 'package:flutterdb/manage_bookings_page.dart';
import 'package:flutterdb/signup_page.dart';
import 'package:go_router/go_router.dart';
import '../homepage.dart';
import '../new_booking_page.dart';
import '../SchedulingLandingScreen.dart';
import 'package:flutter/material.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    final isOnAuthPage = state.matchedLocation == '/sign-in' ||
        state.matchedLocation == '/sign-up' ||
        state.matchedLocation == '/forgot-password';

    if (user == null && !isOnAuthPage) return '/sign-in';
    if (user != null && isOnAuthPage) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(title: "Home"),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
        path: '/new-booking',
        builder: (context, state) {
          final _focusedDay = state.extra as DateTime;
          return NewBookingPage(focusedDay: _focusedDay);
        }),
    GoRoute(
      path: '/manage-bookings',
      builder: (context, state) => ManageBookingPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(
        providers: const [],
        actions: [
          SignedOutAction((context) {
            context.go('/sign-in');
          }),
        ],
      ),
    ),
    GoRoute(
      path: '/scheduling/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SchedulingLandingScreen(documentId: id);
      },
    ),
    GoRoute(path: '/algorithm', builder: (context, state) => BookingPage())
  ],
);







// import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutterdb/forgot_password_page.dart';
// import 'package:flutterdb/login_page.dart';
// import 'package:flutterdb/manage_bookings_page.dart';
// import 'package:flutterdb/signup_page.dart';
// import 'package:go_router/go_router.dart';
// import '../homepage.dart';
// import '../new_booking_page.dart';
// import '../SchedulingLandingScreen.dart';
// import 'package:flutter/material.dart';

// final appRouter = GoRouter(
//   initialLocation: '/',
//   redirect: (BuildContext context, GoRouterState state) {
//     // Get current user
//     final user = FirebaseAuth.instance.currentUser;
    
//     // Check if the user is not on the authentication pages
//     final isOnAuthPage = state.matchedLocation == '/sign-in' || 
//                         state.matchedLocation == '/sign-up';

//     // If there's no user and we're not on an auth page, redirect to sign-in
//     if (user == null && !isOnAuthPage) {
//       return '/sign-in';
//     }

//     // If user is authenticated and trying to access auth pages, redirect to home
//     if (user != null && isOnAuthPage) {
//       return '/';
//     }

//     // No redirect needed
//     return null;
//   },
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => const MyHomePage(title: "Home"),
//     ),
    
//     // Auth routes at root level
//     GoRoute(
//       path: '/sign-in',
//       builder: (context, state) => const LoginPage(),
//       routes: [
//         GoRoute(
//           path: 'forgot-password',
//           builder: (context, state) {
//             return ForgotPasswordScreen(
//               headerMaxExtent: 200,
//             );
//           },
//         ),
//       ],
//     ),
    
//     GoRoute(
//       path: '/sign-up',
//       builder: (context, state) => SignupScreen(),
//     ),

//     GoRoute(
//       path: '/forgot-password',
//       builder: (context, state) {
//         return ForgotPasswordScreen(
//           headerMaxExtent: 200,
//         );
//       },
//     ),

//     GoRoute(
//       path: '/new-booking',
//       builder: (context, state) =>  NewBookingPage(),
//     ),

//      GoRoute(
//       path: '/forgot-password',
//       builder: (context, state) =>  ForgotPasswordPage(),
//     ),
    
//     GoRoute(
//       path: '/manage-bookings',
//       builder: (context, state) =>  ManageBookingPage(),
//     ),
//     GoRoute(
//       path: '/profile',
//       builder: (context, state) => ProfileScreen(
//         providers: const [],
//         actions: [
//           SignedOutAction((context) {
//             context.go('/sign-in');
//           }),
//         ],
//       ),
//     ),
    
//     GoRoute(
//       path: '/scheduling/:id',
//       builder: (context, state) {
//         final id = state.pathParameters['id']!;
//         return SchedulingLandingScreen(documentId: id);
//       },
//     ),
//   ],
// );




// // import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// // import 'package:flutterdb/login_page.dart';
// // import 'package:flutterdb/signup_page.dart';
// // import 'package:go_router/go_router.dart';
// // import '../homepage.dart';
// // import '../SchedulingLandingScreen.dart';

// // final appRouter = GoRouter(
// //   routes: [
// //     GoRoute(
// //       path: '/',
// //       builder: (context, state) => const MyHomePage(title: "Home"),
// //       routes: [
// //         _signInRoute,
// //         _signUpRoute,
// //         _profileRoute,
// //         _forgotPassword,
// //         schedulingLandingRoute()
// //       ],
// //     ),
// //   ],
// // );

// // final GoRoute _signInRoute = GoRoute(
// //     path: 'sign-in',
// //     builder: (context, state) => const LoginPage(),
// //     routes: [
// //       GoRoute(
// //         path: 'forgot-password',
// //         builder: (context, state) {
// //           return ForgotPasswordScreen(
// //             headerMaxExtent: 200,
// //           );
// //         },
// //       ),
// //     ]);

// // final GoRoute _signUpRoute =
// //     GoRoute(path: 'sign-up', builder: (context, state) => SignupScreen());

// // final GoRoute _forgotPassword = GoRoute(
// //   path: 'forgot-password',
// //   builder: (context, state) {
// //     return ForgotPasswordScreen(
// //       headerMaxExtent: 200,
// //     );
// //   },
// // );

// // // Profile Route
// // final GoRoute _profileRoute = GoRoute(
// //   path: 'profile',
// //   builder: (context, state) => ProfileScreen(
// //     providers: const [],
// //     actions: [
// //       SignedOutAction((context) => context.pushReplacement('/')),
// //     ],
// //   ),
// // );

// // GoRoute schedulingLandingRoute() {
// //   return GoRoute(
// //     path: 'scheduling/:id', //  Dynamic route with document ID
// //     builder: (context, state) {
// //       final id = state.pathParameters['id']!;
// //       return SchedulingLandingScreen(documentId: id);
// //     },
// //   );
// // }
