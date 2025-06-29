import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AdminChangePasswordScreen extends StatefulWidget {
  const AdminChangePasswordScreen({super.key});

  @override
  State<AdminChangePasswordScreen> createState() => _AdminChangePasswordScreenState();
}

class _AdminChangePasswordScreenState extends State<AdminChangePasswordScreen> {
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();
  final otpController = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool otpSent = false;
  bool loading = false;
  String? adminEmail;

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> sendOtp() async {
    final adminDoc = await FirebaseFirestore.instance.collection('admins').doc('main_admin').get();
    if (!adminDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin email not found.")));
      return;
    }

    adminEmail = adminDoc['email'];
    final otp = (100000 + Random().nextInt(900000)).toString();

    await FirebaseFirestore.instance.collection('otps').doc(adminEmail).set({
      'otp': otp,
      'timestamp': DateTime.now().toIso8601String(),
    });

    const serviceId = 'service_0htdkbt';
    const templateId = 'template_5bhy77a';
    const userId = '13RGoNCNyhCwP3Nsb';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'to_email': adminEmail,
          'passcode': otp,
        },
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to $adminEmail")));
      setState(() => otpSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send OTP: ${response.body}")));
    }
  }

  Future<void> changePassword() async {
    final oldPass = oldPassController.text.trim();
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();
    final otp = otpController.text.trim();

    if (!otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please send OTP first")));
      return;
    }

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("New passwords do not match")));
      return;
    }

    setState(() => loading = true);

    final doc = await FirebaseFirestore.instance.collection('admins').doc('main_admin').get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin not found")));
      setState(() => loading = false);
      return;
    }

    final email = doc['email'];
    if (doc['password'] != hashPassword(oldPass)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Old password is incorrect")));
      setState(() => loading = false);
      return;
    }

    final otpDoc = await FirebaseFirestore.instance.collection('otps').doc(email).get();
    if (!otpDoc.exists || otpDoc['otp'] != otp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
      setState(() => loading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('admins').doc('main_admin').update({
      'password': hashPassword(newPass),
    });

    await FirebaseFirestore.instance.collection('otps').doc(email).delete();

    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password changed successfully")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Admin Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldPassController,
              obscureText: !_showOld,
              decoration: InputDecoration(
                labelText: "Old Password",
                suffixIcon: IconButton(
                  icon: Icon(_showOld ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showOld = !_showOld),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPassController,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(_showNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmPassController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (otpSent)
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: "Enter OTP"),
              ),
            if (!otpSent)
              TextButton.icon(
                onPressed: sendOtp,
                icon: const Icon(Icons.send),
                label: const Text("Send OTP to Admin Email"),
              ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_open),
              label: const Text("Change Password"),
              onPressed: loading ? null : changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
            )
          ],
        ),
      ),
    );
  }
}
