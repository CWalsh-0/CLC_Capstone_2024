import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageBookingPage extends StatefulWidget {
  const ManageBookingPage({super.key});

  @override
  State<ManageBookingPage> createState() => _ManageBookingPageState();
}

class _ManageBookingPageState extends State<ManageBookingPage> {
  List<bool> selectedBookings = [false, false, false];

  @override
  Widget build(BuildContext context) {
    int selectedCount = selectedBookings.where((selected) => selected).length;

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
                    'Manage Booking',
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
                child: Column(
                  children: [
                    Table(
                      border: TableBorder.all(color: Colors.black),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(3),
                      },
                      children: [
                        _buildTableRow(['', 'Date', 'Booking Type', 'Time'], isHeader: true),
                        _buildSelectableRow(0, 'Nov 11', 'Desk 12', 'Full day'),
                        _buildSelectableRow(1, 'Nov 11', 'Meeting Room 2', '1pm to 3pm'),
                        _buildSelectableRow(2, 'Nov 11', 'Desk 5', 'Afternoon'),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: selectedCount == 1 ? () {} : null,
                          child: const Text('Edit'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedCount > 0 ? () {} : null,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                  ],
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

  TableRow _buildSelectableRow(int index, String date, String type, String time) {
    return TableRow(
      children: [
        Center(
          child: Checkbox(
            value: selectedBookings[index],
            onChanged: (bool? value) {
              setState(() {
                selectedBookings[index] = value ?? false;
              });
            },
          ),
        ),
        _buildTableCell(date),
        _buildTableCell(type),
        _buildTableCell(time),
      ],
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(),
        textAlign: TextAlign.center,
      ),
    );
  }
}
