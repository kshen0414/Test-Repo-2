import 'package:basic_ui_2/screens/home/home.dart';
import 'package:basic_ui_2/screens/user/welcome_screen.dart';
import 'package:basic_ui_2/services/auth_service.dart';
import 'package:basic_ui_2/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:basic_ui_2/route/router.dart' as router;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/receipt_provider.dart';
import 'providers/expense_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize providers with preloaded data
  final expenseProvider = ExpenseProvider();
  final receiptProvider = ReceiptProvider();

  // Preload data in parallel
  await Future.wait([
    expenseProvider.initializeData(),
    receiptProvider.initializeData(),
  ]);

  FlutterNativeSplash.remove();


  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => expenseProvider,
        ),
        ChangeNotifierProvider<ReceiptProvider>(
          create: (_) => receiptProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Tracker',
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      home: StreamBuilder<User?>(
        stream: context.read<AuthService>().authStateChanges,
        builder: (context, snapshot) {
          // Show loading indicator while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If user is logged in, show home screen
          if (snapshot.hasData) {
            return const Home();
          }

          // If user is not logged in, show welcome screen
          return const WelcomeScreen();
        },
      ),
    );
  }
}
