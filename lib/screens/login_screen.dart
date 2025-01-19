import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_memorizer/screens/home_screen.dart';
import 'package:word_memorizer/services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? 'Create an account' : 'Already have an account?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success;
      if (_isLogin) {
        success = await authService.login(_usernameController.text, _passwordController.text);
      } else {
        success = await authService.register(_usernameController.text, _passwordController.text);
        if (success) {
          success = await authService.login(_usernameController.text, _passwordController.text);
        }
      }

      if (success) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isLogin ? 'Login failed' : 'Registration failed')),
        );
      }
    }
  }
}
