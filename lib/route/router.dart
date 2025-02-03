import 'package:basic_ui_2/route/route_constants.dart';
import 'package:flutter/material.dart';
import 'screen_export.dart';


Route<dynamic> generateRoute(RouteSettings settings){
  switch (settings.name){
    case logInScreenRoute:
      return MaterialPageRoute(builder: (context) => const LoginScreen(),);
    case signUpScreenRoute:
    return MaterialPageRoute(builder: (context)=> const SignUpScreen(), );
    default:
      return MaterialPageRoute(builder: (context)=>const LoginScreen(),);
  }
}