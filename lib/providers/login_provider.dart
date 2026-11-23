import 'package:flutter/material.dart';

class LoginProvider extends ChangeNotifier {
  bool _isObscure = true;
  bool get isObscure => _isObscure;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void toggleVisibility() {
    _isObscure = !_isObscure;
    notifyListeners();
  }

  void clear() {
    emailController.clear();
    passwordController.clear();
    _isObscure = true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
