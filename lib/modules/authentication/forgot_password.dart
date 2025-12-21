import 'package:einventorycomputer/services/auth.dart';
import 'package:einventorycomputer/shared/loading.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool loading = false;
  String error = '';
  String success = '';

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
        error = '';
        success = '';
      });

      try {
        await _auth.resetPassword(_emailController.text.trim());
        setState(() {
          loading = false;
          success = 'Password reset email sent! Check your inbox.';
        });
        
        // Auto-navigate back after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } catch (e) {
        String errorMessage = 'An error occurred. Please try again.';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No user found with this email address.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many attempts. Please try again later.';
        }
        
        setState(() {
          loading = false;
          error = errorMessage;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: const Color(0xFF81D4FA),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Enter your email to reset password',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(44)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  const Icon(
                                    Icons.lock_reset,
                                    size: 80,
                                    color: Color(0xFF81D4FA),
                                  ),
                                  const SizedBox(height: 30),
                                  const Text(
                                    'Reset Your Password',
                                    style: TextStyle(
                                      fontFamily: 'SansRegular',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Enter your email address and we\'ll send you a link to reset your password.',
                                    style: TextStyle(
                                      fontFamily: 'SansRegular',
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      fontFamily: 'SansRegular',
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your email',
                                      hintStyle: TextStyle(
                                        fontFamily: 'SansRegular',
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!val.contains('@') || !val.contains('.')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Send Reset Link',
                                      style: TextStyle(
                                        fontFamily: 'SansRegular',
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (error.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error, color: Colors.red.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              error,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 14,
                                                fontFamily: 'SansRegular',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (success.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              success,
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 14,
                                                fontFamily: 'SansRegular',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 30),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Back to Sign In',
                                      style: TextStyle(
                                        fontFamily: 'SansRegular',
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}