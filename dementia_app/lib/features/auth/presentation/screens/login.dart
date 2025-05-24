import 'package:dementia_app/core/logging/logger.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/auth/presentation/providers/auth_service.dart';
import 'package:dementia_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup.dart';

class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  LoginPage({super.key});

  void login(BuildContext context) async {
    String email = emailController.text;
    String password = passwordController.text;

    AuthService authService = AuthService();

    try {
      UserModel user = await authService.login(email, password);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login successful. Welcome back, ${user.firstName}!')));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return const HomeScreen();
      }));
    } catch (e) {
      logger.e('Login failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Login failed. Please check your credentials and try again.')));
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final forgotPasswordEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: forgotPasswordEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                icon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _auth.sendPasswordResetEmail(
                  email: forgotPasswordEmailController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Password reset email sent. Please check your email.'),
                    duration: Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                logger.e('Error sending password reset email: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sending reset email: ${e.toString()}'),
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Topmost image
            SizedBox(
              height: size.height / 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.asset(
                  'assets/images/login.jpg', // Use your image here
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Login',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    child: Column(
                      children: [
                        // Email field
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.alternate_email_outlined),
                            labelText: 'Email ID',
                          ),
                          controller: emailController,
                        ),
                        // Password field
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.lock_outline_rounded),
                            labelText: 'Password',
                          ),
                          controller: passwordController,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  // Login Button
                  ElevatedButton(
                    onPressed: () {
                      // Call login function
                      login(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Center(
                        child: Text(
                      "Login",
                      style: TextStyle(fontSize: 15),
                    )),
                  ),
                  const SizedBox(height: 25),
                  // Register Button (navigate to SignUpPage)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        GestureDetector(
                          child: const Text(
                            "Register",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo),
                          ),
                          onTap: () {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) {
                              return const SignUpPage();
                            }));
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
