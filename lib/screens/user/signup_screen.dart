import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:basic_ui_2/components/sign_up_form.dart';
import 'package:basic_ui_2/route/route_constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../constants.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  void _onNameChanged(String value) => setState(() => _name = value);
  void _onEmailChanged(String value) => setState(() => _email = value);
  void _onPasswordChanged(String value) => setState(() => _password = value);
  void _onConfirmPasswordChanged(String value) =>
      setState(() => _confirmPassword = value);

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_password != _confirmPassword) {
        _showToast("Passwords do not match", isError: true);
        return;
      }
      try {
        // Try to create auth account
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email.trim(),
          password: _password.trim(),
        );
        if (userCredential.user != null) {
          // Update auth profile
          await userCredential.user!.updateDisplayName(_name.trim());
          // Create user model
          final user = UserModel(
            id: userCredential.user!.uid,
            email: _email.trim(),
            // password: _password.trim(),
            fullName: _name.trim(),
            // phoneNo: '',
          );
          // Save to Firestore using service
          await FirestoreService.createUser(user, userCredential.user!.uid);
          _showToast(
            "Account created successfully! Please login.",
            isError: false,
          );
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, logInScreenRoute);
          });
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = 'This email is already registered. Please login instead.';
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address.';
            break;
          case 'operation-not-allowed':
            message = 'Email/password signup is not enabled.';
            break;
          case 'weak-password':
            message = 'Password is too weak. Please use a stronger password.';
            break;
          default:
            message = 'Signup failed: ${e.message}';
        }
        _showToast(message, isError: true);
      } catch (e) {
        _showToast('An unexpected error occurred. Please try again.',
            isError: true);
        print('Error during signup: $e'); // For debugging
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                "assets/images/register.png",
                fit: BoxFit.cover,
                width: 350, // Set a specific width
                height: 350, // Set a specific height
              ),
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's get started!",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    const Text(
                      "Please enter your valid data in order to create an account.",
                    ),
                    const SizedBox(height: defaultPadding),
                    SignUpForm(
                      formKey: _formKey,
                      onNameChanged: _onNameChanged,
                      onEmailChanged: _onEmailChanged,
                      onPasswordChanged: _onPasswordChanged,
                      onConfirmPasswordChanged: _onConfirmPasswordChanged,
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    ElevatedButton(
                      onPressed: _signUp,
                      child: const Text("Sign Up"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Do you have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, logInScreenRoute);
                          },
                          child: const Text("Log in"),
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
}
