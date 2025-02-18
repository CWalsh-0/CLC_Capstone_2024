import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new booking
  Future<void> createBooking({
    required String roomId,
    required DateTime dateBooked,
    required String timeSlot,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Start a batch write
    final batch = _firestore.batch();

    // 1. Update the spaces collection for RFID
    final roomRef = _firestore.collection('spaces').doc(roomId);
    batch.set(roomRef, {
      'date_booked': Timestamp.fromDate(dateBooked),
      'user_id': user.uid,
      'status': 'approved',
      'timeout': "60"
    });

    // 2. Create a new document in bookings collection
    final bookingRef = _firestore.collection('bookings').doc();
    batch.set(bookingRef, {
      'user_id': user.uid,
      'resource_id': roomId,
      'date_booked': Timestamp.fromDate(dateBooked),
      'booking_status': 'approved',
      'time_slot': timeSlot,
      'timeout': "60",
      'type': 'room',
      'karma_points': 1200,
      'timestamp': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();
  }

  Future<void> createDeskBooking({
    required String deskId,
    required DateTime dateBooked,
    required String timeSlot,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Start a batch write
    final batch = _firestore.batch();

    // 1. Update the spaces collection for RFID
    final deskRef = _firestore.collection('spaces').doc(deskId);
    batch.set(deskRef, {
      'date_booked': Timestamp.fromDate(dateBooked),
      'user_id': user.uid,
      'status': 'approved',
      'timeout': "60"
    });

    // 2. Create a new document in bookings collection
    final bookingRef = _firestore.collection('bookings').doc();
    batch.set(bookingRef, {
      'user_id': user.uid,
      'resource_id': deskId,
      'date_booked': Timestamp.fromDate(dateBooked),
      'booking_status': 'approved',
      'time_slot': timeSlot,
      'timeout': "60",
      'type': 'desk',
      'karma_points': 1200,
      'timestamp': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('Booking not found');

    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    final resourceId = bookingData['resource_id'] as String;

    // Start a batch write
    final batch = _firestore.batch();

    // 1. Update booking status
    batch.update(_firestore.collection('bookings').doc(bookingId), {
      'booking_status': 'cancelled',
      'cancelled_at': FieldValue.serverTimestamp(),
    });

    // 2. Update the space's status
    final spaceDoc = await _firestore.collection('spaces').doc(resourceId).get();
    if (spaceDoc.exists) {
      final spaceData = spaceDoc.data() as Map<String, dynamic>;
      final spaceUserId = spaceData['user_id'];
      final spaceDateBooked = spaceData['date_booked'] as Timestamp;
      
      if (spaceUserId == bookingData['user_id'] && 
          spaceDateBooked.toDate().isAtSameMomentAs(bookingData['date_booked'].toDate())) {
        batch.update(_firestore.collection('spaces').doc(resourceId), {
          'status': 'cancelled',
        });
      }
    }

    // Commit the batch
    await batch.commit();
  }

  // Get user's bookings
  Stream<List<BookingData>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('date_booked', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return BookingData(
              id: doc.id,
              dateBooked: (data['date_booked'] as Timestamp).toDate(),
              userId: data['user_id'],
              rfidStatus: data['booking_status'] ?? '',
              bookingStatus: data['booking_status'],
              timeSlot: data['time_slot'],
              timeout: int.parse(data['timeout']),
              roomId: data['resource_id'],
            );
          }).toList();
        });
  }

  // Check if a room is available
  Future<bool> isRoomAvailable(String roomId, DateTime date, String timeSlot) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final bookingsQuery = await _firestore
        .collection('bookings')
        .where('resource_id', isEqualTo: roomId)
        .where('date_booked', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date_booked', isLessThan: Timestamp.fromDate(endOfDay))
        .where('booking_status', isEqualTo: 'approved')
        .get();

    for (var doc in bookingsQuery.docs) {
      final data = doc.data();
      final existingTimeSlot = data['time_slot'] as String;
      
      if (existingTimeSlot == 'Full day' || timeSlot == 'Full day') {
        return false;
      }
      
      if (existingTimeSlot == timeSlot) {
        return false;
      }
    }

    return true;
  }

  Future<bool> isDeskAvailable(String deskId, DateTime date, String timeSlot) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final bookingsQuery = await _firestore
        .collection('bookings')
        .where('resource_id', isEqualTo: deskId)
        .where('date_booked', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date_booked', isLessThan: Timestamp.fromDate(endOfDay))
        .where('booking_status', isEqualTo: 'approved')
        .get();

    for (var doc in bookingsQuery.docs) {
      final data = doc.data();
      final existingTimeSlot = data['time_slot'] as String;
      
      if (existingTimeSlot == 'Full day' || timeSlot == 'Full day') {
        return false;
      }
      
      if (existingTimeSlot == timeSlot) {
        return false;
      }
    }

    return true;
  }
}

class BookingData {
  final String id;
  final DateTime dateBooked;
  final String userId;
  final String rfidStatus;
  final String bookingStatus;
  final String timeSlot;
  final int timeout;
  final String roomId;

  BookingData({
    required this.id,
    required this.dateBooked,
    required this.userId,
    required this.rfidStatus,
    required this.bookingStatus,
    required this.timeSlot,
    required this.timeout,
    required this.roomId,
  });
}