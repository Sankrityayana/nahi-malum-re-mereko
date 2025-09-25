import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isSignup = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.loading ? null : () async {
                if (isSignup) {
                  await auth.signUp(emailCtrl.text, passCtrl.text);
                } else {
                  await auth.signIn(emailCtrl.text, passCtrl.text);
                }
              },
              child: Text(isSignup ? 'Sign Up' : 'Login'),
            ),
            TextButton(
              onPressed: () => setState(() => isSignup = !isSignup),
              child: Text(isSignup ? 'Have an account? Login' : "New here? Sign up"),
            )
          ],
        ),
      ),
    );
  }
}
