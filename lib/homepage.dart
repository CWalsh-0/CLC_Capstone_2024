import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

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

  // Generate time slots from 8 AM to 6 PM
  final List<String> timeSlots = List.generate(11, (index) {
    int hour = index + 8;
    return '${hour.toString().padLeft(2, '0')}:00';
  });

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
                      // Logo and App Name
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
                              title: Text(
                                'Profile',
                                style: GoogleFonts.poppins(),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => context.push('/profile'),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.settings, color: Color(0xFF1A47B8)),
                              title: Text(
                                'Settings',
                                style: GoogleFonts.poppins(),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => context.push('/settings'),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.logout, color: Color(0xFF1A47B8)),
                              title: Text(
                                'Logout',
                                style: GoogleFonts.poppins(),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () async {
                              await _handleLogout(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar Section
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
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                          ),
                          availableCalendarFormats: const {
                            CalendarFormat.week: 'Week'
                          },
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time slots column
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
                                  // Calendar grid
                                  Expanded(
                                    child: Column(
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

                // Booking Buttons Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // New Booking Button
                        SizedBox(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () => context.push('/new-booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A47B8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'New Booking',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Manage Bookings Button
                        SizedBox(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () => context.push('/manage-bookings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A47B8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Manage your Bookings',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Map Icon
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
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    // Header with close button
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Floors Plan',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(),
                                    // Placeholder for floor plan
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Floor Plan Display\n(Coming Soon)',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}