import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterdb/firestore/booking_service.dart';

class NewBookingPage extends StatefulWidget {
  const NewBookingPage({super.key});

  @override
  State<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends State<NewBookingPage> {
  String? selectedBookingType;
  DateTime selectedDate = DateTime.now();
  final BookingService bookingService = BookingService();
  String? selectedTimeSlot;
  String? selectedSpaceId;  // This will store either room or desk ID
  
  final List<String> timeSlots = ['Morning', 'Afternoon', 'Full day'];
  
  // Add lists for rooms and desks
  final List<String> roomIds = ['room1', 'room2', 'room3'];  // Replace with your actual room IDs
  final List<String> deskIds = ['desk1', 'desk2', 'desk3', 'desk4', 'desk5'];  // Replace with your actual desk IDs

  void _confirmBooking() async {
    try {
      if (selectedBookingType == null) {
        _showError('Please select a booking type');
        return;
      }

      if (selectedSpaceId == null) {
        _showError('Please select a ${selectedBookingType == "room" ? "room" : "desk"}');
        return;
      }

      if (selectedTimeSlot == null) {
        _showError('Please select a time slot');
        return;
      }

      // Check availability based on booking type
      bool isAvailable;
      if (selectedBookingType == 'room') {
        isAvailable = await bookingService.isRoomAvailable(
          selectedSpaceId!,
          selectedDate,
          selectedTimeSlot!
        );
      } else {
        isAvailable = await bookingService.isDeskAvailable(
          selectedSpaceId!,
          selectedDate,
          selectedTimeSlot!
        );
      }

      if (!isAvailable) {
        _showError('This ${selectedBookingType == "room" ? "room" : "desk"} is not available for the selected time slot');
        return;
      }

      // Create the booking based on type
      if (selectedBookingType == 'room') {
        await bookingService.createBooking(
          roomId: selectedSpaceId!,
          dateBooked: selectedDate,
          timeSlot: selectedTimeSlot!,
        );
      } else {
        await bookingService.createDeskBooking(
          deskId: selectedSpaceId!,
          dateBooked: selectedDate,
          timeSlot: selectedTimeSlot!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully'))
        );
        context.go('/');
      }
    } catch (e) {
      _showError('Error creating booking: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header (same as before)...
             Container(
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

            // Booking Type Selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() {
                        selectedBookingType = 'desk';
                        selectedSpaceId = null;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedBookingType == 'desk' 
                          ? const Color(0xFF1A47B8) 
                          : Colors.grey[300],
                      ),
                      child: Text(
                        'Hot-Desk',
                        style: GoogleFonts.poppins(
                          color: selectedBookingType == 'desk' 
                            ? Colors.white 
                            : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() {
                        selectedBookingType = 'room';
                        selectedSpaceId = null;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedBookingType == 'room' 
                          ? const Color(0xFF1A47B8) 
                          : Colors.grey[300],
                      ),
                      child: Text(
                        'Meeting Room',
                        style: GoogleFonts.poppins(
                          color: selectedBookingType == 'room' 
                            ? Colors.white 
                            : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Date Selection
            if (selectedBookingType != null) Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                title: Text('Select Date', style: GoogleFonts.poppins()),
                trailing: TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ),
            ),

            // Space Selection (Room or Desk)
            if (selectedBookingType != null) Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select ${selectedBookingType == "room" ? "Room" : "Desk"}',
                  labelStyle: GoogleFonts.poppins(),
                ),
                value: selectedSpaceId,
                items: (selectedBookingType == "room" ? roomIds : deskIds).map((String id) {
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      '${selectedBookingType == "room" ? "Room" : "Desk"} ${id.substring(id.length - 1)}',
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedSpaceId = value;
                  });
                },
              ),
            ),

            // Time Slot Selection
            if (selectedBookingType != null && selectedSpaceId != null) Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Time Slot',
                  labelStyle: GoogleFonts.poppins(),
                ),
                value: selectedTimeSlot,
                items: timeSlots.map((String slot) {
                  return DropdownMenuItem<String>(
                    value: slot,
                    child: Text(slot, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedTimeSlot = value;
                  });
                },
              ),
            ),

            // Confirm Button
            if (selectedBookingType != null && selectedSpaceId != null && selectedTimeSlot != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A47B8),
                    minimumSize: const Size(200, 50),
                  ),
                  child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



//DO NOT DELETE
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';

// class NewBookingPage extends StatefulWidget {
//   const NewBookingPage({super.key});

//   @override
//   State<NewBookingPage> createState() => _NewBookingPageState();
// }

// class _NewBookingPageState extends State<NewBookingPage> {
//   String? selectedBookingType;
//   final List<String> timeSlots = ['Morning', 'Afternoon', 'All Day'];
//   final List<String> availableTimes = [
//     '9:00', '9:30', '10:00', '10:30', '11:00', '11:30', 
//     '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
//     '15:00', '15:30', '16:00', '16:30', '17:00'
//   ];
  
//   // Map to store selected times for each room
//   final Map<int, Map<String, String?>> roomTimes = {};

