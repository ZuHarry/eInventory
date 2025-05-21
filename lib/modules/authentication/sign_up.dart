import 'package:einventorycomputer/services/auth.dart';
import 'package:einventorycomputer/shared/loading.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  final Function toggleView;
  const SignUp({required this.toggleView, super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController = TextEditingController();

  bool _obscurePassword = true;
  String error = '';

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      dynamic result = await _auth.registerWithEmailAndPassword(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (result == null) {
        setState(() {
          error = 'Please supply a valid email';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            appBar: AppBar(title: const Text("Sign Up")),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildInputField(
                        label: 'Your Username',
                        controller: _usernameController,
                        icon: Icons.person,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter a username' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Your Email',
                        controller: _emailController,
                        icon: Icons.email,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter an email' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        label: 'Your Password',
                        controller: _passwordController,
                        validator: (val) => val == null || val.length < 6
                            ? 'Enter a password 6+ chars long'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        label: 'Confirm Your Password',
                        controller: _confirmpasswordController,
                        validator: (val) => val != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
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
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => widget.toggleView(),
                        child: const Text("Already have an account? Sign In"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(label, icon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          decoration: _passwordDecoration(label),
          validator: validator,
        ),
      ],
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
