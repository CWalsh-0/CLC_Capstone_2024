import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//
class SchedulingLandingScreen extends StatelessWidget {
  final String documentId;

  const SchedulingLandingScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scheduling')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('homeassistant')
            .doc(documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var status = data['status'] ?? 'No Status';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: data.entries.map((entry) {
                    return ListTile(
                      title: Text('${entry.key}: ${entry.value}'),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Toggle the status
                  String newStatus =
                      status == 'authorized' ? 'unauthorized' : 'authorized';
                  await FirebaseFirestore.instance
                      .collection('homeassistant')
                      .doc(documentId)
                      .update({'status': newStatus});
                },
                child: Text('Toggle Status'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Current status: $status'),
              ),
            ],
          );
        },
      ),
    );
  }
}
