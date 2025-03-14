import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math';

// Status enum for tracking availability
enum ResourceStatus {
  available,
  booked,
  partiallyAvailable,
  myBooking
}

class FloorPlanModel extends StatefulWidget {
  final DateTime? selectedDate;
  final String? userId; // Current user ID to identify "my bookings"

  const FloorPlanModel({
    super.key,
    this.selectedDate,
    this.userId,
  });

  @override
  _FloorPlanModelState createState() => _FloorPlanModelState();
}

class _FloorPlanModelState extends State<FloorPlanModel> {
  String selectedFloor = '1st';
  int currentIndex = 0;
  bool isLoading = true;
  late DateTime _currentDate;
  
  // Maps to store status of each resource
  Map<String, ResourceStatus> deskStatuses = {};
  Map<String, ResourceStatus> roomStatuses = {};
  
  // Maps to store booking details for tooltips
  Map<String, Map<String, dynamic>> deskBookingDetails = {};
  Map<String, Map<String, dynamic>> roomBookingDetails = {};

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate ?? DateTime.now();
    _loadResourceStatuses();
  }

  // Load booking data from Firestore
  Future<void> _loadResourceStatuses() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Format the selected date
      String formattedDate = DateFormat('yyyy-MM-dd').format(_currentDate);
      
      // Reset status maps
      deskStatuses.clear();
      roomStatuses.clear();
      deskBookingDetails.clear();
      roomBookingDetails.clear();
      
      // Initialize all resources as available
      _initializeResourceStatuses();
      
      // Fetch all bookings for this date from the bookings collection
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isEqualTo: formattedDate)
          .get();

      // Process each booking
      for (var doc in bookingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String resourceId = data['resource_id'] as String;
        String userId = data['user_id'] as String;
        String bookingType = data['booking_type'] as String;
        String status = data['status'] as String;
        
        // Only process approved bookings
        if (status != 'approved') continue;
        
        bool isMyBooking = userId == widget.userId;
        
        // Process desk/hotdesk bookings
        if (bookingType.toLowerCase().contains('hotdesk') || resourceId.startsWith('room_6')) {
          if (resourceId.startsWith('room_6')) {
            // Hotdesk bookings with IDs like "room_67890"
            String deskId = resourceId;
            
            // Only process desks for the current floor
            if ((selectedFloor == '1st' && int.parse(deskId.split('_')[1]) >= 67890 && int.parse(deskId.split('_')[1]) < 67892) ||
                (selectedFloor == '2nd' && int.parse(deskId.split('_')[1]) >= 67892)) {
              
              // Check time slot
              String timeSlot = data['time'] ?? 'All Day';
              
              // Store full booking details for tooltip
              deskBookingDetails[deskId] = {
                'status': status,
                'time': timeSlot,
                'isMyBooking': isMyBooking,
                'date': formattedDate,
                'duration': data['timeout'] ?? 0,
              };
              
              // Set status based on ownership
              deskStatuses[deskId] = isMyBooking 
                  ? ResourceStatus.myBooking 
                  : ResourceStatus.booked;
            }
          }
        } 
        // Process conference room bookings
        else if (bookingType.toLowerCase().contains('conference') || resourceId.startsWith('room_1')) {
          if (resourceId.startsWith('room_1')) {
            // Room bookings with IDs like "room_1000"
            String roomId = resourceId;
            
            // Only process rooms for the current floor
            if ((selectedFloor == '1st' && int.parse(roomId.split('_')[1]) < 1005) ||
                (selectedFloor == '2nd' && int.parse(roomId.split('_')[1]) >= 1005)) {
              
              // Get time range
              String startTime = data['start_time'] ?? '';
              String endTime = data['end_time'] ?? '';
              
              // Store full booking details for tooltip
              roomBookingDetails[roomId] = {
                'status': status,
                'start_time': startTime,
                'end_time': endTime,
                'isMyBooking': isMyBooking,
                'date': formattedDate,
                'duration': data['timeout'] ?? 0,
              };
              
              // Set status based on ownership
              roomStatuses[roomId] = isMyBooking 
                  ? ResourceStatus.myBooking 
                  : ResourceStatus.booked;
            }
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading resource statuses: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Initialize all resources as available
  void _initializeResourceStatuses() {
    // Initialize desk statuses based on floor
    if (selectedFloor == '1st') {
      // First floor desks (room_67890, room_67891)
      for (int i = 67890; i < 67892; i++) {
        deskStatuses['room_$i'] = ResourceStatus.available;
      }
      
      // First floor rooms (room_1000 to room_1004)
      for (int i = 1000; i < 1005; i++) {
        roomStatuses['room_$i'] = ResourceStatus.available;
      }
    } else {
      // Second floor desks (room_67892+)
      for (int i = 67892; i < 67894; i++) {
        deskStatuses['room_$i'] = ResourceStatus.available;
      }
      
      // Second floor rooms (room_1005+)
      for (int i = 1005; i < 1010; i++) {
        roomStatuses['room_$i'] = ResourceStatus.available;
      }
    }
  }

  // Get color based on resource status
  Color getStatusColor(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.available:
        return Colors.green;
      case ResourceStatus.booked:
        return Colors.red;
      case ResourceStatus.partiallyAvailable:
        return Colors.orange;
      case ResourceStatus.myBooking:
        return Colors.blue;
    }
  }

  void _changeDate(DateTime date) {
    setState(() {
      _currentDate = date;
    });
    _loadResourceStatuses();
  }

  Widget _buildDeskMap() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 600,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: DeskMapPainter(
                      selectedFloor, 
                      deskStatuses,
                      deskBookingDetails,
                      (resourceId) => _showBookingDetails(resourceId, true)
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildMeetingRoomMap() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 600,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MeetingRoomMapPainter(
                      selectedFloor, 
                      roomStatuses,
                      roomBookingDetails,
                      (resourceId) => _showBookingDetails(resourceId, false)
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
          );
  }
  
  // Show booking details when a resource is tapped
  void _showBookingDetails(String resourceId, bool isDesk) {
    Map<String, dynamic>? details = isDesk 
        ? deskBookingDetails[resourceId] 
        : roomBookingDetails[resourceId];
        
    if (details == null) {
      // If no booking, show available message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Resource Available'),
            content: Text('$resourceId is available for booking.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        }
      );
      return;
    }
    
    // Show booking details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isMyBooking = details['isMyBooking'] ?? false;
        
        return AlertDialog(
          title: Text(
            isMyBooking ? 'Your Booking' : 'Booked Resource',
            style: TextStyle(
              color: isMyBooking ? Colors.blue : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resource: $resourceId'),
              Text('Date: ${details['date']}'),
              if (isDesk) Text('Time Slot: ${details['time']}'),
              if (!isDesk) ...[
                Text('Start Time: ${details['start_time']}'),
                Text('End Time: ${details['end_time']}'),
              ],
              Text('Duration: ${details['duration']} minutes'),
              Text('Status: ${details['status']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    currentIndex == 0 ? 'Desk map' : 'Meeting room map',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  // Date picker with smaller size to fix overflow
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _currentDate,
                        firstDate: DateTime.now().subtract(Duration(days: 30)),
                        lastDate: DateTime.now().add(Duration(days: 60)),
                      );
                      if (picked != null && picked != _currentDate) {
                        _changeDate(picked);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8E9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF1A47B8)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Color(0xFF1A47B8)),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(_currentDate),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1A47B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => currentIndex = 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.desktop_windows,
                          color: currentIndex == 0 ? Color(0xFF1A47B8) : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Desk map',
                          style: GoogleFonts.poppins(
                            color: currentIndex == 0 ? Color(0xFF1A47B8) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 32),
                  InkWell(
                    onTap: () => setState(() => currentIndex = 1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          color: currentIndex == 1 ? Color(0xFF1A47B8) : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Meeting room',
                          style: GoogleFonts.poppins(
                            color: currentIndex == 1 ? Color(0xFF1A47B8) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: Colors.grey[300],
              thickness: 2,
              indent: 16,
              endIndent: 16,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Select floor:',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(width: 16),
                  _buildFloorButton('1st'),
                  SizedBox(width: 16),
                  _buildFloorButton('2nd'),
                ],
              ),
            ),

            Expanded(
              child: currentIndex == 0 ? _buildDeskMap() : _buildMeetingRoomMap(),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildLegendItem('My booking', Colors.blue),
                  _buildLegendItem('Available', Colors.green),
                  _buildLegendItem('Booked', Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorButton(String floor) {
    final isSelected = selectedFloor == floor;
    return InkWell(
      onTap: () {
        setState(() {
          selectedFloor = floor;
          _loadResourceStatuses(); // Reload statuses when floor changes
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE8E9FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF1A47B8) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Text(
              floor,
              style: GoogleFonts.poppins(
                color: isSelected ? Color(0xFF1A47B8) : Colors.grey[600],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: Color(0xFF1A47B8)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }
}

// Custom painter for desk map
class DeskMapPainter extends CustomPainter {
  final String floor;
  final Map<String, ResourceStatus> deskStatuses;
  final Map<String, Map<String, dynamic>> deskBookingDetails;
  final Function(String) onTapResource;
  
  DeskMapPainter(this.floor, this.deskStatuses, this.deskBookingDetails, this.onTapResource);
  
  // Track clickable regions for hotspots
  final Map<String, Rect> clickableRegions = {};

  @override
  void paint(Canvas canvas, Size size) {
    // Clear previous clickable regions
    clickableRegions.clear();
    
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final tablePaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;
    
    // Center the drawing in the available space
    double centerX = size.width / 2;
    
    // Table dimensions
    double tableWidth = 180;
    double tableHeight = 40;
    double tableSpacing = 120; // Increased spacing between tables

    // First floor has 3 tables, second floor has 2 tables
    int numTables = floor == '1st' ? 1 : 1; // Just display 1 table per floor for simplicity
    
    // Calculate total height needed
    double totalHeight = numTables * (tableHeight + tableSpacing);
    double startY = (size.height - totalHeight) / 2;

    for (int i = 0; i < numTables; i++) {
      double yOffset = startY + (i * (tableHeight + tableSpacing));
      double tableX = centerX - (tableWidth / 2);
      
      // Draw table
      canvas.drawRect(
        Rect.fromLTWH(tableX, yOffset, tableWidth, tableHeight),
        tablePaint
      );

      // Draw desks based on floor
      int baseIndex = floor == '1st' ? 67890 : 67892;
      
      // Draw desks for the specified floor
      _drawDesk(canvas, tableX + 45, yOffset - 25, baseIndex, size);
      _drawDesk(canvas, tableX + 135, yOffset - 25, baseIndex + 1, size);
    }
  }
  
  void _drawDesk(Canvas canvas, double x, double y, int deskNumber, Size size) {
    String deskId = 'room_$deskNumber';
    ResourceStatus status = deskStatuses[deskId] ?? ResourceStatus.available;
    
    // Choose color based on status
    Color statusColor;
    switch (status) {
      case ResourceStatus.available:
        statusColor = Colors.green;
      case ResourceStatus.booked:
        statusColor = Colors.red;
      case ResourceStatus.partiallyAvailable:
        statusColor = Colors.orange;
      case ResourceStatus.myBooking:
        statusColor = Colors.blue;
    }
    
    // Draw chair circle with status color
    final fillPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw filled circle
    canvas.drawCircle(Offset(x, y), 20, fillPaint);
    
    // Draw border
    canvas.drawCircle(Offset(x, y), 20, borderPaint);
    
    // Store clickable region
    clickableRegions[deskId] = Rect.fromCircle(center: Offset(x, y), radius: 20);
    
    // Create a paragraph to draw text properly
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: 12,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.black))
      ..addText('Desk $deskNumber');
    
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: 80));
    
    // Position text
    double textY = y - 35; // Put text above the circle
    
    canvas.drawParagraph(
      paragraph,
      Offset(x - 40, textY)
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
  
  @override
  bool hitTest(Offset position) {
    for (var entry in clickableRegions.entries) {
      if (entry.value.contains(position)) {
        onTapResource(entry.key);
        return true;
      }
    }
    return false;
  }
}

// Custom painter for meeting room map
class MeetingRoomMapPainter extends CustomPainter {
  final String floor;
  final Map<String, ResourceStatus> roomStatuses;
  final Map<String, Map<String, dynamic>> roomBookingDetails;
  final Function(String) onTapResource;
  
  MeetingRoomMapPainter(this.floor, this.roomStatuses, this.roomBookingDetails, this.onTapResource);
  
  // Track clickable regions for hotspots
  final Map<String, Rect> clickableRegions = {};

  @override
  void paint(Canvas canvas, Size size) {
    // Clear previous clickable regions
    clickableRegions.clear();
    
    // Base room number based on floor
    final int baseRoomNum = floor == '1st' ? 1000 : 1005;
    
    // Calculate available width to fit all rooms without overflow
    double availableWidth = size.width - 32; // Account for padding
    double roomWidth = min(170.0, availableWidth * 0.45); // Limit maximum size and make proportional
    double roomHeight = roomWidth * 0.9; // Maintain aspect ratio
    double horizontalGap = (availableWidth - (roomWidth * 2)) / 3; // Distribute remaining space
    
    // Just display the first room for simplicity
    int roomNumber = baseRoomNum;
    String roomId = 'room_$roomNumber';
    ResourceStatus status = roomStatuses[roomId] ?? ResourceStatus.available;
    
    // Position room centered
    double xOffset = (size.width - roomWidth) / 2;
    double yOffset = 100;
    
    _drawMeetingRoom(
      canvas,
      xOffset,
      yOffset,
      roomNumber,
      status,
      roomWidth,
      roomHeight
    );
    
    // Store clickable region
    clickableRegions[roomId] = Rect.fromLTWH(xOffset, yOffset, roomWidth, roomHeight);
  }

  void _drawMeetingRoom(Canvas canvas, double x, double y, int roomNumber, ResourceStatus status, double width, double height) {
    // Choose color based on status
    Color statusColor;
    switch (status) {
      case ResourceStatus.available:
        statusColor = Colors.green.withOpacity(0.2);
      case ResourceStatus.booked:
        statusColor = Colors.red.withOpacity(0.2);
      case ResourceStatus.partiallyAvailable:
        statusColor = Colors.orange.withOpacity(0.2);
      case ResourceStatus.myBooking:
        statusColor = Colors.blue.withOpacity(0.2);
    }
    
    // Draw room rectangle with status color
    final roomPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw filled rectangle
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      roomPaint
    );
    
    // Draw border
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      borderPaint
    );

    // Draw room name text using paragraph
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: 18,
      fontWeight: ui.FontWeight.bold,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.black))
      ..addText('Room $roomNumber');
    
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    
    // Position text at the top of the room, above the circles
    canvas.drawParagraph(
      paragraph,
      Offset(x, y + 10)
    );
    
    // Draw capacity indicator
    final capacityText = '6 people';
    
    final capacityBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: 14,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.black54))
      ..addText(capacityText);
    
    final capacityParagraph = capacityBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    
    // Position capacity text at bottom of room
    canvas.drawParagraph(
      capacityParagraph,
      Offset(x, y + height - 30)
    );
    
    // Draw chair circles
    final chairPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Large room - 6 chairs in a grid pattern
    // Left column
    canvas.drawCircle(Offset(x + width * 0.3, y + height * 0.3), 10, chairPaint);
    canvas.drawCircle(Offset(x + width * 0.3, y + height * 0.5), 10, chairPaint);
    canvas.drawCircle(Offset(x + width * 0.3, y + height * 0.7), 10, chairPaint);
    
    // Right column
    canvas.drawCircle(Offset(x + width * 0.7, y + height * 0.3), 10, chairPaint);
    canvas.drawCircle(Offset(x + width * 0.7, y + height * 0.5), 10, chairPaint);
    canvas.drawCircle(Offset(x + width * 0.7, y + height * 0.7), 10, chairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
  
  @override
  bool hitTest(Offset position) {
    for (var entry in clickableRegions.entries) {
      if (entry.value.contains(position)) {
        onTapResource(entry.key);
        return true;
      }
    }
    return false;
  }
}