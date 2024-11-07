import 'package:api_frontend/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'welcome.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/check-token'), // Replace with your validation endpoint
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      final jsonResponse = json.decode(response.body);

      if (jsonResponse != null) {
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
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/login'),
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
          String userid = jsonResponse['data']['id'].toString();
          String name = jsonResponse['data']['name'];
          String token = jsonResponse['data']['token'];
          String role = jsonResponse['data']['role'].toString();

          await storage.write(key: 'userid', value: userid);
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
      return 'error: $e';
    }
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/login_vector.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
              const Text(
                'Hello Again!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Welcome back, you\'ve been missed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // email input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          border: InputBorder.none, hintText: 'Email'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // password input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: InputBorder.none, hintText: 'Password'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Sign in button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: () async {
                    final loginData = LoginData(
                      name: _emailController.text,
                      password: _passwordController.text,
                    );

                    final authError = await _authUser(loginData);
                    if (authError == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WelcomeScreen()),
                      );
                    } else {
                      // Tampilkan error kalau login gagal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authError)),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Register route
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not a member?'),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register Now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
