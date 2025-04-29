// lib/screens/register_page.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'student_home.dart';
import 'organizer_home.dart';
import 'admin_home.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'student';

  void _register() async {
    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
      );

      String role = await _authService.getUserRole();

      if (role == 'student') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentHome()));
      } else if (role == 'organizer') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrganizerHome()));
      } else if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminHome()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'organizer', child: Text('Organizer')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Select Role'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}
