import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    Key? key,
    this.selectedDate,
    this.userId,
  }) : super(key: key);

  @override
  _FloorPlanModelState createState() => _FloorPlanModelState();
}

class _FloorPlanModelState extends State<FloorPlanModel> {
  String selectedFloor = '1st';
  int currentIndex = 0;
  bool isLoading = true;
  
  // Maps to store status of each resource
  Map<String, ResourceStatus> deskStatuses = {};
  Map<String, ResourceStatus> roomStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadResourceStatuses();
  }

  // Load booking data from Firestore
  Future<void> _loadResourceStatuses() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Format the selected date
      final dateToUse = widget.selectedDate ?? DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateToUse);
      
      // Fetch all bookings for this date
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isEqualTo: formattedDate)
          .get();

      // Reset statuses
      deskStatuses.clear();
      roomStatuses.clear();

      // Initialize all desks as available
      for (int floor = 1; floor <= 2; floor++) {
        String floorStr = floor == 1 ? '1st' : '2nd';
        int numDesks = floorStr == '1st' ? 9 : 6; // 3 tables * 3 seats for 1st floor, 2 tables * 3 seats for 2nd floor
        
        for (int i = 1; i <= numDesks; i++) {
          deskStatuses['desk_${floorStr}_$i'] = ResourceStatus.available;
        }
      }

      // Initialize all rooms as available
      for (int floor = 1; floor <= 2; floor++) {
        String floorStr = floor == 1 ? '1st' : '2nd';
        int baseRoomNum = floorStr == '1st' ? 1 : 6;
        
        for (int i = 0; i < 6; i++) { // 6 rooms per floor (3 rows * 2 columns)
          int roomNum = baseRoomNum + i;
          roomStatuses['room_${floorStr}_$roomNum'] = ResourceStatus.available;
        }
      }

      // Process bookings to update statuses
      for (var doc in bookingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String resourceId = data['resource_id'] as String;
        bool isMyBooking = data['user_id'] == widget.userId;
        
        if (resourceId.startsWith('desk_')) {
          // Extract floor and desk number
          List<String> parts = resourceId.split('_');
          String deskId = 'desk_${parts[1]}_${parts[2]}';
          
          deskStatuses[deskId] = isMyBooking 
              ? ResourceStatus.myBooking 
              : ResourceStatus.booked;
        } 
        else if (resourceId.startsWith('room_')) {
          // Extract floor and room number
          List<String> parts = resourceId.split('_');
          String roomId = 'room_${parts[1]}_${parts[2]}';
          
          // Check time range for partial availability
          if (data.containsKey('start_time') && data.containsKey('end_time')) {
            // For simplicity, we'll mark rooms as either booked or my booking
            // A more sophisticated implementation would check for overlapping time slots
            roomStatuses[roomId] = isMyBooking 
                ? ResourceStatus.myBooking 
                : ResourceStatus.booked;
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

  Widget _buildDeskMap() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Container(
                width: 800,
                height: 600,
                padding: EdgeInsets.all(16),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: DeskMapPainter(selectedFloor, deskStatuses),
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
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Container(
                width: 800,
                height: 600,
                padding: EdgeInsets.all(16),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MeetingRoomMapPainter(selectedFloor, roomStatuses),
                    child: Container(),
                  ),
                ),
              ),
            ),
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
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(widget.selectedDate ?? DateTime.now())}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
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
                  _buildLegendItem('Partially available', Colors.orange),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ],
    );
  }
}

class DeskMapPainter extends CustomPainter {
  final String floor;
  final Map<String, ResourceStatus> deskStatuses;
  
  DeskMapPainter(this.floor, this.deskStatuses);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    int numTables = floor == '1st' ? 3 : 2;
    
    // Calculate total height needed for all tables
    double tableHeight = 120; // Height of table plus chairs
    double totalHeight = tableHeight * numTables + (numTables - 1) * 60; // Including gaps
    
    // Calculate starting Y position to center vertically
    double startY = (size.height - totalHeight) / 2;
    
    // Position tables more towards left, centered around x=200
    double centerX = 200;
    double tableWidth = 160;
    double startX = centerX - (tableWidth / 2);

    // Counter for desk numbering
    int deskCounter = 1;