//   @override
//   void initState() {
//     super.initState();
//     // Initialize the room times
//     for (int i = 0; i < 3; i++) {  // for 3 rooms
//       roomTimes[i] = {
//         'start': null,
//         'end': null,
//       };
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header with back button
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF1A47B8).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.arrow_back_ios_new,
//                         color: Color(0xFF1A47B8),
//                         size: 20,
//                       ),
//                       onPressed: () => context.go('/'),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Text(
//                     'New Booking',
//                     style: GoogleFonts.poppins(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF1A47B8),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Booking Type Buttons
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         selectedBookingType = 'desk';
//                         // Reset all room times
//                         for (int i = 0; i < 3; i++) {
//                           roomTimes[i] = {
//                             'start': null,
//                             'end': null,
//                           };
//                         }
//                       });
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: selectedBookingType == 'desk'
//                           ? const Color(0xFF1A47B8)
//                           : Colors.grey[300],
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 32,
//                         vertical: 16,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Hot-Desk Station',
//                       style: GoogleFonts.poppins(
//                         color: selectedBookingType == 'desk'
//                             ? Colors.white
//                             : Colors.black,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         selectedBookingType = 'room';
//                         // Reset all room times
//                         for (int i = 0; i < 3; i++) {
//                           roomTimes[i] = {
//                             'start': null,
//                             'end': null,
//                           };
//                         }
//                       });
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: selectedBookingType == 'room'
//                           ? const Color(0xFF1A47B8)
//                           : Colors.grey[300],
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 32,
//                         vertical: 16,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       'Meeting Room',
//                       style: GoogleFonts.poppins(
//                         color: selectedBookingType == 'room'
//                             ? Colors.white
//                             : Colors.black,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Availability Table
//             if (selectedBookingType != null)
//               Expanded(
//                 child: Container(
//                   margin: const EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Column(
//                     children: [
//                       // Table Header
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               flex: selectedBookingType == 'desk' ? 1 : 2,
//                               child: Text(
//                                 selectedBookingType == 'desk' ? 'Desk' : 'Room',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             if (selectedBookingType == 'desk') ...[
//                               Expanded(
//                                 flex: 1,
//                                 child: Text(
//                                   'Select',
//                                   style: GoogleFonts.poppins(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                               Expanded(
//                                 flex: 2,
//                                 child: Text(
//                                   'Duration',
//                                   style: GoogleFonts.poppins(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ] else
//                               Expanded(
//                                 flex: 3,
//                                 child: Text(
//                                   'Time Range',
//                                   style: GoogleFonts.poppins(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
                      
//                       // Table Content
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: selectedBookingType == 'desk' ? 5 : 3, // 3 rooms example
//                           itemBuilder: (context, index) {
//                             if (selectedBookingType == 'desk') {
//                               return buildDeskRow(index);
//                             } else {
//                               return buildRoomRow(index);
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             // Confirm Button
//             if (selectedBookingType != null)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Handle confirmation
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1A47B8),
//                     minimumSize: const Size(200, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'Confirm',
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildDeskRow(int index) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16.0,
//         vertical: 8.0,
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 flex: 1,
//                 child: Text(
//                   '${index + 1}',
//                   style: GoogleFonts.poppins(),
//                 ),
//               ),
//               Expanded(
//                 flex: 1,
//                 child: Checkbox(
//                   value: false,
//                   onChanged: (value) {},
//                 ),
//               ),
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   'Morning',
//                   style: GoogleFonts.poppins(),
//                 ),
//               ),
//             ],
//           ),
//           ...List.generate(
//             timeSlots.length - 1, 
//             (slotIndex) => Row(
//               children: [
//                 Expanded(
//                   flex: 1,
//                   child: Text(
//                     '',
//                     style: GoogleFonts.poppins(),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: Checkbox(
//                     value: false,
//                     onChanged: (value) {},
//                   ),
//                 ),
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     timeSlots[slotIndex + 1],
//                     style: GoogleFonts.poppins(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildRoomRow(int index) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16.0,
//         vertical: 8.0,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               'Room ${index + 1}',
//               style: GoogleFonts.poppins(),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Container(
//                     alignment: Alignment.centerRight,
//                     child: DropdownButton<String>(
//                       value: roomTimes[index]!['start'],
//                       hint: Text('Start', style: GoogleFonts.poppins()),
//                       items: availableTimes.map((String time) {
//                         return DropdownMenuItem<String>(
//                           value: time,
//                           child: Text(time, style: GoogleFonts.poppins()),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           roomTimes[index]!['start'] = newValue;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 60,
//                   child: Center(
//                     child: Text(
//                       'to',
//                       style: GoogleFonts.poppins(),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 2,
//                   child: Container(
//                     alignment: Alignment.centerLeft,
//                     child: DropdownButton<String>(
//                       value: roomTimes[index]!['end'],
//                       hint: Text('End', style: GoogleFonts.poppins()),
//                       items: availableTimes.map((String time) {
//                         return DropdownMenuItem<String>(
//                           value: time,
//                           child: Text(time, style: GoogleFonts.poppins()),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           roomTimes[index]!['end'] = newValue;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }