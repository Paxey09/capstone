import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCoursesSection extends StatefulWidget {
  final Future<void> Function(String) logActivity;

  const ManageCoursesSection({super.key, required this.logActivity});

  @override
  State<ManageCoursesSection> createState() => _ManageCoursesSectionState();
}

class _ManageCoursesSectionState extends State<ManageCoursesSection> {
  final TextEditingController _newCourseController = TextEditingController();
  final TextEditingController _editCourseController = TextEditingController();

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _addCourse() async {
    final newCourse = _newCourseController.text.trim().toUpperCase();
    if (newCourse.isEmpty) {
      _showSnack('Enter a course name', Colors.red);
      return;
    }

    final exists = await FirebaseFirestore.instance
        .collection('courses')
        .where('name', isEqualTo: newCourse)
        .get();
    if (exists.docs.isNotEmpty) {
      _showSnack('Course already exists', Colors.orange);
      return;
    }

    await FirebaseFirestore.instance.collection('courses').add({
      'name': newCourse,
      'createdAt': Timestamp.now(),
    });

    await widget.logActivity('Added course "$newCourse"');

    _newCourseController.clear();
    _showSnack('Course added', Colors.green);
  }

  Future<void> _editCourse(String docId, String currentCourseName) async {
    _editCourseController.text = currentCourseName;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: TextField(
            controller: _editCourseController,
            decoration: const InputDecoration(labelText: 'Course Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final updatedCourseName = _editCourseController.text.trim().toUpperCase();
                if (updatedCourseName.isEmpty) {
                  _showSnack('Enter a course name', Colors.red);
                  return;
                }
                if (updatedCourseName == currentCourseName) {
                  Navigator.of(context).pop();
                  return;
                }
                final exists = await FirebaseFirestore.instance
                    .collection('courses')
                    .where('name', isEqualTo: updatedCourseName)
                    .get();
                if (exists.docs.isNotEmpty) {
                  _showSnack('Course already exists', Colors.orange);
                  return;
                }
                await FirebaseFirestore.instance.collection('courses').doc(docId).update({'name': updatedCourseName});
                await widget.logActivity('Edited course "$currentCourseName" to "$updatedCourseName"');
                Navigator.of(context).pop();
                _showSnack('Course updated', Colors.green);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCourse(String docId, String courseName) async {
    final used = await FirebaseFirestore.instance
        .collection('counselors')
        .where('course', isEqualTo: courseName)
        .get();
    if (used.docs.isNotEmpty) {
      _showSnack('Cannot delete. This course is currently assigned to one or more counselors.', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this course?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('courses').doc(docId).delete();
                Navigator.of(context).pop();
                await widget.logActivity('Deleted course "$courseName"');
                _showSnack('Course deleted', Colors.red);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Manage Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      TextField(controller: _newCourseController, decoration: const InputDecoration(labelText: 'New Course')),
      ElevatedButton(onPressed: _addCourse, child: const Text('Add Course')),
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();
          final docs = snap.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name']),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCourse(doc.id, data['name']);
                    } else if (value == 'delete') {
                      _deleteCourse(doc.id, data['name']);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ]);
  }
}