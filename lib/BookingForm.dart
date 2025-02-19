import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController _resourceIdController = TextEditingController();
  final List<String> _bookingTypes = ['Hotdesk', 'Conference Room'];
  String? _selectedBookingType;
  String bookingType = ''; // Add a variable to hold the selected booking type

  final List<String> _dateTimeTypes = ['Allday', 'Morning', 'Afternoon'];
  String? _selectedDateTime;
  String selectedDateTime = '';

  final TextEditingController _timeoutController = TextEditingController();
  final TextEditingController _karmaPointsController = TextEditingController();

  Future<void> sendRestCall(Map<String, dynamic> jsonBody) async {
    final url =
        Uri.parse('https://algorithmmain-production.up.railway.app/book');
    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(jsonBody));
      if (response.statusCode == 200) {
        print('Success: ${response.body}');
      } else {
        print('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _onSubmit() {
    // Code this later to be currently signed in user than some entered id
    User? user = FirebaseAuth.instance.currentUser;
    final jsonBody = {
      'user_id': user?.uid,
      'booking_type': bookingType,
      'time': selectedDateTime,
      'resource_id': _resourceIdController.text,
      'timeout': _timeoutController.text,
      'karma_points': int.parse(_karmaPointsController.text)
    };
    sendRestCall(jsonBody);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Add a Bookings',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
            child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Booking Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBookingType,
                items: _bookingTypes.map((String bookingType) {
                  return DropdownMenuItem<String>(
                    value: bookingType,
                    child: Text(bookingType),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    bookingType = newValue!;
                  });
                },
                hint: Text('Select a room type'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _timeoutController,
                decoration: InputDecoration(
                  labelText: 'Time Out Length',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Booking Time',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDateTime,
                items: _dateTimeTypes.map((String dateTimeType) {
                  return DropdownMenuItem<String>(
                    value: dateTimeType,
                    child: Text(dateTimeType),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDateTime = newValue!;
                  });
                },
                hint: Text('Select when to book'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _karmaPointsController,
                decoration: InputDecoration(
                  labelText: 'Karma Points',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _resourceIdController,
                decoration: InputDecoration(
                  labelText: 'Resource ID',
                  border: OutlineInputBorder(
                    // Add border around the TextField
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A47B8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )));
  }
}
