// lib/modules/auth/screens/login_screen.dart
import 'package:famradar/models/user_model.dart';
import 'package:famradar/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../interfaces/auth_service_interface.dart';

class LoginScreen extends StatefulWidget {
  final AuthServiceInterface authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final provider = context.read<AppProvider>();
    UserModel? user;
    if (_usePhone) {
      user = await widget.authService.signInWithPhone(
        _phoneController.text,
        _passwordController.text,
      );
    } else {
      user = await widget.authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    }
    if (user != null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FamRadar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_usePhone)
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              )
            else
              IntlPhoneField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                initialCountryCode: 'BR',
              ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () => setState(() => _usePhone = !_usePhone),
              child: Text(_usePhone ? 'Use Email' : 'Use Phone'),
            ),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Don’t have an account? Sign Up'),
            ),
            if (context.read<AppProvider>().errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  context.read<AppProvider>().errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
