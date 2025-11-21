import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'bloc/auth/auth_cubit.dart';
import 'bloc/wardrobe/wardrobe_bloc.dart';
import 'bloc/outfit/outfit_cubit.dart';
import 'bloc/recommendation/recommendation_bloc.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/wardrobe/wardrobe_screen.dart';
import 'screens/wardrobe/add_item_screen.dart';
import 'screens/outfit/outfit_planner_screen.dart';
import 'screens/outfit/outfit_calendar_screen.dart';
import 'screens/recommendations/recommendation_screen.dart';
import 'screens/shopping/shopping_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
// Replace your current App Check activation with this:
  if (kReleaseMode) {
    // production: prefer Play Integrity (ensure Play App Signing & config in Play Console)
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  } else {
    // development: debug provider — register the printed debug token in Firebase Console
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }

  // Avoid "X-Firebase-Locale ... value was null" by explicitly setting language (or set per-user)
  FirebaseAuth.instance.setLanguageCode('en');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => WardrobeBloc()),
        BlocProvider(create: (_) => OutfitCubit()),
        BlocProvider(create: (_) => RecommendationBloc()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        navigatorObservers: [observer],
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/wardrobe': (context) => const WardrobeScreen(),
          '/add-item': (context) => const AddItemScreen(),
          '/outfit-planner': (context) => const OutfitPlannerScreen(),
          '/outfit-calendar': (context) => const OutfitCalendarScreen(),
          '/recommendations': (context) => const RecommendationScreen(),
          '/shopping': (context) => const ShoppingScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
