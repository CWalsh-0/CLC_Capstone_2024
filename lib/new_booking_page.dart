import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;

import 'package:http/http.dart' as http;
import 'dart:convert';

class NewBookingPage extends StatefulWidget {
  const NewBookingPage({super.key});

  @override
  State<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends State<NewBookingPage> {
  String? selectedBookingType;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;

  final List<String> timeSlots = ['Morning', 'Afternoon', 'All Day'];
  final List<String> availableTimes = [
    '09:00',
    '09:30',
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

  final Map<int, bool> selectedDesks = {};
  final Map<int, bool> selectedRooms = {};
  final Map<int, Map<String, String?>> roomTimes = {};
  final Map<int, String> selectedDeskTimeSlots = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _hasSelection = false;
  String _userId = "anonymous";

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      selectedDesks[i] = false;
    }
    for (int i = 0; i < 3; i++) {
      selectedRooms[i] = false;
      roomTimes[i] = {'start': null, 'end': null};
    }
    _userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
  }

  bool _isMorningSlotDisabled(DateTime selectedDay) {
    final now = DateTime.now();
    //uncomment for debug
    // final now = DateTime(
    //    staticTime.year, staticTime.month, staticTime.day, 8, 0, 0); // 9:00 AM
    if (!isSameDay(selectedDay, now)) return false;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentMinutes = currentHour * 60 + currentMinute;
    return currentMinutes >= 12 * 60; // Disable Morning after 12 PM
  }

  bool _isTimeDisabled(String time, DateTime selectedDay) {
    final now = DateTime.now();
    //uncomment for debug
    //final now = DateTime(
    //    staticTime.year, staticTime.month, staticTime.day, 8, 0, 0); // 9:00 AM
    if (!isSameDay(selectedDay, now)) return false;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentMinutes = currentHour * 60 + currentMinute;
    final timeMinutes = _timeToMinutes(time);
    return timeMinutes <= currentMinutes;
  }

  Future<bool> _isAllDayDisabled(int deskIndex, DateTime selectedDay) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    String resourceId = 'room_${deskIndex + 67890}';

    QuerySnapshot bookingQuery = await _firestore
        .collection('bookings')
        .where('resource_id', isEqualTo: resourceId)
        .where('date', isEqualTo: formattedDate)
        .get();

