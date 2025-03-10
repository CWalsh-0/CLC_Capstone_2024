import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FloorPlanModel extends StatefulWidget {
  @override
  _FloorPlanModelState createState() => _FloorPlanModelState();
}

class _FloorPlanModelState extends State<FloorPlanModel> {
  String selectedFloor = '1st';
  int currentIndex = 0;

  Widget _buildDeskMap() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          width: 800,
          height: 600,
          padding: EdgeInsets.all(16),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: DeskMapPainter(selectedFloor),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingRoomMap() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          width: 800,
          height: 600,
          padding: EdgeInsets.all(16),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: MeetingRoomMapPainter(selectedFloor),
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
      child: Container(
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
  DeskMapPainter(this.floor);

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

    for (int i = 0; i < numTables; i++) {
      double yOffset = startY + (i * (tableHeight + 60));
      
      // Draw desk
      canvas.drawRect(
        Rect.fromLTWH(startX, yOffset + 15, tableWidth, 40),
        paint
      );

      // Draw 3 chairs on top
      for (int j = 0; j < 3; j++) {
        _drawChair(
          canvas,
          startX + 30 + (j * 50),
          yOffset
        );
      }

      // Draw 3 chairs on bottom
      for (int j = 0; j < 3; j++) {
        _drawChair(
          canvas,
          startX + 30 + (j * 50),
          yOffset + 70
        );
      }
    }
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

class MeetingRoomMapPainter extends CustomPainter {
  final String floor;
  MeetingRoomMapPainter(this.floor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    for (int row = 0; row < 3; row++) {
      double yOffset = row * 200.0;
      
      for (int col = 0; col < 2; col++) {
        double xOffset = col * 250.0;
        
        // Calculate room number based on floor
        int baseNumber = floor == '1st' ? 1 : 6;
        int roomNumber = baseNumber + (row * 2) + col;
        
        // Alternate between 4 and 6 seats
        bool isLargeRoom = roomNumber % 2 == 0;
        
        _drawMeetingRoom(
          canvas,
          30 + xOffset,
          50 + yOffset,
          'Meeting room #$roomNumber\nMax: ${isLargeRoom ? 6 : 4}',
          isLargeRoom
        );
      }
    }
  }

  void _drawMeetingRoom(Canvas canvas, double x, double y, String label, bool isLargeRoom) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Draw room
    canvas.drawRect(Rect.fromLTWH(x, y, 180, 120), paint);

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

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 12, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y + 130));
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