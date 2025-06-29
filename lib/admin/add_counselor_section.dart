import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class AddCounselorSection extends StatefulWidget {
  final Future<void> Function(String) logActivity;

  const AddCounselorSection({super.key, required this.logActivity});

  @override
  State<AddCounselorSection> createState() => _AddCounselorSectionState();
}

class _AddCounselorSectionState extends State<AddCounselorSection> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedCourse;

  bool _obscurePassword = true;

  bool _isEmailValid(String email) {
    final regex = RegExp(r'^[\w\.\-]+@citycollegeoftagaytay\.edu\.ph$');
    return regex.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final regex = RegExp(r'^(?=.*\d).{6,}$'); // Fixed regex: at least 6 chars, 1 digit
    return regex.hasMatch(password);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _addCounselor() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || _selectedCourse == null || !_isEmailValid(email)) {
      _showSnack('Fill all fields with valid CCT email', Colors.red);
      return;
    }

    if (!_isPasswordValid(password)) {
      _showSnack('Password must be at least 6 characters with at least 1 number.', Colors.red);
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('counselors')
        .where('email', isEqualTo: email)
        .get();
    if (existing.docs.isNotEmpty) {
      _showSnack('Email already exists', Colors.orange);
      return;
    }

    final hashed = sha256.convert(utf8.encode(password)).toString();
    await FirebaseFirestore.instance.collection('counselors').add({
      'name': name,
      'email': email,
      'password': hashed,
      'course': _selectedCourse,
      'status': 'active',
      'createdAt': Timestamp.now(),
    });

    await widget.logActivity('Added counselor "$name" ($email) to course "$_selectedCourse"');

    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() => _selectedCourse = null);
    _showSnack('Counselor added', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final isEmailValid = _isEmailValid(_emailController.text.trim());
    final isPasswordValid = _isPasswordValid(_passwordController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Counselor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: _emailController.text.isEmpty || isEmailValid ? null : 'Invalid format',
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: _passwordController.text.isEmpty || isPasswordValid
                ? null
                : 'Min 6 characters, include at least 1 number',
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('courses').snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            final items = snap.data!.docs.map((e) => e['name'] as String).toList();
            return DropdownButtonFormField(
              value: _selectedCourse,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedCourse = v),
              decoration: const InputDecoration(labelText: 'Select Course'),
            );
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _addCounselor, child: const Text('Add Counselor')),
      ],
    );
  }
}
