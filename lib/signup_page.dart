import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterdb/firestore/firestore_stream.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10), // Reduced from 20
                // Logo and FlexiDesk text in a row
                Row(
                  children: [
                    Image.asset(
                      'assets/flexidesk_logo.png',
                      height: 60, // Reduced from 80
                      width: 60, // Reduced from 80
                    ),
                    const SizedBox(width: 15), // Reduced from 20
                    Padding(
                      padding: const EdgeInsets.only(top: 95), // Reduced from 125
                      child: Center(
                        child: Text(
                          'FlexiDesk',
                          style: GoogleFonts.allura(
                            fontSize: 40, // Reduced from 50
                            color: const Color(0xFF1A47B8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5), // Reduced from 25
                
                // Sign Up Text
                Text(
                  'SIGN UP',
                  style: GoogleFonts.baloo2(
                    fontSize: 24, // Reduced from 30
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 5
                Text(
                  'Please enter your details below',
                  style: GoogleFonts.baloo2(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5), // Reduced from 22

                // Form Fields with reduced spacing
                _buildInputField('First Name', 'Enter your first name', false, firstNameController),
                const SizedBox(height: 5), // Reduced from 24
                _buildInputField('Last Name', 'Enter your last name', false, lastNameController),
                const SizedBox(height: 5),
                _buildInputField('Email', 'Enter your email', false, emailController),
                const SizedBox(height: 5),
                _buildInputField('Password', 'Enter your password', true, passwordController),
                const SizedBox(height: 5),
                _buildInputField('Confirm Password', 'Confirm your password', true, confirmPasswordController),
                const SizedBox(height: 20),

                // Register Button
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                        await firestoreService.saveUserToFirestore(
                          firstNameController.text,
                          lastNameController.text,
                        );
                        if (context.mounted) {
                          context.go('/');
                        }
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Authentication failed')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A47B8),
                    padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 10), // Reduced from 24
                
                // Or Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 5), // Reduced from 24

                // Microsoft Sign Up Button
                OutlinedButton(
                  onPressed: () {
                    // Implement Microsoft sign up
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/microsoft_logo.png',
                        height: 20, // Reduced from 24
                        width: 20, // Reduced from 24
                      ),
                      const SizedBox(width: 8),
                      const Text('Sign up with Microsoft'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.push('/sign-in'),
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          color: Color(0xFF1A47B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, bool isPassword, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced padding
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            if (isPassword && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (label == 'Email' && !value.contains('@')) {
              return 'Please enter a valid email';
            }
            if (label == 'Confirm Password' && value != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}

