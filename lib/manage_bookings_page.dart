import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageBookingPage extends StatefulWidget {
  const ManageBookingPage({super.key});

  @override
  State<ManageBookingPage> createState() => _ManageBookingPageState();
}

Map<String, dynamic>? selectedBookingData;

class _ManageBookingPageState extends State<ManageBookingPage> {
  String? selectedBookingId;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Manage Bookings',
          style: TextStyle(
            color: Colors.blue,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('user_id', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No bookings found.'));
            }

            // list of bookings for the user
            var bookings = snapshot.data!.docs;

            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                var booking = bookings[index];
                var bookingData = booking.data() as Map<String, dynamic>;
                String bookingId = booking.id;

                return Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedBookingId == bookingId
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Room: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${bookingData['resource_id']}'),
                          SizedBox(width: 15),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Booking Type: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('${bookingData['booking_type']}'),
                              SizedBox(width: 10),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Booking Status: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('${bookingData['status']}'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Time Booked: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('${bookingData['time']}'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Duration: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('${bookingData['timeout']}'),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          // toggle selection of the booking
                          if (selectedBookingId == bookingId) {
                            selectedBookingId =
                                null; // deselect if already selected
                            selectedBookingData = null;
                          } else {
                            selectedBookingId = bookingId;
                            selectedBookingData = bookingData;
                          }
                        });
                      },
                      trailing: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 150),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              //make sure the booking is done before being able to edit
                              onPressed: (selectedBookingData != null &&
                                      selectedBookingData!['status'] ==
                                          'approved')
                                  ? () {
                                      print(
                                          "Editing: ${selectedBookingData!['resource_id']}");
                                      _openEditDialog(context, bookingId);
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    context, bookingId);
                              },
                            ),
                          ],
                        ),
                      ),
                    ));
              },
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this booking?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // call the function to delete the booking
                _deleteBooking(bookingId);
                _resetRoom(bookingId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteBooking(String bookingId) {
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .delete()
        .then((_) {
      print("Booking $bookingId deleted successfully.");
    }).catchError((error) {
      print("Error deleting booking: $error");
    });
  }
}

void _resetRoom(String bookingId) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('spaces')
        .doc("hotdesks")
        .collection("hotdesk_bookings")
        .where("booking_id", isEqualTo: bookingId)
        .get();

    for (var doc in querySnapshot.docs) {
      // we should probably keep the rooms and not generate them
      //await doc.reference.delete();
      await doc.reference.update({
        "date_booked": FieldValue.serverTimestamp(), // not an elegant reset
        "is_booked": "false",
        "user_id": "empty",
        "time": "",
        "status": "empty",
        "timeout": 0,
        "booking_id": "empty"
      });
      print("Space $bookingId reset successfully.");
    }
  } catch (e) {
    print("Error deleting booking: $e");
  }
}

void _showEditDialog(
    BuildContext context, String bookingId, Map<String, dynamic> bookingData) {
  TextEditingController timeoutController =
      TextEditingController(text: bookingData['timeout'].toString());
  TextEditingController statusController =
      TextEditingController(text: bookingData['status']);

  // Dropdown options for time slots
  final List<String> dateTimeTypes = ['Allday', 'Morning', 'Afternoon'];
  String selectedTime = bookingData['time']; // Default to existing time

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Edit Booking"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Time Booked",
                  border: OutlineInputBorder(),
                ),
                value: selectedTime,
                items: dateTimeTypes.map((String time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (newValue) {
                  selectedTime = newValue!; // update selected time
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: timeoutController,
                decoration: InputDecoration(labelText: "Duration (mins)"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: statusController,
                decoration: InputDecoration(labelText: "Status"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('spaces')
                  .doc("hotdesks")
                  .collection("hotdesk_bookings")
                  .doc(selectedBookingData?["resource_id"])
                  .update({
                "time": selectedTime,
                "timeout": int.parse(timeoutController.text),
                "status": statusController.text,
              });

              Navigator.of(context).pop();
              print("Booking $bookingId updated successfully!");
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
}

void _openEditDialog(BuildContext context, String bookingId) async {
  String roomId = selectedBookingData?["resource_id"];
  print(roomId);
  try {
    DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection("spaces")
        .doc("hotdesks")
        .collection("hotdesk_bookings")
        .doc(roomId)
        .get();

    if (bookingSnapshot.exists) {
      Map<String, dynamic> bookingData =
          bookingSnapshot.data() as Map<String, dynamic>;

      // ignore: use_build_context_synchronously
      _showEditDialog(context, bookingId, bookingData);
    } else {
      print("Booking not found.");
    }
  } catch (e) {
    print("Error fetching booking: $e");
  }
}
