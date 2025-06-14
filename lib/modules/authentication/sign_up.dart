import 'package:einventorycomputer/services/auth.dart';
import 'package:einventorycomputer/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:einventorycomputer/modules/authentication/verify_email.dart';

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
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureReferralCode = true;
  String error = '';
  
  // Staff type dropdown
  String? _selectedStaffType;
  final List<String> _staffTypes = ['Staff', 'Lecturer', 'Technician'];
  
  // Referral code constant
  static const String _validReferralCode = "ABC123";

  void _register() async {
    if (_formKey.currentState!.validate()) {
      // Check referral code first
      if (_referralCodeController.text.trim() != _validReferralCode) {
        setState(() {
          error = 'Invalid referral code. Please contact your administrator.';
        });
        return;
      }

      setState(() => loading = true);

      dynamic result = await _auth.registerWithEmailAndPassword(
        _fullnameController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _telephoneController.text.trim(),
        _selectedStaffType!,
        _staffIdController.text.trim(),
      );

      if (result == null) {
        setState(() {
          error = 'Please supply a valid email';
          loading = false;
        });
      } else {
        if (mounted) {
          setState(() => loading = false);
          // Navigate to email verification with callback to return to sign in
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmail(
                onVerificationComplete: () {
                  // Pop the verification screen and go back to sign in
                  Navigator.pop(context);
                  widget.toggleView(); // This will switch to sign in page
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email verified successfully! You can now sign in.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: const Color(0xFFFFC727),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () => widget.toggleView(),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Register',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your account',
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                label: 'Your Fullname',
                                controller: _fullnameController,
                                icon: Icons.person,
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Enter your fullname' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                label: 'Your Username',
                                controller: _usernameController,
                                icon: Icons.person,
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Enter a username' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                label: 'Staff ID',
                                controller: _staffIdController,
                                icon: Icons.badge,
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Enter your staff ID' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                label: 'Your Email',
                                controller: _emailController,
                                icon: Icons.email,
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Enter an email' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                label: 'Telephone Number',
                                controller: _telephoneController,
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Enter your telephone number' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildStaffTypeDropdown(),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: 'Your Password',
                                controller: _passwordController,
                                validator: (val) => val == null || val.length < 6
                                    ? 'Enter a password 6+ chars long'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: 'Confirm Your Password',
                                controller: _confirmpasswordController,
                                validator: (val) => val != _passwordController.text
                                    ? 'Passwords do not match'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildReferralCodeField(),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontFamily: 'SansRegular',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (error.isNotEmpty)
                                Text(
                                  error,
                                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontFamily: 'SansRegular'),
          decoration: _inputDecoration(label, icon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildStaffTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staff Type',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStaffType,
          decoration: InputDecoration(
            labelText: 'Select Staff Type',
            labelStyle: const TextStyle(fontFamily: 'SansRegular'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            prefixIcon: const Icon(Icons.work),
          ),
          items: _staffTypes.map((String staffType) {
            return DropdownMenuItem<String>(
              value: staffType,
              child: Text(
                staffType,
                style: const TextStyle(fontFamily: 'SansRegular'),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedStaffType = newValue;
            });
          },
          validator: (value) => value == null ? 'Please select a staff type' : null,
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
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          style: const TextStyle(fontFamily: 'SansRegular'),
          decoration: _passwordDecoration(label),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildReferralCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Referral Code',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _referralCodeController,
          obscureText: _obscureReferralCode,
          style: const TextStyle(fontFamily: 'SansRegular'),
          decoration: InputDecoration(
            labelText: 'Enter referral code',
            labelStyle: const TextStyle(fontFamily: 'SansRegular'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            prefixIcon: const Icon(Icons.vpn_key),
            suffixIcon: IconButton(
              icon: Icon(_obscureReferralCode ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscureReferralCode = !_obscureReferralCode;
                });
              },
            ),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Enter a referral code' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'SansRegular'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      prefixIcon: Icon(icon),
    );
  }

  InputDecoration _passwordDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'SansRegular'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
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