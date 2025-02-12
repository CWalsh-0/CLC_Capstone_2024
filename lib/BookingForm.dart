import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _resourceIdController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
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
    final jsonBody = {
      'user_id': _userIdController.text,
      'resource_id': _resourceIdController.text,
      //'status': _statusController.text,
      'timeout': _timeoutController.text,
      'karma_points': int.parse(_karmaPointsController.text)
    };
    sendRestCall(jsonBody);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Book a Resource')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(labelText: 'User ID'),
              ),
              TextField(
                controller: _timeoutController,
                decoration: InputDecoration(labelText: 'Time Out Length'),
              ),
              TextField(
                controller: _karmaPointsController,
                decoration: InputDecoration(labelText: 'Karma Points'),
              ),
              TextField(
                controller: _resourceIdController,
                decoration: InputDecoration(labelText: 'Resource ID'),
              ),
              TextField(
                controller: _statusController,
                decoration: InputDecoration(labelText: 'DO NOT USE: Status'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onSubmit,
                child: Text('Submit'),
              ),
            ],
          ),
        ));
  }
}
