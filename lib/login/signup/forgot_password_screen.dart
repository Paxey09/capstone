import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController =
      TextEditingController(); // Added controller for password confirmation
  String? generatedOtp;
  bool otpSent = false;
  bool _obscureNewPassword = true; // For toggling new password visibility
  bool _obscureConfirmPassword =
      true; // For toggling confirm password visibility

  // Password validation error message
  String? _passwordErrorText;

  void sendOtp() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    // Restrict email domain
    // Restrict Gmail but allow calmademic25@gmail.com
    if (email.endsWith('@gmail.com') && email != 'calmademic25@gmail.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only CCT emails are allowed.")),
      );
      return;
    }

// Allow only @citycollegeoftagaytay.edu.ph or calmademic25@gmail.com
    if (!email.endsWith('@citycollegeoftagaytay.edu.ph') &&
        email != 'calmademic25@gmail.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only CCT emails or are allowed.")),
      );
      return;
    }

    // Generate 6-digit OTP
    generatedOtp = (100000 + Random().nextInt(900000)).toString();

    // Expiry time: 15 minutes from now
    final expiry = DateTime.now().add(const Duration(minutes: 15));
    final formattedTime =
        "${expiry.hour}:${expiry.minute.toString().padLeft(2, '0')}";

    // Save OTP to Firestore
    await FirebaseFirestore.instance.collection('otps').doc(email).set({
      'otp': generatedOtp,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // EmailJS setup
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
          'to_email': email,
          'passcode': generatedOtp,
          'time': formattedTime,
        },
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to $email")),
      );
      setState(() => otpSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP: ${response.body}")),
      );
    }
  }

  // Function to validate the new password
  bool _validatePassword(String password) {
    if (password.length < 6) {
      _passwordErrorText = "Password must be at least 6 characters long.";
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _passwordErrorText = "Password must contain at least one number.";
      return false;
    }
    _passwordErrorText = null;
    return true;
  }

  void verifyAndResetPassword() async {
    final email = emailController.text.trim();
    final enteredOtp = otpController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmNewPassword = confirmNewPasswordController.text.trim();

    // Password validation
    if (!_validatePassword(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_passwordErrorText!)),
      );
      return;
    }

    // Password confirmation
    if (newPassword != confirmNewPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("New password and confirm password do not match.")),
      );
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('otps').doc(email).get();

    if (!doc.exists || doc['otp'] != enteredOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
      return;
    }

    final hashed = sha256.convert(utf8.encode(newPassword)).toString();

    // Admin account reset
    if (email == 'calmademic25@gmail.com') {
      // Consider updating this to a @citycollegeoftagaytay.edu.ph admin email if applicable
      await FirebaseFirestore.instance
          .collection('admins')
          .doc('main_admin')
          .update({'password': hashed});
    } else {
      // Student password reset
      await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: email)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'password': hashed});
        }
      });

      // Counselor password reset
      await FirebaseFirestore.instance
          .collection('counselors')
          .where('email', isEqualTo: email)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'password': hashed});
        }
      });
    }

    // Delete OTP after use
    await FirebaseFirestore.instance.collection('otps').doc(email).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset successful")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Enter your email"),
            ),
            if (otpSent) ...[
              const SizedBox(height: 10),
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: "Enter OTP"),
              ),
              const SizedBox(height: 10),
              // New Password Field
              TextField(
                controller: newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "Enter new password",
                  hintText:
                      "Min. 6 chars, at least 1 number", // Hint for password requirements
                  errorText: _passwordErrorText, // Display validation warning
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  // Validate as the user types
                  setState(() {
                    _validatePassword(value);
                  });
                },
              ),
              const SizedBox(height: 10),
              // Confirm New Password Field
              TextField(
                controller: confirmNewPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirm new password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: otpSent ? verifyAndResetPassword : sendOtp,
              child: Text(otpSent ? "Reset Password" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
