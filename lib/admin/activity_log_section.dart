import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityLogSection extends StatefulWidget {
  const ActivityLogSection({super.key});

  @override
  State<ActivityLogSection> createState() => _ActivityLogSectionState();
}

class _ActivityLogSectionState extends State<ActivityLogSection> {
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _clearLogs() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Activity Logs'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to clear all activity logs?'),
                Text('This action cannot be undone.'),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final QuerySnapshot allLogs =
                      await FirebaseFirestore.instance.collection('activity_logs').get();
                  final WriteBatch batch = FirebaseFirestore.instance.batch();

                  for (final QueryDocumentSnapshot log in allLogs.docs) {
                    batch.delete(log.reference);
                  }

                  await batch.commit();
                  _showSnack('Activity logs cleared successfully.', Colors.green);
                } catch (e) {
                  _showSnack('Error clearing logs: $e', Colors.red);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Activity Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Clear Logs',
              onPressed: _clearLogs,
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('activity_logs')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text('No activity yet.');
            return ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp).toDate();
                final formatted = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(data['action']),
                  subtitle: Text('By: ${data['performedBy']}  •  $formatted'),
                );
              },
            );
          },
        ),
      ],
    );
  }
}