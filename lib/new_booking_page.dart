import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;

class NewBookingPage extends StatefulWidget {
  const NewBookingPage({super.key});

  @override
  State<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends State<NewBookingPage> {
  // Booking type selection
  String? selectedBookingType;
  
  // Calendar selection
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;
  
  // Time slots and ranges
  final List<String> timeSlots = ['Morning', 'Afternoon', 'All Day'];
  final List<String> availableTimes = [
    '9:00', '9:30', '10:00', '10:30', '11:00', '11:30', 
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00'
  ];
  
  // Selected resources
  final Map<int, bool> selectedDesks = {};
  final Map<int, Map<String, String?>> roomTimes = {};
  final Map<int, String> selectedDeskTimeSlots = {};

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Loading state
  bool _isLoading = false;
  
  // Form validation
  bool _hasSelection = false;
  
  // User ID
  String _userId = "anonymous";

  @override
  void initState() {
    super.initState();
    // Initialize selections
    for (int i = 0; i < 5; i++) {
      selectedDesks[i] = false;
    }
    
    for (int i = 0; i < 3; i++) {
      roomTimes[i] = {
        'start': null,
        'end': null,
      };
    }
    
    // Get current user
    _userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
  }
  
  // Check if user has made a valid selection
  void _validateSelections() {
    bool hasValid = false;
    
    if (selectedBookingType == 'desk') {
      // Check if any desk is selected with a time slot
      for (int i = 0; i < 5; i++) {
        if (selectedDesks[i] == true && selectedDeskTimeSlots.containsKey(i)) {
          hasValid = true;
          break;
        }
      }
    } else if (selectedBookingType == 'room') {
      // Check if any room has both start and end times
      for (int i = 0; i < 3; i++) {
        if (roomTimes[i]!['start'] != null && roomTimes[i]!['end'] != null) {
          hasValid = true;
          break;
        }
      }
    }
    
    setState(() {
      _hasSelection = hasValid;
    });
  }

  // Check if a resource is available for the selected day and time
  Future<bool> _checkAvailability(String resourceType, String resourceId, String timeSlot, {String? startTime, String? endTime}) async {
    try {
      // Format date for the query
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
      
      // Query existing bookings for this resource on this day
      QuerySnapshot bookingQuery = await _firestore
          .collection('bookings')
          .where('resource_id', isEqualTo: resourceId)
          .where('date', isEqualTo: formattedDate)
          .get();
      
      if (bookingQuery.docs.isEmpty) {
        return true; // No bookings found, resource is available
      }
      
      // For desk bookings, check time slot conflicts
      if (resourceType == 'desk') {
        for (var doc in bookingQuery.docs) {
          if (doc['time'] == timeSlot) {
            return false; // Time slot already booked
          }
        }
        return true;
      } 
      // For room bookings, check time range conflicts
      else if (resourceType == 'room') {
        // Convert times to comparable format (minutes since start of day)
        int requestedStart = _timeToMinutes(startTime!);
        int requestedEnd = _timeToMinutes(endTime!);
        
        for (var doc in bookingQuery.docs) {
          int bookedStart = _timeToMinutes(doc['start_time']);
          int bookedEnd = _timeToMinutes(doc['end_time']);
          
          // Check for overlap
          if (requestedStart < bookedEnd && requestedEnd > bookedStart) {
            return false; // Time range conflict
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
  
  // Convert time string to minutes for comparison
  int _timeToMinutes(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Save booking to Firestore
  Future<void> _saveBooking() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate a unique booking ID
      String bookingId = 'bk_${DateTime.now().millisecondsSinceEpoch}_${_userId.substring(0, Math.min(5, _userId.length))}';
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
      
      // Generate timestamp
      Timestamp timestamp = Timestamp.now();
      
      if (selectedBookingType == 'desk') {
        // Process desk bookings
        for (int i = 0; i < 5; i++) {
          if (selectedDesks[i] == true && selectedDeskTimeSlots.containsKey(i)) {
            String resourceId = 'desk_${i + 1}';
            String timeSlot = selectedDeskTimeSlots[i]!;
            
            // Check availability before booking
            bool isAvailable = await _checkAvailability('desk', resourceId, timeSlot);
            
            if (isAvailable) {
              await _firestore.collection('bookings').add({
                'booking_id': bookingId,
                'booking_type': 'Hot-Desk Station',
                'resource_id': resourceId,
                'date': formattedDate,
                'time': timeSlot,
                'status': 'approved',
                'timeout': '120',
                'timestamp': timestamp,
                'user_id': _userId,
                'karma_points': 500, // Example value
              });
            } else {
              // Show error for unavailable resource
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Desk ${i + 1} is not available for the selected time')),
              );
            }
          }
        }
      } else if (selectedBookingType == 'room') {
        // Process room bookings
        for (int i = 0; i < 3; i++) {
          if (roomTimes[i]!['start'] != null && roomTimes[i]!['end'] != null) {
            String resourceId = 'room_${i + 1000}';
            String startTime = roomTimes[i]!['start']!;
            String endTime = roomTimes[i]!['end']!;
            
            // Check if start time is before end time
            if (_timeToMinutes(startTime) >= _timeToMinutes(endTime)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('End time must be after start time for Room ${i + 1}')),
              );
              continue;
            }
            
            // Check availability before booking
            bool isAvailable = await _checkAvailability(
              'room', 
              resourceId, 
              '', 
              startTime: startTime, 
              endTime: endTime
            );
            
            if (isAvailable) {
              await _firestore.collection('bookings').add({
                'booking_id': bookingId,
                'booking_type': 'Conference Room',
                'resource_id': resourceId,
                'date': formattedDate,
                'start_time': startTime,
                'end_time': endTime,
                'status': 'approved',
                'timeout': '120',
                'timestamp': timestamp,
                'user_id': _userId,
                'karma_points': 1200, // Example value
              });
            } else {
              // Show error for unavailable resource
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Room ${i + 1} is not available for the selected time range')),
              );
            }
          }
        }
      }
      
      // Navigate back to home page
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
                // Header with back button
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

                // Booking Type Buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedBookingType = 'desk';
                            // Reset all selections
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
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            // Reset all room times
                            for (int i = 0; i < 3; i++) {
                              roomTimes[i] = {
                                'start': null,
                                'end': null,
                              };
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
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

                // Calendar (visible after booking type selection)
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
                          lastDay: DateTime.now().add(const Duration(days: 60)),
                          focusedDay: _focusedDay,
                          calendarFormat: CalendarFormat.week,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              // Reset selections when day changes
                              if (selectedBookingType == 'desk') {
                                for (int i = 0; i < 5; i++) {
                                  selectedDesks[i] = false;
                                }
                                selectedDeskTimeSlots.clear();
                              } else {
                                for (int i = 0; i < 3; i++) {
                                  roomTimes[i] = {
                                    'start': null,
                                    'end': null,
                                  };
                                }
                              }
                              _validateSelections();
                            });
                          },
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF1A47B8),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF1A47B8).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Availability Table
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
                          // Table Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: selectedBookingType == 'desk' ? 1 : 2,
                                  child: Text(
                                    selectedBookingType == 'desk' ? 'Desk' : 'Room',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (selectedBookingType == 'desk') ...[
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Select',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Duration',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Time Range',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Table Content
                          Expanded(
                            child: ListView.builder(
                              itemCount: selectedBookingType == 'desk' ? 5 : 3,
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

                // Confirm Button
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  Widget buildDeskRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Desk ${index + 1}',
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
                      // Clear time slot if desk is deselected
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
                  hint: Text('Select time', style: GoogleFonts.poppins(fontSize: 14)),
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
                    return DropdownMenuItem<String>(
                      value: slot,
                      child: Text(slot, style: GoogleFonts.poppins(fontSize: 14)),
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
  }

  Widget buildRoomRow(int index) {
    // Function to validate time selection
    bool isValidTimeSelection() {
      if (roomTimes[index]!['start'] == null || roomTimes[index]!['end'] == null) {
        return true; // Not both times selected yet
      }
      
      // Check if start time is before end time
      int startMinutes = _timeToMinutes(roomTimes[index]!['start']!);
      int endMinutes = _timeToMinutes(roomTimes[index]!['end']!);
      
      return startMinutes < endMinutes;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Room ${index + 1}',
                  style: GoogleFonts.poppins(),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: DropdownButton<String>(
                          value: roomTimes[index]!['start'],
                          hint: Text('Start', style: GoogleFonts.poppins(fontSize: 14)),
                          underline: Container(height: 1, color: Colors.grey),
                          isExpanded: true,
                          items: availableTimes.map((String time) {
                            return DropdownMenuItem<String>(
                              value: time,
                              child: Text(time, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              roomTimes[index]!['start'] = newValue;
                              _validateSelections();
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          'to',
                          style: GoogleFonts.poppins(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<String>(
                          value: roomTimes[index]!['end'],
                          hint: Text('End', style: GoogleFonts.poppins(fontSize: 14)),
                          underline: Container(height: 1, color: Colors.grey),
                          isExpanded: true,
                          items: availableTimes.map((String time) {
                            return DropdownMenuItem<String>(
                              value: time,
                              child: Text(time, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              roomTimes[index]!['end'] = newValue;
                              _validateSelections();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Warning if invalid time selection
          if (!isValidTimeSelection())
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'End time must be after start time',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}