import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calmademic/login/signup/Login_Screen.dart';
import 'change_password_screen.dart';
import 'student_details_page.dart';

class CounselorStudentListPage extends StatefulWidget {
  final String counselorId;
  final String counselorName;
  final String counselorEmail;
  final String counselorCourse;

  const CounselorStudentListPage({
    super.key,
    required this.counselorId,
    required this.counselorName,
    required this.counselorEmail,
    required this.counselorCourse,
  });

  @override
  State<CounselorStudentListPage> createState() => _CounselorStudentListPageState();
}

class _CounselorStudentListPageState extends State<CounselorStudentListPage> {
  bool showArchived = false;
  bool isSelecting = false;
  final Set<String> selectedIds = {};

  Future<void> _logActivity(String action) async {
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'action': action,
      'performedBy': '${widget.counselorName} (${widget.counselorEmail})',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _logout(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(child: const Text('No'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _archiveStudent(String docId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Archive Student"),
        content: const Text("Are you sure you want to archive this student? This will prevent them from logging in."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Archive")),
        ],
      ),
    );

    if (result == true) {
      try {
        final studentDoc = await FirebaseFirestore.instance.collection('students').doc(docId).get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final studentName = studentData['name'] ?? 'Unknown';

          // Move student data to 'archived_students' collection
          await FirebaseFirestore.instance.collection('archived_students').doc(docId).set(studentData);

          // Delete student from 'students' collection
          await FirebaseFirestore.instance.collection('students').doc(docId).delete();

          await _logActivity('Archived student $studentName');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student $studentName archived successfully.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive student: $e')),
        );
      }
    }
  }

  Future<void> _unarchiveStudent(String docId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unarchive Student"),
        content: const Text("Are you sure you want to unarchive this student? This will allow them to log in again."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Unarchive")),
        ],
      ),
    );

    if (result == true) {
      try {
        final archivedStudentDoc = await FirebaseFirestore.instance.collection('archived_students').doc(docId).get();
        if (archivedStudentDoc.exists) {
          final studentData = archivedStudentDoc.data() as Map<String, dynamic>;
          final studentName = studentData['name'] ?? 'Unknown';

          // Move student data back to 'students' collection
          await FirebaseFirestore.instance.collection('students').doc(docId).set(studentData);

          // Delete student from 'archived_students' collection
          await FirebaseFirestore.instance.collection('archived_students').doc(docId).delete();

          await _logActivity('Unarchived student $studentName');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student $studentName unarchived successfully.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unarchive student: $e')),
        );
      }
    }
  }

  Future<void> _bulkUpdateArchived(bool archive) async {
    for (String id in selectedIds) {
      if (archive) {
        await _archiveStudent(id); // Call archive student for each selected student
      } else {
        await _unarchiveStudent(id); // Call unarchive student for each selected student
      }
    }
    setState(() {
      selectedIds.clear();
      isSelecting = false;
    });
  }

  Stream<QuerySnapshot> getStudentStream() {
    // Stream for active students
    if (!showArchived) {
      return FirebaseFirestore.instance
          .collection('students')
          .where('course', isEqualTo: widget.counselorCourse)
          .snapshots();
    } else {
      // Stream for archived students
      return FirebaseFirestore.instance
          .collection('archived_students')
          .where('course', isEqualTo: widget.counselorCourse)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSelecting
            ? Text('${selectedIds.length} selected')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Counselor: ${widget.counselorName}"),
                  Text("${widget.counselorEmail} | ${widget.counselorCourse}", style: const TextStyle(fontSize: 12)),
                ],
              ),
        backgroundColor: const Color(0xFF69D2E7),
        actions: [
          if (isSelecting)
            IconButton(
              icon: Icon(showArchived ? Icons.unarchive : Icons.archive),
              tooltip: showArchived ? 'Unarchive Selected' : 'Archive Selected',
              onPressed: () => _bulkUpdateArchived(!showArchived),
            ),
          if (isSelecting)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => setState(() {
                isSelecting = false;
                selectedIds.clear();
              }),
            ),
          if (!isSelecting)
            IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF69D2E7)),
              child: Text(widget.counselorName, style: const TextStyle(fontSize: 20, color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Active Students"),
              onTap: () {
                setState(() {
                  showArchived = false;
                  isSelecting = false;
                  selectedIds.clear();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text("Archived Students"),
              onTap: () {
                setState(() {
                  showArchived = true;
                  isSelecting = false;
                  selectedIds.clear();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(email: widget.counselorEmail),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getStudentStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error loading student data: ${snapshot.error}'));

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(child: Text(showArchived ? 'No archived students.' : 'No active students.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.grey[200],
                child: Text(
                  showArchived ? '📂 Archived Students' : '👨‍🎓 Active Students',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final doc = students[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final studentId = doc.id;
                    final studentName = data['name'] ?? 'No name';
                    final studentEmail = data['email'] ?? 'N/A';
                    final studentCourse = data['course'] ?? 'N/A';
                    final studentAge = data['age']?.toString() ?? 'N/A';
                    final studentDob = data['dob'] ?? 'N/A';
                    final selected = selectedIds.contains(studentId);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: isSelecting
                            ? Checkbox(
                                value: selected,
                                onChanged: (_) {
                                  setState(() {
                                    selected ? selectedIds.remove(studentId) : selectedIds.add(studentId);
                                  });
                                },
                              )
                            : null,
                        title: Text(studentName),
                        subtitle: Text(studentEmail),
                        trailing: isSelecting
                            ? null
                            : PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'archive') {
                                    _archiveStudent(studentId);
                                  } else if (value == 'unarchive') {
                                    _unarchiveStudent(studentId);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (!showArchived) const PopupMenuItem(value: 'archive', child: Text('Archive')),
                                  if (showArchived) const PopupMenuItem(value: 'unarchive', child: Text('Unarchive')),
                                ],
                              ),
                        onTap: isSelecting
                            ? () {
                                setState(() {
                                  selected ? selectedIds.remove(studentId) : selectedIds.add(studentId);
                                });
                              }
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailsPage(
                                      name: studentName,
                                      email: studentEmail,
                                      course: studentCourse,
                                      age: studentAge,
                                      dob: studentDob,
                                    ),
                                  ),
                                );
                              },
                        onLongPress: () {
                          if (!isSelecting) {
                            setState(() {
                              isSelecting = true;
                              selectedIds.add(studentId);
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}