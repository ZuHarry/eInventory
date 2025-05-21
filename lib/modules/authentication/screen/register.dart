import 'package:einventorycomputer/services/auth.dart';
import 'package:einventorycomputer/shared/loading.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  final TextEditingController _usernameController = TextEditingController(); // Not used in auth
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();

  bool _obscurePassword = true;
  String error = '';

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      dynamic result = await _auth.registerWithEmailAndPassword(
        _fullnameController.text.trim(),
         _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (result == null) {
        setState(() {
          error = 'Please supply a valid email';
          loading = false;
        });
      } else {
        Navigator.pop(context); // Registration successful, go back to login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            appBar: AppBar(title: const Text("Register")),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // Fullname
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Full Name', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _fullnameController,
                            decoration: _inputDecoration('Username', Icons.person),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Enter Your Full Name' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Username
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Username', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _inputDecoration('Username', Icons.person),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Enter a username' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Email
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Email', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email', Icons.email),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Enter an email' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Password', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _passwordDecoration('Password'),
                            validator: (val) => val == null || val.length < 6
                                ? 'Enter a password 6+ chars long'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Confirm Your Password', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmpasswordController,
                            obscureText: _obscurePassword,
                            decoration: _passwordDecoration('Confirm Password'),
                            validator: (val) => val != _passwordController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Register'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      prefixIcon: Icon(icon),
    );
  }

  InputDecoration _passwordDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }
}
