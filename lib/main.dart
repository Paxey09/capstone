import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'login/signup/Login_Screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'counselor/CounselorStudentListPage.dart';
import 'student/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final isAdmin = prefs.getBool('isAdmin') ?? false;
  final isCounselor = prefs.getBool('isCounselor') ?? false;
  final isStudent = prefs.getBool('isStudent') ?? false;

  Widget startScreen;

  if (isAdmin) {
    startScreen = const AdminDashboardScreen();
  } else if (isCounselor) {
    startScreen = CounselorStudentListPage(
      counselorId: prefs.getString('counselorId') ?? '',
      counselorName: prefs.getString('counselorName') ?? '',
      counselorEmail: prefs.getString('counselorEmail') ?? '',
      counselorCourse: prefs.getString('counselorCourse') ?? '',
    );
  } else if (isStudent) {
    startScreen = HomeScreen(

      studentName: prefs.getString('studentName') ?? '',
      studentEmail: prefs.getString('studentEmail') ?? '',
      studentCourse: prefs.getString('studentCourse') ?? '',
    );
  } else {
    startScreen = const LoginScreen();
  }

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calmademic',
      debugShowCheckedModeBanner: false,
      home: startScreen,
    );
  }
}
