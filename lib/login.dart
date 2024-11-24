import 'package:api_frontend/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'welcome.dart';
import 'package:audioplayers/audioplayers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final storage = const FlutterSecureStorage();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('sounds/welcome.mp3'));
  }

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await storage.read(key: 'auth_token');  //ngambil token user di penyimpanan android
    if (token != null) { // kalau udah ada tokennya
      final response = await http.get(
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/check-token'), // cek tokennya valid apa engga ke api laravel
        headers: {
          'Authorization': 'Bearer $token', //kita ngirim tokennya buat dicek disini
        },
      );
      final jsonResponse = json.decode(response.body); // kita ambil respon dari api

      if (jsonResponse != null) { // null -> tokennya udah expired
         String userid = jsonResponse['data']['id'].toString();
          String name = jsonResponse['data']['name'];
          String profilePic = jsonResponse['data']['profile_pic'];
          String email = jsonResponse['data']['email'];
          String token = jsonResponse['data']['token'];
          String role = jsonResponse['data']['role'].toString();

          await storage.write(key: 'userid', value: userid);
          await storage.write(key: 'name', value: name);
          await storage.write(key: 'profile_pic', value: profilePic);
          await storage.write(key: 'email', value: email);
          await storage.write(key: 'auth_token', value: token);
          await storage.write(key: 'role', value: role);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      } else {
        await storage.delete(key: 'auth_token');
      }
    }
  }

  Future<String?> _authUser(LoginData data) async {
    try {
      final response = await http.post(
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': data.name,
          'password': data.password,
        }),
      );

      if (response.statusCode == 200) {
        _playSound();
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          String userid = jsonResponse['data']['id'].toString();
          String name = jsonResponse['data']['name'];
          String profilePic = jsonResponse['data']['profile_pic'];
          String email = jsonResponse['data']['email'];
          String token = jsonResponse['data']['token'];
          String role = jsonResponse['data']['role'].toString();

          await storage.write(key: 'userid', value: userid);
          await storage.write(key: 'name', value: name);
          await storage.write(key: 'profile_pic', value: profilePic);
          await storage.write(key: 'email', value: email);
          await storage.write(key: 'auth_token', value: token);
          await storage.write(key: 'role', value: role);

          return null;
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
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                AnimatedOpacity(
                  opacity: isKeyboardOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: isKeyboardOpen
                      ? Container()
                      : Image.asset(
                          'assets/images/login_vector.png',
                          height: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Colors.deepPurpleAccent),
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final loginData = LoginData(
                      name: _emailController.text,
                      password: _passwordController.text,
                    );

                    final authError = await _authUser(loginData);
                    if (authError == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomeScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authError)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}