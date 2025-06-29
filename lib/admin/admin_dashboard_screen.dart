
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/signup/Login_Screen.dart';
import 'manage_courses_section.dart';
import 'add_counselor_section.dart';
import 'counselor_list_section.dart';
import 'activity_log_section.dart';
import 'admin_change_password.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedPage = 2;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _logActivity(String action) async {
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'action': action,
      'performedBy': 'Admin',
      'timestamp': Timestamp.now(),
    });
  }

  void _navigateToPage(int page) {
    Navigator.pop(context); // Auto-close drawer
    setState(() => _selectedPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Manage Courses'),
              onTap: () => _navigateToPage(0),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Counselor'),
              onTap: () => _navigateToPage(1),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Counselor List'),
              onTap: () => _navigateToPage(2),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Activity Log'),
              onTap: () => _navigateToPage(3),
            ),
            ListTile(
  leading: const Icon(Icons.lock),
  title: const Text('Change Password'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminChangePasswordScreen()),
    );
  },
),

          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: _selectedPage == 0
              ? ManageCoursesSection(logActivity: _logActivity)
              : _selectedPage == 1
                  ? AddCounselorSection(logActivity: _logActivity)
                  : _selectedPage == 2
                      ? CounselorListSection(logActivity: _logActivity)
                      : const ActivityLogSection(),
        ),
      ),
    );
  }
}
