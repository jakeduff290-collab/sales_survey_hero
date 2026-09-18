import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _companyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_companyController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // The secret sauce: Combine Company Code and Username into the Firebase email format
      final company = _companyController.text.trim().toLowerCase();
      final username = _usernameController.text.trim().toLowerCase();
      final formattedEmail = '$username@$company.surveyhero.com';

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: formattedEmail,
        password: _passwordController.text.trim(),
      );
      
      // Save their info so the Dashboard can display it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_code', _companyController.text.trim().toUpperCase());
      await prefs.setString('username', _usernameController.text.trim());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}'), backgroundColor: Colors.red),
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
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SURVEY HERO', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFE2F952))
            ),
            const SizedBox(height: 12),
            const Text(
              'Rep Portal Login', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white70, fontSize: 16)
            ),
            const SizedBox(height: 48),
            
            _buildTextField('Company Code (e.g., WAVE)', _companyController, false),
            const SizedBox(height: 24),
            
            _buildTextField('Username', _usernameController, false),
            const SizedBox(height: 24),
            
            _buildTextField('Password', _passwordController, true),
            const SizedBox(height: 40),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2F952), 
                foregroundColor: Colors.black, 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
              ),
              onPressed: _isLoading ? null : _login,
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                  : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
                child: const Text('New rep? Register here.', style: TextStyle(color: Color(0xFFE2F952))),
              ),
            )
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
