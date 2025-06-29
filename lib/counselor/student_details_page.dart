import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailsPage extends StatelessWidget {
  final String name;
  final String email;
  final String course;
  final String age;
  final String dob;

  const StudentDetailsPage({
    super.key,
    required this.name,
    required this.email,
    required this.course,
    required this.age,
    required this.dob,
  });

  Widget detailField({required String label, required String value, required BuildContext context}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: label == "Email"
              ? GestureDetector(
                  onTap: () async {
                    final Uri emailUri = Uri(scheme: 'mailto', path: value);
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot launch email app.')),
                      );
                    }
                  },
                  child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.blue)),
                )
              : Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF69D2E7),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            detailField(label: "Name", value: name, context: context),
            detailField(label: "Email", value: email, context: context),
            detailField(label: "Course", value: course, context: context),
            detailField(label: "Age", value: age, context: context),
            detailField(label: "Date of Birth", value: dob, context: context),
          ],
        ),
      ),
    );
  }
}