    for (var doc in bookingQuery.docs) {
      String timeSlot = doc['time'];
      if (timeSlot == 'Morning' || timeSlot == 'Afternoon') {
        return true; // Disable All Day if Morning or Afternoon is booked
      }
    }
    return false;
  }

  Future<void> sendRestCall(Map<String, dynamic> jsonBody) async {
    final url =
        Uri.parse('https://algorithmmain-production.up.railway.app/book');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
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

  void _validateSelections() {
    bool hasValid = false;
    if (selectedBookingType == 'desk') {
      for (int i = 0; i < 5; i++) {
        if (selectedDesks[i] == true && selectedDeskTimeSlots.containsKey(i)) {
          hasValid = true;
          break;
        }
      }
    } else if (selectedBookingType == 'room') {
      for (int i = 0; i < 3; i++) {
        if ((selectedRooms[i] ?? false) &&
            roomTimes[i]!['start'] != null &&
            roomTimes[i]!['end'] != null) {
          hasValid = true;
          break;
        }
      }
    }
    setState(() {
      _hasSelection = hasValid;
    });
  }

  Future<bool> _checkAvailability(
      String resourceType, String resourceId, String timeSlot,
      {String? startTime, String? endTime}) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
      QuerySnapshot bookingQuery = await _firestore
          .collection('bookings')
          .where('resource_id', isEqualTo: resourceId)
          .where('date', isEqualTo: formattedDate)
          .get();

      if (bookingQuery.docs.isEmpty) return true;

      if (resourceType == 'desk') {
        for (var doc in bookingQuery.docs) {
          if (doc['time'] == timeSlot) return false;
        }
        return true;
      } else if (resourceType == 'room') {
        int requestedStart = _timeToMinutes(startTime!);
        int requestedEnd = _timeToMinutes(endTime!);
        for (var doc in bookingQuery.docs) {
          int bookedStart = _timeToMinutes(doc['start_time']);
          int bookedEnd = _timeToMinutes(doc['end_time']);
          if (requestedStart < bookedEnd && requestedEnd > bookedStart) {
            return false;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  int _timeToMinutes(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _saveBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String bookingId =
          'bk_${DateTime.now().millisecondsSinceEpoch}_${_userId.substring(0, Math.min(5, _userId.length))}';
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
      Timestamp timestamp = Timestamp.now();

      if (selectedBookingType == 'desk') {
        for (int i = 0; i < 2; i++) {
          if (selectedDesks[i] == true &&
              selectedDeskTimeSlots.containsKey(i)) {
            String resourceId = 'room_${i + 67890}';
            String timeSlot = selectedDeskTimeSlots[i]!;
            bool isAvailable =
                await _checkAvailability('desk', resourceId, timeSlot);

            var rnd = Math.Random();
            int val = 600 + rnd.nextInt(601);
            //int valTime = 5 + rnd.nextInt(25);
            int valTime = 30;

            if (isAvailable) {
              final jsonBody = {
                'booking_type': 'Hotdesk',
                'resource_id': resourceId,
                'date': formattedDate,
                'time': timeSlot,
                'status': 'pending',
                'timeout': valTime,
                'user_id': _userId,
                'karma_points': val,
              };
              print(jsonBody);
              sendRestCall(jsonBody);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Desk ${i + 67890} is not available for the selected time')),
              );
            }
          }
        }
      } else if (selectedBookingType == 'room') {
        for (int i = 0; i < 1; i++) {
          if ((selectedRooms[i] ?? false) &&
              roomTimes[i]!['start'] != null &&
              roomTimes[i]!['end'] != null) {
            String resourceId = 'room_${i + 1000}';
            String startTime = roomTimes[i]!['start']!;
            String endTime = roomTimes[i]!['end']!;
            DateTime start = DateTime.parse("2024-01-01 $startTime:00");
            DateTime end = DateTime.parse("2024-01-01 $endTime:00");
            int differenceInMinutes = end.difference(start).inMinutes;

            if (_timeToMinutes(startTime) >= _timeToMinutes(endTime)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'End time must be after start time for Room ${i + 1}')),
              );
              continue;
            }

            bool isAvailable = await _checkAvailability('room', resourceId, '',
                startTime: startTime, endTime: endTime);

            var rnd = Math.Random();
            int val = 600 + rnd.nextInt(601);

            if (isAvailable) {
              final jsonBody = {
                'booking_type': 'Conference Room',
                'resource_id': resourceId,
                'date': formattedDate,
                'start_time': startTime,
                'end_time': endTime,
                'status': 'pending',
                'timeout': differenceInMinutes,
                'user_id': _userId,
                'karma_points': val,
              };
              print(jsonBody);
              sendRestCall(jsonBody);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Room ${i + 1000} is not available for the selected time range')),
              );
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed successfully!')),
        );
        context.go('/');
      }
    } catch (e) {
      print('Error saving booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A47B8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xFF1A47B8),
                              size: 20,
                            ),
                            onPressed: () => context.go('/'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'New Booking',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A47B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedBookingType = 'desk';
                              for (int i = 0; i < 5; i++) {
                                selectedDesks[i] = false;
                              }
                              selectedDeskTimeSlots.clear();
                              _showCalendar = true;
                              _validateSelections();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedBookingType == 'desk'
                                ? const Color(0xFF1A47B8)
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Hot-Desk Station',
                            style: GoogleFonts.poppins(
                              color: selectedBookingType == 'desk'
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedBookingType = 'room';
                              for (int i = 0; i < 3; i++) {
                                selectedRooms[i] = false;
                                roomTimes[i] = {'start': null, 'end': null};
                              }
                              _showCalendar = true;
                              _validateSelections();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedBookingType == 'room'
                                ? const Color(0xFF1A47B8)
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Meeting Room',
                            style: GoogleFonts.poppins(
                              color: selectedBookingType == 'room'
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showCalendar) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Select Date',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A47B8),
                              ),
                            ),
                          ),
                          TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay:
                                DateTime.now().add(const Duration(days: 60)),
                            focusedDay: _focusedDay,
                            calendarFormat: CalendarFormat.week,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                if (selectedBookingType == 'desk') {
                                  for (int i = 0; i < 5; i++) {
                                    selectedDesks[i] = false;
                                  }
                                  selectedDeskTimeSlots.clear();
                                } else {
                                  for (int i = 0; i < 3; i++) {
                                    selectedRooms[i] = false;
                                    roomTimes[i] = {'start': null, 'end': null};
                                  }
                                }
                                _validateSelections();
                              });
                            },
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            calendarStyle: CalendarStyle(
                              selectedDecoration: const BoxDecoration(
                                  color: Color(0xFF1A47B8),
                                  shape: BoxShape.circle),
                              todayDecoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1A47B8).withOpacity(0.3),
                                  shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (selectedBookingType != null)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      selectedBookingType == 'desk'
                                          ? 'Desk'
                                          : 'Room',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Select',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      selectedBookingType == 'desk'
                                          ? 'Duration'
                                          : 'Time Range',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount:
                                    selectedBookingType == 'desk' ? 2 : 2,
                                itemBuilder: (context, index) {
                                  if (selectedBookingType == 'desk') {
                                    return buildDeskRow(index);
                                  } else {
                                    return buildRoomRow(index);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (selectedBookingType != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _hasSelection ? _saveBooking : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasSelection
                              ? const Color(0xFF1A47B8)
                              : Colors.grey,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget buildDeskRow(int index) {
    return FutureBuilder<bool>(
      future: _isAllDayDisabled(index, _selectedDay),
      builder: (context, snapshot) {
        final isAllDayDisabled = snapshot.data ?? false;
        final isMorningDisabled = _isMorningSlotDisabled(_selectedDay);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Desk ${index + 67890}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Checkbox(
                      value: selectedDesks[index],
                      onChanged: (value) {
                        setState(() {
                          selectedDesks[index] = value ?? false;
                          if (value == false) {
                            selectedDeskTimeSlots.remove(index);
                          }
                          _validateSelections();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: DropdownButton<String>(
                      value: selectedDeskTimeSlots[index],
                      hint: Text('Select time',
                          style: GoogleFonts.poppins(fontSize: 14)),
                      underline: Container(height: 1, color: Colors.grey),
                      isExpanded: true,
                      onChanged: selectedDesks[index] == true
                          ? (value) {
                              setState(() {
                                selectedDeskTimeSlots[index] = value!;
                                _validateSelections();
                              });
                            }
                          : null,
                      items: timeSlots.map((String slot) {
                        final isDisabled =
                            (slot == 'Morning' && isMorningDisabled) ||
                                (slot == 'All Day' && isAllDayDisabled);
                        return DropdownMenuItem<String>(
                          value: slot,
                          enabled: !isDisabled,
                          child: Text(
                            slot,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDisabled ? Colors.grey : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget buildRoomRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Room ${index + 1000}',
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                flex: 1,
                child: Checkbox(
                  value: selectedRooms[index] ?? false,
                  onChanged: (value) {
                    setState(() {
                      selectedRooms[index] = value ?? false;
                      if (value == false) {
                        roomTimes[index] = {'start': null, 'end': null};
                      }
                      _validateSelections();
                    });
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: roomTimes[index]!['start'],
                        hint: Text('Start',
                            style: GoogleFonts.poppins(fontSize: 14)),
                        underline: Container(height: 1, color: Colors.grey),
                        isExpanded: true,
                        onChanged: (selectedRooms[index] ?? false)
                            ? (value) {
                                setState(() {
                                  roomTimes[index]!['start'] = value;
                                  _validateSelections();
                                });
                              }
                            : null,
                        items: availableTimes.map((String time) {
                          final isDisabled =
                              _isTimeDisabled(time, _selectedDay);
                          return DropdownMenuItem<String>(
                            value: time,
                            enabled: !isDisabled,
                            child: Text(
                              time,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDisabled ? Colors.grey : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: roomTimes[index]!['end'],
                        hint: Text('End',
                            style: GoogleFonts.poppins(fontSize: 14)),
                        underline: Container(height: 1, color: Colors.grey),
                        isExpanded: true,
                        onChanged: (selectedRooms[index] ?? false)
                            ? (value) {
                                setState(() {
                                  roomTimes[index]!['end'] = value;
                                  _validateSelections();
                                });
                              }
                            : null,
                        items: availableTimes.map((String time) {
                          final isDisabled =
                              _isTimeDisabled(time, _selectedDay) ||
                                  (roomTimes[index]!['start'] != null &&
                                      _timeToMinutes(time) <=
                                          _timeToMinutes(
                                              roomTimes[index]!['start']!));
                          return DropdownMenuItem<String>(
                            value: time,
                            enabled: !isDisabled,
                            child: Text(
                              time,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDisabled ? Colors.grey : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (roomTimes[index]!['start'] != null &&
              roomTimes[index]!['end'] != null &&
              _timeToMinutes(roomTimes[index]!['start']!) >=
                  _timeToMinutes(roomTimes[index]!['end']!))
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'End time must be after start time',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
