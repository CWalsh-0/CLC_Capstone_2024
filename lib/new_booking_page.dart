import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewBookingPage extends StatefulWidget {
  final DateTime focusedDay;

  const NewBookingPage({super.key, required this.focusedDay});

  @override
  State<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends State<NewBookingPage> {
  String? selectedBookingType;
  final Map<int, Map<String, String?>> roomTimes = {};
  List<Map<String, dynamic>> bookings = [];
  String? selectedDesk;
  String? selectedRoom;
  String? selectedTimeSlot;
  Map<String, String?> roomTimeSlots = {};
  Map<String, String?> roomStartDates = {};
  Map<String, String?> roomEndDates = {};
  String? selectedEnd;
  final List<String> timeSlots = ['Morning', 'Afternoon', 'All Day'];
  final List<String> availableTimes = [
    '9:00',
    '9:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00'
  ];

  Future<List<DocumentSnapshot>> fetchRooms() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('spaces')
        .doc("conference_rooms")
        .collection("conference_rooms_bookings")
        .get();
    return snapshot.docs;
  }

  Future<List<DocumentSnapshot>> fetchDesks() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('spaces')
        .doc("hotdesks")
        .collection("hotdesk_bookings")
        .get();
    return snapshot.docs;
  }

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

  // Map to store selected times for each room

  //Map<int, Map<String, String?>> roomTimes = {};
  //String selectedBookingType = 'desk';
  //List<Map<String, dynamic>> bookings = [];
  //Map<int, Map<String, String?>> roomTimes = {};
  //String selectedBookingType = 'desk';

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 5; i++) {
      for (String slot in timeSlots) {
        bookings.add({
          'desk': i + 1,
          'timeSlot': slot,
          'is_booked': "false",
        });
      }
      roomTimes[i] = {'start': null, 'end': null};
    }
  }

  void submitBooking() async {
    print(selectedBookingType);
    List<Map<String, dynamic>> deskBookings = [];
    List<Map<String, dynamic>> roomBookings = [];

    if (selectedBookingType == 'desk') {
      for (var desk in await fetchDesks()) {
        if (desk['is_booked'] == 'true') {}
      }
    } else {
      for (var room in await fetchRooms()) {
        if (room['is_booked'] == 'true') {}
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Booking Submitted Successfully!'),
    ));
  }

  Widget buildDeskRow(DocumentSnapshot desk) {
    bool isSelected = selectedDesk == desk['room_id'];
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
          title: Text(
            'Hotdesk ${desk['room_id']}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: [
              DropdownButton<String>(
                hint: Text('Timeslot'),
                value: selectedTimeSlot,
                items: timeSlots.map((String time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedTimeSlot = newValue;
                  });
                },
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedDesk = desk['room_id'];
                      print("test");
                      print(selectedDesk);
                      print(widget.focusedDay);
                    } else {
                      selectedDesk = null;
                    }
                  });
                },
              ),
            ],
          )),
    );
  }

  Widget buildRoomRow(DocumentSnapshot room) {
    bool isSelected = selectedRoom == room['room_id'];
    String? selectedStartDate = roomStartDates[room['room_id']];
    String? selectedEndDate = roomEndDates[room['room_id']];
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          'Conference ${room['room_id']}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            DropdownButton<String>(
              //value: room['start'],
              hint: Text('Start'),
              value: selectedStartDate,
              items: availableTimes.map((String time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  roomStartDates[room['room_id']] = newValue;
                });
              },
            ),
            SizedBox(width: 20),
            DropdownButton<String>(
              //value: room['end'],
              hint: Text('End'),
              value: selectedEndDate,
              items: availableTimes.map((String time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  roomEndDates[room['room_id']] = newValue;
                });
              },
            ),
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedRoom = room['room_id'];
                    print("test");
                    print(selectedRoom);
                    print(widget.focusedDay);
                  } else {
                    selectedRoom = null;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HotDesk & Conference Room Booking'),
        actions: [
          TextButton(
            onPressed: () => setState(() => selectedBookingType = 'desk'),
            child: Text('Book HotDesk'),
          ),
          TextButton(
            onPressed: () => setState(() => selectedBookingType = 'room'),
            child: Text('Book Conference Room'),
          ),
        ],
      ),
      body: FutureBuilder(
        future: selectedBookingType == 'desk' ? fetchDesks() : fetchRooms(),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No ${selectedBookingType}s available.'));
          }

          return ListView(
            children: snapshot.data!
                .map((doc) => selectedBookingType == 'desk'
                    ? buildDeskRow(doc)
                    : buildRoomRow(doc))
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: submitBooking,
        child: Icon(Icons.check),
      ),
    );
  }
}
