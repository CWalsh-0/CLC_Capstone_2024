import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Welcome to Flexidesk',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Sign up to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildTextField('First Name', 'Enter your first name', false),
                  SizedBox(height: 16),
                  _buildTextField('Last Name', 'Enter your last name', false),
                  SizedBox(height: 16),
                  _buildTextField('Email', 'Enter your email address', false),
                  SizedBox(height: 16),
                  _buildTextField('Password', 'Enter your password', true),
                  SizedBox(height: 16),
                  _buildTextField('Confirm Password', 'Confirm your password', true),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Handle sign-up action
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to login page
                      },
                      child: Text(
                        'Already have an account? Log In',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'OR',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Handle sign up with Microsoft action
                      },
                      icon: Image.asset(
                        'assets/images/microsoft_logo.png',
                        height: 20,
                      ),
                      label: Text(
                        'Sign up with Microsoft',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hintText, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}
