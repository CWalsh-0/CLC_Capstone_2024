import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterdb/firestore/booking_service.dart';


class ManageBookingPage extends StatefulWidget {
  const ManageBookingPage({super.key});

  @override
  State<ManageBookingPage> createState() => _ManageBookingPageState();
}

class _ManageBookingPageState extends State<ManageBookingPage> {
  final BookingService _bookingService = BookingService();
  Map<String, bool> selectedBookings = {};

  Color _getStatusColor(String bookingStatus) {
    switch (bookingStatus.toLowerCase()) {
      case 'booked':
        return Colors.red;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = selectedBookings.values.where((selected) => selected).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    'My Bookings',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A47B8),
                    ),
                  ),
                ],
              ),
            ),

            // Booking Table
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<List<BookingData>>(
                  stream: _bookingService.getUserBookings(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bookings = snapshot.data!;
                    
                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          'No bookings found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Table(
                          border: TableBorder.all(color: Colors.black),
                          columnWidths: const {
                            0: FlexColumnWidth(0.7),  // Checkbox column
                            1: FlexColumnWidth(2.5),  // Date column
                            2: FlexColumnWidth(2),    // Room column
                            3: FlexColumnWidth(2),    // Time column
                            4: FlexColumnWidth(2),    // Status column
                          },
                          children: [
                            _buildTableRow(['', 'Date', 'Room', 'Time Slot', 'Status'], isHeader: true),
                            ...bookings.map((booking) => _buildSelectableRow(
                              booking.id,
                              booking.dateBooked.toString().split(' ')[0],
                              booking.roomId,
                              booking.timeSlot,
                              booking.bookingStatus,
                            )),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: selectedCount == 1 ? () => _handleEdit(bookings) : null,
                              child: const Text('Edit'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: selectedCount > 0 ? () => _handleCancel(bookings) : null,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell,
            style: GoogleFonts.poppins(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  TableRow _buildSelectableRow(String id, String date, String type, String time, String status) {
    return TableRow(
      children: [
        Center(
          child: Checkbox(
            value: selectedBookings[id] ?? false,
            onChanged: (bool? value) {
              setState(() {
                selectedBookings[id] = value ?? false;
              });
            },
          ),
        ),
        _buildTableCell(date),
        _buildTableCell(type),
        _buildTableCell(time),
        _buildTableCell(
          status,
          color: _getStatusColor(status),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _handleEdit(List<BookingData> bookings) {
    final selectedBooking = bookings.firstWhere(
      (booking) => selectedBookings[booking.id] == true
    );
    // Navigate to edit page or show edit dialog
    print('Editing booking: ${selectedBooking.id}');
  }

  void _handleCancel(List<BookingData> bookings) async {
    try {
      final selectedIds = selectedBookings.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      for (String id in selectedIds) {
        await _bookingService.cancelBooking(id);
      }

      setState(() {
        selectedBookings.clear();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookings cancelled successfully')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling bookings: $e')),
        );
      }
    }
  }
}