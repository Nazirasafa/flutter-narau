import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> registerUser(BuildContext context) async {
    final response = await http.post(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/register'),
      body: {
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'c_password': confirmPasswordController.text,
      },
    );

    if (response.statusCode == 200) {
      // Registration successful, navigate to login or other screen
      Navigator.pop(context);
    } else {
      // Handle errors
      final jsonResponse = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(jsonResponse['error'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            ElevatedButton(
              onPressed: () => registerUser(context),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
