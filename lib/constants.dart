import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';




const double defaultPadding = 16.0;
const Color primaryColor = Color(0xFF7B61FF);
const double defaultBorderRadious = 12.0;

const MaterialColor primaryMaterialColor =
    MaterialColor(0xFF9581FF, <int, Color>{
  50: Color(0xFFEFECFF),
  100: Color(0xFFD7D0FF),
  200: Color(0xFFBDB0FF),
  300: Color(0xFFA390FF),
  400: Color(0xFF8F79FF),
  500: Color(0xFF7B61FF),
  600: Color(0xFF7359FF),
  700: Color(0xFF684FFF),
  800: Color(0xFF5E45FF),
  900: Color(0xFF6C56DD),
});

const Color blackColor40 = Color(0xFFA2A2A5);
const Color blackColor = Color(0xFF16161E);
const Color blackColor10 = Color(0xFFE8E8E9);

const Color whileColor80 = Color(0xFFCCCCCC);
const Color whileColor60 = Color(0xFF999999);
const Color whileColor40 = Color(0xFF666666);
const Color whileColor20 = Color(0xFF333333);
const Color whileColor10 = Color(0xFF191919);
const Color whileColor5 = Color(0xFF0D0D0D);

const Color errorColor = Color(0xFFEA5B5B);

const Color lightGreyColor = Color(0xFFF8F8F9);
const Color greyColor = Color(0xFFB8B5C3);
const Color darkGreyColor = Color(0xFF1C1C25);

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])',
  errorText: 'passwords must have at least one special character')
]);

final emailValidator = MultiValidator([
  RequiredValidator(errorText: 'Please enter your email'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const pasNotMatchErrorText = "passwords do not match";