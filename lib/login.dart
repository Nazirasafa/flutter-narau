import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'welcome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final storage = const FlutterSecureStorage();

  Duration get loginTime => const Duration(milliseconds: 2250);

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      // Validate the token by making a test API call
      final response = await http.get(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/check-token'), // Replace with your validation endpoint
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      } else {
        await storage.delete(key: 'auth_token'); // Clear expired token
      }
    }
  }

Future<String?> _authUser(LoginData data) async {
  try {
    final response = await http.post(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/login'), // Change to correct IP for device/emulator
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': data.name,
        'password': data.password,
      }),
    );

   
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Check for success and extract token from nested data object
      if (jsonResponse['success'] == true) {
        String name = jsonResponse['data']['name'];
        String token = jsonResponse['data']['token'];
        String role = jsonResponse['data']['role'].toString();


        await storage.write(key: 'name', value: name);
        await storage.write(key: 'auth_token', value: token);
        await storage.write(key: 'role', value: role);

        return null; // Login successful
      } else {
        return jsonResponse['message'] ?? 'Login failed';
      }
    } else {
      return 'Invalid username or password';
    }
  } catch (e) {
    return 'An error occurred. Please try again.';
  }
}






  Future<String?> _recoverPassword(String name) async {
    // Implement recovery logic if available
    return 'User not found'; // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'SMKN 4 Bogor',
      logo: const AssetImage('assets/logo.png'),
      onLogin: _authUser,
      onRecoverPassword: _recoverPassword,
      theme: LoginTheme(
        primaryColor: Colors.grey[100],
        accentColor: Colors.purpleAccent,
        titleStyle: const TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 10,
          margin: const EdgeInsets.all(50),
          shadowColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        buttonTheme: const LoginButtonTheme(
          splashColor: Colors.purpleAccent,
          backgroundColor: Colors.blueAccent,
          highlightColor: Colors.purple,
          elevation: 8.0,
        ),
      ),
      onSubmitAnimationCompleted: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      },
    );
  }
}
