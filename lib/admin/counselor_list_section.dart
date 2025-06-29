import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Extension to capitalize the first letter of a string.
extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}

class CounselorListSection extends StatefulWidget {
  // Callback function to log activities.
  final Future<void> Function(String) logActivity;

  const CounselorListSection({super.key, required this.logActivity});

  @override
  State<CounselorListSection> createState() => _CounselorListSectionState();
}

class _CounselorListSectionState extends State<CounselorListSection> {
  // Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();
  // Filter for counselor status (All, Active, Inactive).
  String _statusFilter = 'All';

  // Function to display a SnackBar message.
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // Helper function to filter counselors based on search query and status filter.
  bool _matchesSearchAndFilter(Map<String, dynamic> data) {
    final search = _searchController.text.toLowerCase();
    final name = (data['name'] ?? '').toLowerCase();
    final email = (data['email'] ?? '').toLowerCase();
    final status = (data['status'] ?? 'active'); // Default to 'active' if status is null.

    // Check if the status matches the filter and if name or email contains the search query.
    return (_statusFilter == 'All' || _statusFilter.toLowerCase() == status) &&
        (name.contains(search) || email.contains(search));
  }

  // Function to toggle the status of a counselor between 'active' and 'inactive'.
  Future<void> _toggleStatus(String docId, String status, String name, String collection) async {
    try {
      final newStatus = status == 'active' ? 'inactive' : 'active';
      await FirebaseFirestore.instance.collection(collection).doc(docId).update({'status': newStatus});
      await widget.logActivity('${newStatus == 'active' ? 'Enabled' : 'Disabled'} counselor "$name"');
      _showSnack('Counselor status updated to ${newStatus.capitalize()}', Colors.green);
    } catch (e) {
      _showSnack('Failed to toggle status: $e', Colors.red);
      await widget.logActivity('Failed to toggle status for counselor "$name": $e');
    }
  }

  // Function to archive a counselor. Moves the counselor from 'counselors' to 'archived_counselors' collection.
  Future<void> _archiveCounselor(String docId, String name) async {
    try {
      // Get the counselor document from the 'counselors' collection.
      final docRef = FirebaseFirestore.instance.collection('counselors').doc(docId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        // Set the status to 'archived' or 'inactive' before moving
        data['status'] = 'archived'; // Or 'inactive' if you prefer that terminology for archived counselors

        // Add the counselor data to the 'archived_counselors' collection.
        await FirebaseFirestore.instance.collection('archived_counselors').doc(docId).set(data);

        // Delete the counselor document from the 'counselors' collection.
        await docRef.delete();

        _showSnack('Counselor "$name" archived successfully', Colors.orange);
        await widget.logActivity('Archived counselor "$name"');
      } else {
        _showSnack('Counselor not found', Colors.red);
        await widget.logActivity('Failed to archive counselor "$name": not found');
      }
    } catch (e) {
      _showSnack('Failed to archive counselor: $e', Colors.red);
      await widget.logActivity('Failed to archive counselor "$name": $e');
    }
  }

  // Function to restore an archived counselor. Moves the counselor from 'archived_counselors' back to 'counselors'.
  Future<void> _restoreCounselor(String docId, String name) async {
    try {
      // Get the counselor document from the 'archived_counselors' collection.
      final docRef = FirebaseFirestore.instance.collection('archived_counselors').doc(docId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        // When restoring, you might want to set their status back to 'active'
        data['status'] = 'active';

        // Add the counselor data back to the 'counselors' collection.
        await FirebaseFirestore.instance.collection('counselors').doc(docId).set(data);

        // Delete the counselor document from the 'archived_counselors' collection.
        await docRef.delete();

        _showSnack('Counselor "$name" restored successfully', Colors.green);
        await widget.logActivity('Restored counselor "$name" from archive');
      } else {
        _showSnack('Archived counselor not found', Colors.red);
        await widget.logActivity('Failed to restore counselor "$name": not found in archive');
      }
    } catch (e) {
      _showSnack('Failed to restore counselor: $e', Colors.red);
      await widget.logActivity('Failed to restore counselor "$name": $e');
    }
  }

