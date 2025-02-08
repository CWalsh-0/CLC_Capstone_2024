import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterdb/firestore/firestore_stream.dart';
import 'package:google_fonts/google_fonts.dart';

//
class SchedulingLandingScreen extends StatelessWidget {
  final String documentId;
  final FirestoreService firestoreService =
      FirestoreService(); // Instantiate service | could just do it in build
  SchedulingLandingScreen({super.key, required this.documentId});

  final TextEditingController timeoutController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scheduling')),
      body: StreamBuilder(
        //get stream
        stream: firestoreService.getDocumentStream(documentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var data = snapshot.data!.data() as Map<String, dynamic>;
          var status = data['status'] ?? 'No Status';

          return Column(
            children: [
              SizedBox(height: 40),
              Center(
                child: _buildTextField('Timeout Length',
                    'Enter the booking duration', false, timeoutController),
              ),
              Expanded(
                child: ListView(
                  children: data.entries.map((entry) {
                    return ListTile(
                      title: Text('${entry.key}: ${entry.value}'),
                    );
                  }).toList(),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    User? user =
                        FirebaseAuth.instance.currentUser; // Get current user
                    if (user != null) {
                      // Toggle the status
                      String newStatus = 'authorized';
                      await FirebaseFirestore.instance
                          .collection('homeassistant')
                          .doc(documentId)
                          .update({
                        'status': newStatus,
                        'timeout': int.tryParse(timeoutController.text) ??
                            0, // Store timeout duration
                        'user_booked': user.uid,
                        'date_booked': FieldValue.serverTimestamp()
                      });
                    }
                    throw Exception("No user logged in");
                  },
                  child: Text(
                    'Push Timeout Time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String status = 'unauthorized';
                    await FirebaseFirestore.instance
                        .collection('homeassistant')
                        .doc(documentId)
                        .update({
                      'status': status,
                      //'timeout': timeoutController.text, // Store timeout duration
                      'date_booked': FieldValue.serverTimestamp()
                    });
                  },
                  child: Text(
                    'Set status to unauthorized',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  User? user =
                      FirebaseAuth.instance.currentUser; // Get current user
                  if (user != null) {
                    // Toggle the status
                    String newStatus =
                        status == 'authorized' ? 'unauthorized' : 'authorized';
                    await FirebaseFirestore.instance
                        .collection('homeassistant')
                        .doc(documentId)
                        .update({
                      'status': newStatus,
                      //'timeout': timeoutController.text, // Store timeout duration
                      'user_booked': user.uid,
                      'date_booked': FieldValue.serverTimestamp()
                    });
                  }
                  throw Exception("No user logged in");
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

Widget _buildTextField(String label, String hintText, bool isPassword,
    TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    ],
  );
}