    for (int i = 0; i < numTables; i++) {
      double yOffset = startY + (i * (tableHeight + 60));
      
      // Draw desk
      canvas.drawRect(
        Rect.fromLTWH(startX, yOffset + 15, tableWidth, 40),
        paint
      );

      // Draw 3 chairs on top with status colors
      for (int j = 0; j < 3; j++) {
        String deskId = 'desk_${floor}_$deskCounter';
        ResourceStatus status = deskStatuses[deskId] ?? ResourceStatus.available;
        
        _drawChair(
          canvas,
          startX + 30 + (j * 50),
          yOffset,
          deskCounter,
          status
        );
        
        deskCounter++;
      }

      // Draw 3 chairs on bottom with status colors
      for (int j = 0; j < 3; j++) {
        String deskId = 'desk_${floor}_$deskCounter';
        ResourceStatus status = deskStatuses[deskId] ?? ResourceStatus.available;
        
        _drawChair(
          canvas,
          startX + 30 + (j * 50),
          yOffset + 70,
          deskCounter,
          status
        );
        
        deskCounter++;
      }
    }
  }

  void _drawChair(Canvas canvas, double x, double y, int deskNumber, ResourceStatus status) {
    // Choose color based on status
    Color statusColor;
    switch (status) {
      case ResourceStatus.available:
        statusColor = Colors.green;
        break;
      case ResourceStatus.booked:
        statusColor = Colors.red;
        break;
      case ResourceStatus.partiallyAvailable:
        statusColor = Colors.orange;
        break;
      case ResourceStatus.myBooking:
        statusColor = Colors.blue;
        break;
    }
    
    // Draw circle with status color
    final fillPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw filled circle
    canvas.drawCircle(Offset(x, y), 12, fillPaint);
    
    // Draw border
    canvas.drawCircle(Offset(x, y), 12, borderPaint);
    
    // Draw desk number
    final textPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Draw number directly on canvas without TextPainter
    // This avoids the TextDirection issues
    final String numberText = deskNumber.toString();
    
    // For simplicity, we'll draw a simple number
    // In a production app, use a simpler approach to draw text
    // or create a custom number drawing function
    final textX = x - 4; // Simple centering approach
    final textY = y - 6;
    
    // For single digit numbers (1-9)
    if (numberText.length == 1) {
      canvas.drawCircle(Offset(x, y), 9, fillPaint);
      
      // Draw a bold "+" as a substitute for numbers to avoid text issues
      final numberPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      // Draw horizontal line for "+"
      canvas.drawLine(
        Offset(x - 4, y),
        Offset(x + 4, y),
        numberPaint
      );
      
      // Draw vertical line for "+"
      canvas.drawLine(
        Offset(x, y - 4),
        Offset(x, y + 4),
        numberPaint
      );
    } 
    // For double digit numbers (10+)
    else {
      canvas.drawCircle(Offset(x, y), 9, fillPaint);
      
      // Draw a simple asterisk "*" shape for double digits
      final numberPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      // Draw X shape
      canvas.drawLine(
        Offset(x - 4, y - 4),
        Offset(x + 4, y + 4),
        numberPaint
      );
      
      canvas.drawLine(
        Offset(x - 4, y + 4),
        Offset(x + 4, y - 4),
        numberPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MeetingRoomMapPainter extends CustomPainter {
  final String floor;
  final Map<String, ResourceStatus> roomStatuses;
  
  MeetingRoomMapPainter(this.floor, this.roomStatuses);

  @override
  void paint(Canvas canvas, Size size) {
    for (int row = 0; row < 3; row++) {
      double yOffset = row * 200.0;
      
      for (int col = 0; col < 2; col++) {
        double xOffset = col * 250.0;
        
        // Calculate room number based on floor
        int baseNumber = floor == '1st' ? 1 : 6;
        int roomNumber = baseNumber + (row * 2) + col;
        
        // Alternate between 4 and 6 seats
        bool isLargeRoom = roomNumber % 2 == 0;
        
        // Get status for this room
        String roomId = 'room_${floor}_$roomNumber';
        ResourceStatus status = roomStatuses[roomId] ?? ResourceStatus.available;
        
        _drawMeetingRoom(
          canvas,
          30 + xOffset,
          50 + yOffset,
          'Room #$roomNumber',
          isLargeRoom,
          status,
          roomNumber
        );
      }
    }
  }

  void _drawMeetingRoom(Canvas canvas, double x, double y, String label, bool isLargeRoom, ResourceStatus status, int roomNumber) {
    // Choose color based on status
    Color statusColor;
    switch (status) {
      case ResourceStatus.available:
        statusColor = Colors.green.withOpacity(0.3);
        break;
      case ResourceStatus.booked:
        statusColor = Colors.red.withOpacity(0.3);
        break;
      case ResourceStatus.partiallyAvailable:
        statusColor = Colors.orange.withOpacity(0.3);
        break;
      case ResourceStatus.myBooking:
        statusColor = Colors.blue.withOpacity(0.3);
        break;
    }
    
    final roomPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw room with status color
    canvas.drawRect(Rect.fromLTWH(x, y, 180, 120), roomPaint);
    
    // Draw border
    canvas.drawRect(Rect.fromLTWH(x, y, 180, 120), borderPaint);

    if (isLargeRoom) {
      // Draw 6 chairs (3 on each side)
      _drawChair(canvas, x + 45, y + 30);
      _drawChair(canvas, x + 45, y + 60);
      _drawChair(canvas, x + 45, y + 90);
      _drawChair(canvas, x + 135, y + 30);
      _drawChair(canvas, x + 135, y + 60);
      _drawChair(canvas, x + 135, y + 90);
    } else {
      // Draw 4 chairs (2 on each side)
      _drawChair(canvas, x + 45, y + 40);
      _drawChair(canvas, x + 45, y + 80);
      _drawChair(canvas, x + 135, y + 40);
      _drawChair(canvas, x + 135, y + 80);
    }

    // Draw room number text in the center of the room
    final labelPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
      
    final textX = x + 90; // Center of room
    final textY = y + 60; // Center of room
    
    // Draw a simple label without TextPainter
    final roomLabelPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    // Draw a simple border line below to indicate "this is Room X"
    canvas.drawLine(
      Offset(x + 60, y + 130),
      Offset(x + 120, y + 130),
      roomLabelPaint
    );
    
    // Draw capacity indicator
    final capacityText = 'Max: ${isLargeRoom ? 6 : 4}';
    final capacityY = y + 150;
    
    // Add a capacity marker
    canvas.drawCircle(
      Offset(x + 90, capacityY - 5),
      3,
      roomLabelPaint
    );
  }

  void _drawChair(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(x, y), 12, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}