  // Function to edit an existing counselor's details.
  Future<void> _editCounselor(String docId, Map<String, dynamic> existingData, String collection) async {
    TextEditingController nameController = TextEditingController(text: existingData['name']);
    TextEditingController emailController = TextEditingController(text: existingData['email']);
    TextEditingController courseController = TextEditingController(text: existingData['course']);
    String? status = existingData['status'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Counselor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['active', 'inactive', 'archived'] // Include 'archived' in dropdown if relevant
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                    .toList(),
                onChanged: (v) {
                  status = v;
                },
              ),
            ],
          ),
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
              try {
                await FirebaseFirestore.instance.collection(collection).doc(docId).update({
                  'name': nameController.text,
                  'email': emailController.text,
                  'course': courseController.text,
                  'status': status,
                });
                _showSnack('Counselor updated', Colors.green);
                await widget.logActivity('Edited counselor "${nameController.text}"');
                Navigator.of(context).pop();
              } catch (e) {
                _showSnack('Failed to update counselor: $e', Colors.red);
                await widget.logActivity('Failed to edit counselor "${nameController.text}": $e');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Counselor List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      // Search text field.
      TextField(
        controller: _searchController,
        decoration: const InputDecoration(labelText: 'Search'),
        onChanged: (_) => setState(() {}), // Rebuild widget on text change to apply search filter.
      ),
      // Dropdown for status filtering.
      DropdownButton<String>(
        value: _statusFilter,
        items: ['All', 'Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _statusFilter = v!), // Update filter and rebuild.
      ),
      const SizedBox(height: 10),
      // StreamBuilder to listen for real-time updates from 'counselors' collection.
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('counselors').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator.
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}')); // Show error message.
          }

          // Filter documents based on search and status.
          final docs = snap.data!.docs.where((doc) => _matchesSearchAndFilter(doc.data() as Map<String, dynamic>)).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No active/inactive counselors found.')); // Message if no counselors match criteria.
          }

          return ListView.builder(
            shrinkWrap: true, // Prevents ListView from taking infinite height.
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'N/A'), // Display counselor name.
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email with a GestureDetector to open email app.
                    GestureDetector(
                      onTap: () async {
                        final email = data['email'] ?? '';
                        if (email.isNotEmpty) {
                          final Uri uri = Uri(scheme: 'mailto', path: email);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            _showSnack('Could not open email app for ${email}', Colors.red);
                          }
                        } else {
                          _showSnack('No email address available', Colors.grey);
                        }
                      },
                      child: Text(
                        data['email'] ?? 'No Email',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text('Course: ${data['course'] ?? 'N/A'}'), // Display counselor course.
                    Text(
                      'Status: ${data['status'].toString().capitalize()}', // Display counselor status.
                      style: TextStyle(
                        color: data['status'] == 'active' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                // Popup menu for actions (Edit, Toggle Status, Archive).
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editCounselor(doc.id, data, 'counselors'); // Pass collection name
                    if (v == 'toggle') _toggleStatus(doc.id, data['status'], data['name'], 'counselors'); // Pass collection name
                    if (v == 'archive') _archiveCounselor(doc.id, data['name']); // Call archive function.
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(data['status'] == 'active' ? 'Disable' : 'Enable'),
                    ),
                    const PopupMenuItem(value: 'archive', child: Text('Archive')), // Changed from 'Delete' to 'Archive'.
                  ],
                ),
              );
            },
          );
        },
      ),
      const SizedBox(height: 20),
      const Text('Archived Counselors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      // StreamBuilder to listen for real-time updates from 'archived_counselors' collection.
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('archived_counselors').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator.
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}')); // Show error message.
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No archived counselors found.')); // Message if no archived counselors.
          }

          return ListView.builder(
            shrinkWrap: true, // Prevents ListView from taking infinite height.
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text('${data['name'] ?? 'N/A'} (Archived)'), // Display counselor name with (Archived) label.
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final email = data['email'] ?? '';
                        if (email.isNotEmpty) {
                          final Uri uri = Uri(scheme: 'mailto', path: email);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            _showSnack('Could not open email app for ${email}', Colors.red);
                          }
                        } else {
                          _showSnack('No email address available', Colors.grey);
                        }
                      },
                      child: Text(
                        data['email'] ?? 'No Email',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text('Course: ${data['course'] ?? 'N/A'}'), // Display counselor course.
                  ],
                ),
                // Popup menu for actions (Restore).
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'restore') _restoreCounselor(doc.id, data['name']); // Call restore function.
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'restore', child: Text('Restore')), // Restore option.
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