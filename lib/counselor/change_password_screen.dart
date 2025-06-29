import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  bool isLoading = false;
  bool showOldPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  String? generatedOtp;

  bool isPasswordValid(String password) {
    final hasMinLength = password.length >= 6;
    final hasNumber = RegExp(r'\d').hasMatch(password);
    return hasMinLength && hasNumber;
  }

  Future<void> sendOtp() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }

    if (!isPasswordValid(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters and contain at least 1 number")),
      );
      return;
    }

    // Validate old password
    final hashedOld = sha256.convert(utf8.encode(oldPassword)).toString();
    final counselorDocs = await FirebaseFirestore.instance
        .collection('counselors')
        .where('email', isEqualTo: widget.email)
        .get();

    if (counselorDocs.docs.isEmpty || counselorDocs.docs.first['password'] != hashedOld) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Old password is incorrect")),
      );
      return;
    }

    // Generate and send OTP
    generatedOtp = (100000 + Random().nextInt(900000)).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 15));
    final formattedTime = "${expiry.hour}:${expiry.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance.collection('otps').doc(widget.email).set({
      'otp': generatedOtp,
      'timestamp': DateTime.now().toIso8601String(),
    });

    const serviceId = 'service_0htdkbt';
    const templateId = 'template_5bhy77a';
    const userId = '13RGoNCNyhCwP3Nsb';

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'to_email': widget.email,
          'passcode': generatedOtp,
          'time': formattedTime,
        },
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to ${widget.email}")),
      );
      setState(() => otpSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP")),
      );
    }
  }

  Future<void> verifyAndChangePassword() async {
    final enteredOtp = otpController.text.trim();
    final newPassword = newPasswordController.text.trim();

    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }

    final otpDoc = await FirebaseFirestore.instance.collection('otps').doc(widget.email).get();

    if (!otpDoc.exists || otpDoc['otp'] != enteredOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    final hashed = sha256.convert(utf8.encode(newPassword)).toString();

    final counselorDocs = await FirebaseFirestore.instance
        .collection('counselors')
        .where('email', isEqualTo: widget.email)
        .get();

    for (var doc in counselorDocs.docs) {
      await doc.reference.update({'password': hashed});
    }

    await FirebaseFirestore.instance.collection('otps').doc(widget.email).delete();

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password updated successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Email: ${widget.email}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: oldPasswordController,
              obscureText: !showOldPassword,
              decoration: InputDecoration(
                labelText: "Old Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(showOldPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => showOldPassword = !showOldPassword),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: !showNewPassword,
              decoration: InputDecoration(
                labelText: "New Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(showNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => showNewPassword = !showNewPassword),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!otpSent)
              ElevatedButton(
                onPressed: isLoading ? null : sendOtp,
                child: const Text("Send OTP"),
              ),
            if (otpSent) ...[
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: "Enter OTP",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : verifyAndChangePassword,
                child: isLoading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Change Password"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
