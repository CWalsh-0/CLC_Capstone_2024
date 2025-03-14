import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'FloorPlanModel.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _userBookings = [];

  final List<String> timeSlots = List.generate(11, (index) {
    int hour = index + 8;
    return '${hour.toString().padLeft(2, '0')}:00';
  });

  // Convert a time string (HH:MM) to a number of minutes since midnight
  int _timeToMinutes(String timeStr) {
    try {
      List<String> parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }
  
  // Adjust the time string to ensure it uses exactly the hours displayed in the calendar
  String _adjustTimeToCalendarGrid(String timeStr) {
    int minutes = _timeToMinutes(timeStr);
    int roundedMinutes = ((minutes + 15) ~/ 30) * 30;
    int hours = roundedMinutes ~/ 60;
    int mins = roundedMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserBookings();
  }
  
  Future<void> _loadUserBookings() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay ?? DateTime.now());
      
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .where('date', isEqualTo: formattedDate)
          .get();
      
      List<Map<String, dynamic>> bookings = [];
      
      for (var doc in bookingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        if (data['booking_type'] != null && 
            (data['booking_type'] as String).toLowerCase().contains('hotdesk')) {
          String timeSlot = data['time'] as String? ?? 'Morning';
          Map<String, String> timeRange = _getTimeRangeForSlot(timeSlot);
          
          String startTime = timeRange['start']!;
          String endTime = timeRange['end']!;
          String adjustedStartTime = _adjustTimeToCalendarGrid(startTime);
          String adjustedEndTime = _adjustTimeToCalendarGrid(endTime);
          
          data['start_datetime'] = _parseTimeString(formattedDate, startTime);
          data['end_datetime'] = _parseTimeString(formattedDate, endTime);
          data['start_time'] = startTime;
          data['end_time'] = endTime;
          data['start_hour_index'] = _getHourIndex(adjustedStartTime);
          data['end_hour_index'] = _getHourIndex(adjustedEndTime);
        } else {
          String startTime = data['start_time'] as String? ?? '09:00';
          String endTime = data['end_time'] as String? ?? '10:00';
          String adjustedStartTime = _adjustTimeToCalendarGrid(startTime);
          String adjustedEndTime = _adjustTimeToCalendarGrid(endTime);
          
          data['start_datetime'] = _parseTimeString(formattedDate, startTime);
          data['end_datetime'] = _parseTimeString(formattedDate, endTime);
          data['start_time'] = startTime;
          data['end_time'] = endTime;
          data['start_hour_index'] = _getHourIndex(adjustedStartTime);
          data['end_hour_index'] = _getHourIndex(adjustedEndTime);
        }
        
        bookings.add(data);
      }
      
      setState(() {
        _userBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user bookings: $e');
      setState(() => _isLoading = false);
    }
  }
  
  DateTime _parseTimeString(String dateStr, String timeStr) {
    if (timeStr.split(':').length < 3) {
      timeStr = '$timeStr:00';
    }
    return DateTime.parse('$dateStr $timeStr');
  }
  
  double _getHourIndex(String timeStr) {
    try {
      List<String> parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      double index = (hour - 8) + (minute / 60.0);
      return index;
    } catch (e) {
      print('Error parsing time: $timeStr - $e');
      return 0.0;
    }
  }
  
  Map<String, String> _getTimeRangeForSlot(String timeSlot) {
    switch (timeSlot) {
      case 'Morning':
        return {'start': '09:00', 'end': '13:00'};
      case 'Afternoon':
        return {'start': '13:00', 'end': '17:00'};
      case 'All Day':
      case 'Allday':
        return {'start': '09:00', 'end': '17:00'};
      default:
        return {'start': '09:00', 'end': '17:00'};
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/sign-in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to log out. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error during logout: $e');
    }
  }
  
  Color _getBookingColor(String? bookingType) {
    if (bookingType == null) return const Color(0xFFFF9800);
    if (bookingType.toLowerCase().contains('hotdesk')) {
      return const Color(0xFF4CAF50);
    } else if (bookingType.toLowerCase().contains('conference')) {
      return const Color(0xFF2196F3);
    }
    return const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/flexidesk_logo.png',
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(width: 15),
                          Padding(
                            padding: const EdgeInsets.only(top: 75),
                            child: Center(
                              child: Text(
                                'FlexiDesk',
                                style: GoogleFonts.allura(
                                  fontSize: 40,
                                  color: const Color(0xFF1A47B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.settings, color: Colors.grey[600]),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        offset: const Offset(0, 40),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Color(0xFF1A47B8)),
                              title: Text('Profile', style: GoogleFonts.poppins()),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => context.push('/profile'),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.settings, color: Color(0xFF1A47B8)),
                              title: Text('Settings', style: GoogleFonts.poppins()),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => context.push('/settings'),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.logout, color: Color(0xFF1A47B8)),
                              title: Text('Logout', style: GoogleFonts.poppins()),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () async => await _handleLogout(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'CALENDAR',
                            style: GoogleFonts.baloo2(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        TableCalendar(
                          firstDay: DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _loadUserBookings();
                          },
                          calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                          availableCalendarFormats: const {CalendarFormat.week: 'Week'},
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          headerStyle: const HeaderStyle(formatButtonVisible: false),
                        ),
                        Expanded(
                          child: _isLoading 
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Column(
                                            children: timeSlots.map((time) => Container(
                                              height: 60,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              alignment: Alignment.center,
                                              child: Text(
                                                time,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )).toList(),
                                          ),
                                        ),
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Column(
                                                children: timeSlots.map((time) => Container(
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: List.generate(5, (index) => Expanded(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey[300]!),
                                                          ),
                                                        ),
                                                      ),
                                                    )),
                                                  ),
                                                )).toList(),
                                              ),
                                              for (var booking in _userBookings)
                                                _buildContinuousBookingBlock(booking),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () => context.push('/new-booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A47B8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('New Booking', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () => context.push('/manage-bookings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A47B8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Manage your Bookings', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () => context.push('/algorithm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A47B8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Demo Booking', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: Icon(Icons.map_outlined, size: 30, color: Colors.grey[600]),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return FloorPlanModel(
                              selectedDate: _selectedDay ?? DateTime.now(),
                              userId: FirebaseAuth.instance.currentUser?.uid,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContinuousBookingBlock(Map<String, dynamic> booking) {
    Color blockColor = _getBookingColor(booking['booking_type'] as String?);
    String resourceName = booking['resource_id'] as String? ?? 'Resource';
    bool isHotdesk = booking['booking_type'] != null && 
                    (booking['booking_type'] as String).toLowerCase().contains('hotdesk');
    IconData bookingIcon = isHotdesk ? Icons.desktop_windows : Icons.meeting_room;
    
    double startIndex = booking['start_hour_index'] as double? ?? 0;
    double endIndex = booking['end_hour_index'] as double? ?? (startIndex + 1);
    
    if ((endIndex - endIndex.floor()).abs() < 0.05) endIndex = endIndex.floor().toDouble();
    if ((startIndex - startIndex.floor()).abs() < 0.05) startIndex = startIndex.floor().toDouble();
    
    double top = startIndex * 60.0;
    double height = (endIndex - startIndex) * 60.0;
    
    // Increase minimum height to better accommodate content
    if (height < 48) height = 48; // Adjusted from 40 to 48 to fit content
    
    String timeText = _getTimeDisplayText(booking);
    
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: blockColor.withOpacity(0.2),
          border: Border.all(color: blockColor, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _showBookingDetails(booking),
            child: Padding(
              padding: const EdgeInsets.all(4.0), // Reduced padding to save space
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Ensure the Column doesn't expand unnecessarily
                children: [
                  Row(
                    children: [
                      Icon(bookingIcon, size: 14, color: blockColor), // Reduced icon size
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          resourceName,
                          style: TextStyle(
                            fontSize: 11, // Reduced font size
                            fontWeight: FontWeight.w500,
                            color: blockColor.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Only show time text if the block is tall enough
                  if (timeText.isNotEmpty && height >= 60) // Adjusted threshold
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 18.0), // Reduced padding
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 9, // Reduced font size
                          color: blockColor.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _getTimeDisplayText(Map<String, dynamic> booking) {
    if (booking['booking_type'] != null && 
        (booking['booking_type'] as String).toLowerCase().contains('hotdesk')) {
      String timeSlot = booking['time'] as String? ?? '';
      String startTime = _getTimeRangeForSlot(timeSlot)['start'] ?? '';
      String endTime = _getTimeRangeForSlot(timeSlot)['end'] ?? '';
      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        return '$timeSlot ($startTime-$endTime)';
      }
      return timeSlot;
    } else {
      String startTime = booking['start_time'] as String? ?? '';
      String endTime = booking['end_time'] as String? ?? '';
      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        return '$startTime - $endTime';
      }
    }
    return '';
  }
  
  void _showBookingDetails(Map<String, dynamic> booking) {
    String formattedDate = booking['date'] as String? ?? '';
    String startTime = '';
    String endTime = '';
    
    if (booking['booking_type'] != null &&
        (booking['booking_type'] as String).toLowerCase().contains('hotdesk')) {
      startTime = booking['time'] as String? ?? '';
      endTime = '';
    } else {
      startTime = booking['start_time'] as String? ?? '';
      endTime = booking['end_time'] as String? ?? '';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Booking Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A47B8),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Resource:', booking['resource_id'] as String? ?? ''),
              _buildDetailRow('Type:', booking['booking_type'] as String? ?? ''),
              _buildDetailRow('Date:', formattedDate),
              if (startTime.isNotEmpty && endTime.isNotEmpty) ...[
                _buildDetailRow('Start Time:', startTime),
                _buildDetailRow('End Time:', endTime),
              ] else if (startTime.isNotEmpty) ...[
                _buildDetailRow('Time:', startTime),
              ],
              _buildDetailRow('Status:', booking['status'] as String? ?? ''),
              _buildDetailRow('Duration:', '${booking['timeout'] ?? 0} minutes'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFF1A47B8))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/manage-bookings');
              },
              child: Text('Manage', style: GoogleFonts.poppins(color: const Color(0xFF1A47B8))),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}