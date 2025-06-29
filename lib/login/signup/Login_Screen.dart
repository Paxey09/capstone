import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Signup_Screen.dart';
import 'forgot_password_screen.dart';
import '../../student/home.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../counselor/CounselorStudentListPage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> signIn(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password required")),
      );
      return;
    }

    // 🔒 Fetch admin email dynamically
    final adminDoc = await FirebaseFirestore.instance.collection('admins').doc('main_admin').get();
    if (adminDoc.exists) {
      final adminEmail = adminDoc['email'];
      final storedPassword = adminDoc['password'];

      if (email == adminEmail && storedPassword == hashPassword(password)) {
        await prefs.setBool('isAdmin', true);
        await prefs.setBool('isCounselor', false);
        await prefs.setBool('isStudent', false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }
    }

    // 👨‍🏫 Counselor login
    final counselorSnapshot = await FirebaseFirestore.instance
        .collection('counselors')
        .where('email', isEqualTo: email)
        .get();

    if (counselorSnapshot.docs.isNotEmpty) {
      final doc = counselorSnapshot.docs.first;
      final data = doc.data();
      final hashedInput = hashPassword(password);

      if (data['password'] == hashedInput) {
        if (data['status'] != 'active') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Counselor account is inactive.'),
            backgroundColor: Colors.redAccent,
          ));
          return;
        }

        await prefs.setBool('isAdmin', false);
        await prefs.setBool('isCounselor', true);
        await prefs.setBool('isStudent', false);
        await prefs.setString('counselorId', doc.id);
        await prefs.setString('counselorName', data['name']);
        await prefs.setString('counselorEmail', data['email']);
        await prefs.setString('counselorCourse', data['course']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CounselorStudentListPage(
              counselorId: doc.id,
              counselorName: data['name'],
              counselorEmail: data['email'],
              counselorCourse: data['course'],
            ),
          ),
        );
        return;
      }
    }

    // 👩‍🎓 Student login
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: email)
        .get();

    if (studentSnapshot.docs.isNotEmpty) {
      final doc = studentSnapshot.docs.first;
      final data = doc.data();
      final hashedInput = hashPassword(password);

      if (data['password'] == hashedInput) {
        await prefs.setBool('isAdmin', false);
        await prefs.setBool('isCounselor', false);
        await prefs.setBool('isStudent', true);
        await prefs.setString('studentId', doc.id);
        await prefs.setString('studentName', data['name']);
        await prefs.setString('studentEmail', data['email']);
        await prefs.setString('studentCourse', data['course']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              studentName: data['name'],
              studentEmail: data['email'],
              studentCourse: data['course'],
            ),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Invalid credentials"),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Login",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00BFCB))),
              const SizedBox(height: 40),

              const Text("EMAIL", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "@citycollegeoftagaytay.edu.ph",
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text("PASSWORD", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.grey)),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => signIn(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6EE7E7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text("Login",
                      style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                },
                child: const Text("No account? Sign up here", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
