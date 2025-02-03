import 'package:basic_ui_2/constants.dart';
import 'package:basic_ui_2/screens/home/home.dart';
import 'package:flutter/material.dart';
import '../../components/login_form.dart';
import 'package:basic_ui_2/route/route_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _email = '';
  String _password = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final User? currentUser = _auth.currentUser;

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Only navigate if both SharedPreferences and Firebase show logged in
      if (isLoggedIn && currentUser != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const Home(),
            settings: const RouteSettings(name: 'Home'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      // Changed from WillPopScope to PopScope
      canPop: false, // This replaces onWillPop
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                "assets/images/login.png",
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back!",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    const Text(
                      "Log in with your data that you entered during registration.",
                    ),
                    const SizedBox(height: defaultPadding),
                    LogInForm(
                      formKey: _formKey,
                      onEmailChanged: _onEmailChanged,
                      onPasswordChanged: _onPasswordChanged,
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    ElevatedButton(
                      onPressed: _login,
                      child: const Text("Log in"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, signUpScreenRoute);
                          },
                          child: const Text("Sign up"),
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onEmailChanged(String value) => setState(() => _email = value);
  void _onPasswordChanged(String value) => setState(() => _password = value);

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // First authenticate with Firebase Auth
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email.trim(),
          password: _password.trim(),
        );

        // Get user data from Firestore
        final User? user = userCredential.user;
        final userData =
            await FirestoreService.getUser(userCredential.user!.uid);
        if (userData != null) {
          final uid = user?.uid;
          print('Logged-in user UID: $uid'); // Print the UID here
          // Save login state with user data
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', _email.trim());
          await prefs.setString('userId', userCredential.user?.uid ?? '');
          await prefs.setString(
              'userName', userData.fullName); // Store user's name
          // Show success message
          _showToast("Login successful!", isError: false);
          // Navigate to Home screen
          if (mounted) {
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const Home(),
                  settings: const RouteSettings(name: 'Home'),
                ),
                (route) => false,
              );
            }
          }
        } else {
          // Handle case where user exists in Auth but not in Firestore
          _showToast("User data not found. Please contact support.",
              isError: true);
          await _auth.signOut(); // Sign out since data is inconsistent
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'No account found with this email. Please sign up.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            message = 'Invalid email or password. Please try again.';
            break;
          case 'invalid-email':
            message = 'The email address is not valid. Please check again.';
            break;
          case 'too-many-requests':
            message = 'Too many failed attempts. Please try again later.';
            break;
          case 'user-disabled':
            message = 'This account has been disabled. Please contact support.';
            break;
          default:
            message = 'Login failed. Please try again.';
        }
        _showToast(message, isError: true);
      } on FirebaseException catch (e) {
        _showToast(FirestoreService.getErrorMessage(e), isError: true);
      } catch (e) {
        _showToast("An unexpected error occurred. Please try again.",
            isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
