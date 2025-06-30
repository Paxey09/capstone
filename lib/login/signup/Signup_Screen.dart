import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Login_Screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final dobController = TextEditingController();

  String? selectedCourse;
  bool isLoading = false;
  Set<String> invalidFields = {};
  String? _nameErrorMessage;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_autoFillNameFromEmail);
  }

  @override
  void dispose() {
    emailController.removeListener(_autoFillNameFromEmail);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dobController.dispose();
    super.dispose();
  }

  void _autoFillNameFromEmail() {
    final email = emailController.text.trim();
    final nameRegex = RegExp(r'^([a-z]+)\.([a-z]+)@citycollegeoftagaytay\.edu\.ph$', caseSensitive: false);

    if (nameRegex.hasMatch(email)) {
      final match = nameRegex.firstMatch(email)!;
      final firstName = match.group(1) ?? '';
      final lastName = match.group(2) ?? '';

      final capitalized = '${_capitalize(firstName)} ${_capitalize(lastName)}';

      if (nameController.text != capitalized) {
        setState(() {
          nameController.text = capitalized;
        });
      }
    }
  }

  String _capitalize(String word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(days: 1));

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: yesterday,
      firstDate: DateTime(1900),
      lastDate: yesterday,
    );

    if (picked != null) {
      setState(() {
        dobController.text = "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signUp() async {
    setState(() {
      isLoading = true;
      invalidFields.clear();
      _nameErrorMessage = null;
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
    });

    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String dob = dobController.text.trim();
    final String? course = selectedCourse;

    if (name.isEmpty) {
      invalidFields.add("name");
      _nameErrorMessage = "Please input your name";
    }
    if (email.isEmpty || !email.endsWith('@citycollegeoftagaytay.edu.ph')) {
      invalidFields.add("email");
      if (!email.endsWith('@citycollegeoftagaytay.edu.ph') && email.isNotEmpty) {
        _emailErrorMessage = "Please use your official CCT email (.edu.ph)";
      } else if (email.isEmpty) {
        _emailErrorMessage = "Please input your email";
      }
    }
    if (password.isEmpty || password.length < 6 || !password.contains(RegExp(r'[0-9]'))) {
      invalidFields.add("password");
      if (password.isEmpty) {
        _passwordErrorMessage = "Please input your password";
      } else if (password.length < 6) {
        _passwordErrorMessage = "Password must be at least 6 characters long";
      } else if (!password.contains(RegExp(r'[0-9]'))) {
        _passwordErrorMessage = "Password must contain at least one number";
      }
    }
    if (dob.isEmpty) invalidFields.add("dob");
    if (course == null) invalidFields.add("course");

    if (invalidFields.isNotEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: email)
            .get(),
        FirebaseFirestore.instance
            .collection('archived_students')
            .where('email', isEqualTo: email)
            .get(),
        FirebaseFirestore.instance
            .collection('counselors')
            .where('email', isEqualTo: email)
            .get(),
        FirebaseFirestore.instance
            .collection('archived_counselors')
            .where('email', isEqualTo: email)
            .get(),
      ]);

      if (results.any((res) => res.docs.isNotEmpty)) {
        _showMessage('This email is already used in the system.');
        setState(() => isLoading = false);
        return;
      }

      final parts = dob.split('/');
      final birthDate = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      final hashedPassword = hashPassword(password);

      await FirebaseFirestore.instance.collection('students').add({
        'name': name,
        'email': email,
        'password': hashedPassword,
        'dob': dob,
        'course': course,
        'age': age,
        'createdAt': Timestamp.now(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    bool obscure = false,
    String? hint,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool error = false,
    String? errorMessage,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: error ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: error
                  ? const BorderSide(color: Colors.red, width: 1.5)
                  : const BorderSide(color: Color(0xFF69D2E7), width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Create New\nAccount",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF69D2E7),
                ),
              ),
              
              const SizedBox(height: 20),
              _label("EMAIL (.edu.ph only)"),
              _textField(
                controller: emailController,
                hint: "example@citycollegeoftagaytay.edu.ph",
                inputType: TextInputType.emailAddress,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._]'))],
                error: invalidFields.contains("email"),
                errorMessage: _emailErrorMessage,
              ),
              const SizedBox(height: 20),
              _label("User Name"),
              _textField(
                controller: nameController,
                hint: "Your name",
                readOnly: true,
                error: invalidFields.contains("name"),
                errorMessage: _nameErrorMessage,
              ),
              const SizedBox(height: 20),
              _label("PASSWORD"),
              _textField(
                controller: passwordController,
                obscure: _obscurePassword,
                hint: "Enter password",
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                error: invalidFields.contains("password"),
                errorMessage: _passwordErrorMessage,
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
              const SizedBox(height: 20),
              _label("DATE OF BIRTH"),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _textField(
                    controller: dobController,
                    hint: "MM/DD/YYYY",
                    error: invalidFields.contains("dob"),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label("COURSE"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final courses = snapshot.data!.docs
                      .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
                      .toList();
                  return DropdownButtonFormField<String>(
                    value: selectedCourse,
                    items: courses
                        .map((course) => DropdownMenuItem(
                              value: course,
                              child: Text(course),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: invalidFields.contains("course")
                            ? const BorderSide(color: Colors.red)
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: invalidFields.contains("course")
                            ? const BorderSide(color: Colors.red)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: invalidFields.contains("course")
                            ? const BorderSide(color: Colors.red)
                            : const BorderSide(color: Color(0xFF69D2E7), width: 1.5),
                      ),
                      hintText: "Select Course",
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF69D2E7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Sign up",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Already have an account? Login here",
                  style: TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
