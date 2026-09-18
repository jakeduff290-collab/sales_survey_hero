import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _companyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_companyController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final companyCodeUpper = _companyController.text.trim().toUpperCase();
      
      // 1. THE BOUNCER: Check if the company actually exists in your database
      final doc = await FirebaseFirestore.instance.collection('companies').doc(companyCodeUpper).get();
      
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Company Code. Check with your manager.'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
        return; // Kick them out before they can make an account!
      }

      // 2. If the company is legit, create the account
      final username = _usernameController.text.trim().toLowerCase();
      final formattedEmail = '$username@${companyCodeUpper.toLowerCase()}.surveyhero.com';

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: formattedEmail,
        password: _passwordController.text.trim(),
      );
      
      // 3. Save their info and let them in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_code', companyCodeUpper);
      await prefs.setString('username', _usernameController.text.trim());

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Registration failed.';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'That username is already taken for this company.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password should be at least 6 characters.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error validating company.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE2F952)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'NEW REP\nREGISTRATION', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE2F952), height: 1.2)
            ),
            const SizedBox(height: 48),
            
            _buildTextField('Company Code (Ask your manager)', _companyController, false),
            const SizedBox(height: 24),
            
            _buildTextField('Choose Username (e.g., first name)', _usernameController, false),
            const SizedBox(height: 24),
            
            _buildTextField('Create Password (6+ characters)', _passwordController, true),
            const SizedBox(height: 40),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2F952), 
                foregroundColor: Colors.black, 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
              ),
              onPressed: _isLoading ? null : _register,
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                  : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFE2F952), fontSize: 14),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2F952))),
      ),
    );
  }
}
