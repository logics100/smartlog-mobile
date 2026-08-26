import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'student_home_screen.dart';
import 'lecturer_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.login(
        login: loginController.text.trim(),
        password: passwordController.text,
      );

      final user = result['user'];
      final role = user['role'];

      if (!mounted) return;

      if (role == 'STUDENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentHomeScreen(user: user),
          ),
        );
      } else if (role == 'LECTURER') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LecturerHomeScreen(user: user),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'This role is not available in the mobile app yet.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Login failed. Check your email/DWU ID, password, and Laravel server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'SmartLog',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text('Digital Clinical Logbook'),

                const SizedBox(height: 40),

                TextField(
                  controller: loginController,
                  decoration: const InputDecoration(
                    labelText: 'DWU ID or Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 16),

                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}