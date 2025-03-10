from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import List, Dict, Optional, Set, Tuple
from collections import defaultdict
import heapq
import uuid
import random



class ResourceType(Enum):
    DESK = "desk"
    ROOM = "room"

class TimeSlot(Enum):
    FULL_DAY = "full_day"    # 9:00 - 17:00
    MORNING = "morning"      # 9:00 - 12:00
    AFTERNOON = "afternoon"  # 12:00 - 17:00

class BookingStatus(Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    MISSED = "missed"
    COMPLETED = "completed"

@dataclass
class User:
    id: str
    name: str
    email: str
    karma_points: int = 1000
    
    def deduct_karma(self, points: int):
        self.karma_points = max(0, self.karma_points - points)

@dataclass
class Resource:
    id: str
    type: ResourceType
    location: str
    desk_family: Optional[str] = None

@dataclass
class Booking:
    id: str
    user: User
    resource: Resource
    start_time: datetime
    end_time: datetime
    status: BookingStatus
    created_at: datetime
    check_in_deadline: datetime
    coworkers: List[User] = None

class BookingSystem:
    def __init__(self):
        self.resources: Dict[str, Resource] = {}
        self.users: Dict[str, User] = {}
        self.bookings: Dict[str, Booking] = {}
        self.request_queue: List[str] = []  # FIFO queue of booking IDs
        self.desk_waiting_list: List[Tuple[int, datetime, str]] = []  # (karma, timestamp, booking_id)
        self.room_waiting_lists: Dict[str, List[Tuple[int, datetime, str]]] = defaultdict(list)  # room_id -> [(karma, timestamp, booking_id)]

    def clear_room_bookings(self, room_id: str = None):
        """Clear all bookings for a specific room"""
        if room_id is None:
            return
        to_remove = [k for k,v in self.bookings.items() if v.resource.id == room_id]
        for booking_id in to_remove:
            self.remove_booking(booking_id)

    def clear_all_room_bookings(self):
        self.bookings = {k:v for k,v in self.bookings.items() if v.resource.type != ResourceType.ROOM}  

    def clear_desk_bookings(self, desk_id: str = None):
        """Clear all bookings for a specific desk"""
        self.bookings = {k:v for k,v in self.bookings.items() if v.resource.id != desk_id}

    def clear_all_desk_bookings(self):
        self.bookings = {k:v for k,v in self.bookings.items() if v.resource.type != ResourceType.DESK}

    def remove_booking(self, booking_id: str):
        """Remove a specific booking by ID from all data structures"""
        if booking_id in self.bookings:
            del self.bookings[booking_id]

        # Remove from request queue if present
        if booking_id in self.request_queue:
            self.request_queue.remove(booking_id)

        #Remove from desk waiting list if present
        self.desk_waiting_list = [x for x in self.desk_waiting_list if x[2] != booking_id]
        heapq.heapify(self.desk_waiting_list)

        #Remove from room waiting lists if present
        for room_id in self.room_waiting_lists:
            self.room_waiting_lists[room_id] = [x for x in self.room_waiting_lists[room_id] if x[2] != booking_id]
            heapq.heapify(self.room_waiting_lists[room_id])


    def get_time_slot_range(self, slot: TimeSlot, date: datetime) -> Tuple[datetime, datetime]:
        base_date = datetime.combine(date.date(), datetime.min.time().replace(hour=9))
        
        if slot == TimeSlot.FULL_DAY:
            return (base_date, base_date + timedelta(hours=8))
        elif slot == TimeSlot.MORNING:
            return (base_date, base_date + timedelta(hours=3))
        elif slot == TimeSlot.AFTERNOON:
            return (base_date + timedelta(hours=3), base_date + timedelta(hours=8))
        else:
            raise ValueError(f"Invalid time slot: {slot}")

    def add_resource(self, resource: Resource):
        self.resources[resource.id] = resource
        
    def add_user(self, user: User):
        self.users[user.id] = user

    def add_to_request_queue(self, booking_id: str):
        """Add booking request to FIFO queue"""
        self.request_queue.append(booking_id)

    def add_to_waiting_list(self, booking_id: str):
        """Add to appropriate waiting list based on resource type"""
        booking = self.bookings[booking_id]
        user = booking.user
        timestamp = datetime.now()
        
        if booking.resource.type == ResourceType.DESK:
            heapq.heappush(self.desk_waiting_list, (-user.karma_points, timestamp, booking_id))
        else:
            heapq.heappush(self.room_waiting_lists[booking.resource.id], 
                          (-user.karma_points, timestamp, booking_id))

    def is_desk_available(self) -> bool:
        """Check if any desk is available"""
        for resource in self.resources.values():
            if resource.type == ResourceType.DESK:
                if self.is_resource_available(resource.id):
                    return True
        return False

    def assign_random_desk(self, booking_id: str):
        """Assign a random available desk to the booking"""
        available_desks = [
            resource for resource in self.resources.values()
            if resource.type == ResourceType.DESK and self.is_resource_available(resource.id)
        ]
        if available_desks:
            random_desk = random.choice(available_desks)
            booking = self.bookings[booking_id]
            booking.resource = random_desk
            booking.status = BookingStatus.CONFIRMED
            return True
        return False

    def is_resource_available(self, resource_id: str) -> bool:
        """Check if a specific resource is available"""
        for booking in self.bookings.values():
            if (booking.resource.id == resource_id and 
                booking.status in {BookingStatus.CONFIRMED, BookingStatus.PENDING}):
                return False
        return True

    def is_room_available(self, room_id: str, start_time: datetime, end_time: datetime, exclude_booking_id: str = None) -> bool:
        """Check if room is available for specified time"""
        for booking in self.bookings.values():
            if (booking.resource.id == room_id and 
                booking.status in {BookingStatus.CONFIRMED, BookingStatus.PENDING} and
                booking.id != exclude_booking_id and 
                not (end_time <= booking.start_time or start_time >= booking.end_time)):
                return False
        return True

    def request_booking(self, user_id: str, resource_id: str, booking_date: datetime, 
                       time_slot: TimeSlot, coworker_ids: List[str] = None) -> str:
        user = self.users[user_id]
        resource = self.resources[resource_id]
        start_time, end_time = self.get_time_slot_range(time_slot, booking_date)
        
        booking_id = str(uuid.uuid4())[:16]
        assert len(booking_id) == 16, f"Booking ID {booking_id} if not 16 characters"

        check_in_window = timedelta(minutes=30 if resource.type == ResourceType.DESK else 15)
        
        booking = Booking(
            id=booking_id,
            user=user,
            resource=resource,
            start_time=start_time,
            end_time=end_time,
            status=BookingStatus.PENDING,
            created_at=datetime.now(),
            check_in_deadline=start_time + check_in_window,
            coworkers=[self.users[cw_id] for cw_id in (coworker_ids or [])]
        )
        
        self.bookings[booking_id] = booking
        self.add_to_request_queue(booking_id)
        
        return booking_id

    def process_request_queue(self):
        """Process FIFO request queue"""
        while self.request_queue:
            booking_id = self.request_queue.pop(0)
            print(f"Processing booking ID: {booking_id}")
            # Check if booking still exists
            if booking_id not in self.bookings:
                print(f"Warning: Booking {booking_id} not found in bookings, skipping...")
                continue

            booking = self.bookings[booking_id]
            
            if booking.resource.type == ResourceType.DESK:
                if booking.coworkers: 
                    group_size = 1 + len(booking.coworkers)
                    available_groups = self.find_adjacent_desks(group_size, booking.start_time, TimeSlot.FULL_DAY)
                    if available_groups:
                        desks = available_groups[0]
                        booking.resource = desks[0]
                        booking.status = BookingStatus.CONFIRMED
                        for i, coworker in enumerate(booking.coworkers,1):
                            coworker_booking_id = str(uuid.uuid4())[:16]
                            assert len(coworker_booking_id) == 16, f"Booking ID {coworker_booking_id} is not 16 characters"
                            coworker_booking = Booking(id=coworker_booking_id,user=coworker,resource=desks[i],start_time=booking.start_time,end_time=booking.end_time,status=BookingStatus.CONFIRMED,created_at=booking.created_at,check_in_deadline=booking.check_in_deadline, coworkers=[])
                            self.bookings[coworker_booking_id] = coworker_booking
                    else:
                        self.add_to_waiting_list(booking_id)
                else:
                    if self.is_desk_available():
                        self.assign_random_desk(booking_id)
                    else:
                        self.add_to_waiting_list(booking_id)
            else:  # Room
                if self.is_room_available(booking.resource.id, booking.start_time, booking.end_time, exclude_booking_id =booking_id):
                    booking.status = BookingStatus.CONFIRMED
                else:
                    self.add_to_waiting_list(booking_id)

    def calculate_karma_penalty(self, booking: Booking) -> int:
        current_time = datetime.now()
        hours_until_booking = (booking.start_time - current_time).total_seconds() / 3600

        if hours_until_booking >24:
            return 0
        elif hours_until_booking < 0:
            return 100
        else:
            base_penalty = 10
            additional_penalty = int((24-hours_until_booking) / (16/60))
            return min(base_penalty + additional_penalty, 100)
    
    def process_cancellation(self, booking_id: str):
        booking = self.bookings[booking_id]
        penalty = self.calculate_karma_penalty(booking)
        booking.user.deduct_karma(penalty)
        booking.status = BookingStatus.CANCELLED

    def start_check_in_timer(self, booking_id: str):
        booking = self.bookings[booking_id]
        booking.check_in_deadline = datetime.now() + timedelta( minutes = 30 if booking.resource.type == ResourceType.DESK else 15)

    def check_in_user(self, booking_id: str):
        booking = self.bookings[booking_id]
        if datetime.now() <= booking.check_in_deadline:
            booking.status = BookingStatus.CONFIRMED
            return True
        else:
            self.release_resource(booking_id)
            return False
        
    def find_adjacent_desks(self, desk_count: int, booking_date: datetime, time_slot: TimeSlot) -> List[List[Resource]]:
        available_groups = []
        start_time, end_time, = self.get_time_slot_range(time_slot, booking_date)

        # Group desks by family
        families = defaultdict(list)
        for resource in self.resources.values():
            if resource.type == ResourceType.DESK:
                families[resource.desk_family].append(resource)

        # Check each family for enough available desks
        for family, family_desks in families.items():
            if len(family_desks) >= desk_count:
                available_desks = [
                    desk for desk in family_desks
                    if not any(
                        b.resource.id == desk.id and 
                        b.status in {BookingStatus.CONFIRMED, BookingStatus.PENDING} and
                        not (end_time <= b.start_time or start_time >= b.end_time)
                        for b in self.bookings.values()
                    )
                ]
                if len(available_desks) >= desk_count:
                    available_groups.append(available_desks[:desk_count])

        return available_groups


    def get_valid_room_times(self, date: datetime) -> List[datetime]:
        base_time = datetime.combine(date.date(), datetime.min.time().replace(hour=9))
        return [base_time + timedelta(minutes=30*i) for i in range(19)]  # 9:00 to 18:00

    def request_room_booking(self, user_id: str, room_id: str, start_time: datetime, end_time: datetime) -> str:
        # Validate time slots
        if not (start_time.minute in {0, 30} and end_time.minute in {0, 30}):
            raise ValueError("Bookings must start and end on hour or half-hour")

        if (end_time - start_time).seconds < 1800:  # 30 minutes
            raise ValueError("Booking must be at least 30 minutes")
    
        if (end_time - start_time).seconds > 32400:  # 9 hours (9am-6pm)
            raise ValueError("Booking cannot exceed 9 hours")
        
        user = self.users[user_id]
        resource = self.resources[room_id]
        booking_id = str(uuid.uuid4())[:16]
        assert len(booking_id) == 16, f"Booking ID {booking_id} is not 16 characters"
    
        booking = Booking(
            id=booking_id,
            user=user,
            resource=resource,
            start_time=start_time,
            end_time=end_time,
            status=BookingStatus.PENDING,
            created_at=datetime.now(),
            check_in_deadline=start_time + timedelta(minutes=15),
            coworkers=[]
        )
    
        self.bookings[booking_id] = booking
        self.add_to_request_queue(booking_id)
    
        print(f"Created booking with ID: {booking_id}")
        return booking_id
        
    def process_room_cancellation(self, booking_id: str):
        cancelled_booking = self.bookings[booking_id]
        room_id = cancelled_booking.resource.id
        cancelled_time = TimeRange(cancelled_booking.start_time, cancelled_booking.end_time)
    
        # Apply karma penalty and mark as cancelled
        penalty = self.calculate_karma_penalty(cancelled_booking)
        cancelled_booking.user.deduct_karma(penalty)
        cancelled_booking.status = BookingStatus.CANCELLED
    
        # Check waiting list for this room
        waiting_list = self.room_waiting_lists[room_id]
    
        while waiting_list:
            # Get highest priority booking from waiting list
            _, _, waiting_booking_id = heapq.heappop(waiting_list)
            waiting_booking = self.bookings[waiting_booking_id]
            waiting_time = TimeRange(waiting_booking.start_time, waiting_booking.end_time)

            # Check if this booking's time slot is now fully available, excluding itself
            if not any(
                TimeRange(b.start_time, b.end_time).overlaps(waiting_time)
                for b in self.bookings.values()
                if b.resource.id == room_id 
                and b.status in {BookingStatus.CONFIRMED, BookingStatus.PENDING}
                and b.id != waiting_booking_id # Exclude self
            ):
                waiting_booking.status = BookingStatus.CONFIRMED
                break
    '''     
    def print_booking_status(self):
        """Print the current status of all bookings for all resources"""
        print("\n === Current Booking Status ===")

        #Group bookings by resource
        bookings_by_resource = defaultdict(list)
        for booking in self.bookings.values():
            bookings_by_resource[booking.resource.id].append(booking)
        
        #Soft resources for consistent output
        for resource_id in sorted(bookings_by_resource.keys()):
            resource = self.resources[resource_id]
            print(f"\nResource: {resource.id} ({resource.type.value})")
            if resource.type == ResourceType.DESK:
                print(f" Family: {resource.desk_family}")
            bookings = bookings_by_resource[resource_id]

            #Sort bookings by start time for readability
            bookings.sort(key=lambda b: b.start_time)

            if bookings:
                for booking in bookings:
                    status = booking.status.value
                    user = booking.user.id
                    start = booking.start_time.strftime("%Y-%m-%d %H: %M")
                    end = booking.end_time.strftime("%Y-%m-%d %H: %M")
                    coworkers = ", ".join(cw.id for cw in booking.coworkers) if booking.coworkers else "None"
                    print(f" Booking ID: {booking.id}")
                    print(f" User: {user}")
                    print(f" Status: {status}")
                    print(f" Time: {start} - {end}")
                    print(f" Coworker: {coworkers}")
                else:
                    print(" No bookings.")

            #Print waiting lists
            print("\nDesk Waiting List:")
            if self.desk_waiting_list:
                for karma, timestamp, booking_id in sorted(self.desk_waiting_list, key=lambda x: x[1]):
                    booking = self.bookings.get(booking_id, None)
                    if booking:
                        print(f"  {booking_id}: {booking.user.id} (Karma: {-karma}, Time: {timestamp.strftime('%Y-%m-%d %H:%M:%S')})")
            
            else:
                print("Empty")

            print("\nRoom Waiting Lists:")
            for room_id, waiting_list in sorted(self.room_waiting_lists.items()):
                if waiting_list:
                    print(f" Room {room_id}:")
                    for karma, timestamp, booking_id in sorted(waiting_list, key=lambda x: x[1]):
                        booking = self.bookings.get(booking_id, None)
                        if booking:
                            print(f"    {booking_id}: {booking.user.id} (Karma: {-karma}, Time: {timestamp.strftime('%Y-%m-%d %H:%M:%S')})")
                else:
                    print(f" Room {room_id}: Empty")
    '''
                    

class TimeRange:
    def __init__(self, start: datetime, end: datetime):
        self.start = start
        self.end = end

    def overlaps(self, other: 'TimeRange') -> bool:
        return not (self.end <= other.start or self.start >= other.end)


def create_test_system():
    system = BookingSystem()
    
    # Add test users
    users = []
    for i in range(1, 33):  # Create 32 users (enough for all tests)
        users.append(User(f"u{i}", f"User{i}", f"user{i}@company.com"))

    for user in users:
        system.add_user(user)
        
    random.seed(42)
    
    # Add 30 desks (6 desk families with 5 desks each)
    desks = []
    for family in range(1, 7):  # 6 families
        for desk in range(1, 6):  # 5 desks per family
            desk_id = f"d{(family-1)*5 + desk}"  # d1, d2, ..., d30
            desks.append(
                Resource(desk_id, ResourceType.DESK, "Floor 1", f"family{family}")
            )
    
    # Add 10 conference rooms
    rooms = []
    for room in range(1, 11):
        rooms.append(
            Resource(f"r{room}", ResourceType.ROOM, "Floor 1")
        )
    
    # Add all resources to the system
    for resource in desks + rooms:
        system.add_resource(resource)
        
    return system

def run_tests():
    print("\nInitializing test system...")
    system = create_test_system()
    current_time = datetime.now()
    booking_date = current_time + timedelta(days=1)

    print("\n=== TEST 1: Basic Request Queue Processing ===")
    booking_id1 = system.request_booking("u1", "d1", booking_date, TimeSlot.FULL_DAY)
    assert len(system.request_queue) == 1
    system.process_request_queue()
    assert system.bookings[booking_id1].status == BookingStatus.CONFIRMED
    assert len(system.request_queue) == 0
    print("Basic request queue test passed!")

    print("\n=== TEST 2: Random Desk Assignment ===")
    booking_id2 = system.request_booking("u2", "d1", booking_date, TimeSlot.FULL_DAY)
    system.process_request_queue()
    assigned_desk = system.bookings[booking_id2].resource.id
    print(f"Randomly assigned desk: {assigned_desk}")
    assert system.bookings[booking_id2].status == BookingStatus.CONFIRMED
    print("Random desk assignment test passed!")

    print("\n=== TEST 3: Desk Waiting List ===")
    # Fill all desks
    for i in range(30):
        system.request_booking(f"u{i+3}", f"d{i+1}", booking_date, TimeSlot.FULL_DAY)
    system.process_request_queue()
    
    # Try booking when full
    waiting_booking_id = system.request_booking("u1", "d1", booking_date, TimeSlot.FULL_DAY)
    system.process_request_queue()
    assert len(system.desk_waiting_list) > 0
    print("Desk waiting list test passed!")

    print("\n=== TEST 4: Room Waiting List ===")
    
    system.clear_room_bookings('r1')
    
    room_booking_id = system.request_booking("u2", "r1", booking_date, TimeSlot.FULL_DAY)
    system.process_request_queue()
    
    # Second booking for same room/time
    waiting_room_booking = system.request_booking("u3", "r1", booking_date, TimeSlot.FULL_DAY)
    system.process_request_queue()
    assert len(system.room_waiting_lists["r1"]) > 0
    print("Room waiting list test passed!")

    print("\n=== TEST 5: Karma Points and Cancellation ===")
    booking_id5 = system.request_booking("u1", "d1", booking_date - timedelta(hours=12), TimeSlot.FULL_DAY)
    initial_karma = system.users["u1"].karma_points
    system.process_cancellation(booking_id5)
    assert system.users["u1"].karma_points < initial_karma
    print("Karma points deduction test passed!")

    print("\n=== TEST 6: RFID Check-in ===")
    booking_id6 = system.request_booking("u2", "d2", current_time + timedelta(minutes=5), TimeSlot.FULL_DAY)
    system.start_check_in_timer(booking_id6)
    assert system.check_in_user(booking_id6)
    print("RFID check-in text passed!")

    print("\n=== TEST 7: Group Booking ===")
    system.clear_all_desk_bookings()
    available_groups = system.find_adjacent_desks(3, booking_date, TimeSlot.FULL_DAY)
    assert len(available_groups) > 0
    assert all(len(group) == 3 for group in available_groups)
    assert all(group[0].desk_family == group[1].desk_family == group[2].desk_family for group in available_groups)
    print("Group booking test passed!")

    
    print("\n=== TEST 8: Room Booking Time Slots ===")
    system = create_test_system() # Reset system state
    system.clear_room_bookings('r1')
    room_start = datetime.combine(booking_date.date(), datetime.min.time().replace(hour=9))
    room_end = room_start + timedelta(hours=2)

    booking_id8 = system.request_room_booking("u1", "r1", room_start, room_end)
    system.process_request_queue()
    assert system.bookings[booking_id8].status == BookingStatus.CONFIRMED, f"Booking Successfully Completed!"

    try:
        invalid_start = room_start + timedelta(minutes=15)
        system.request_room_booking("u2", "r1", invalid_start, room_end)
        assert False, "Should have rejected booking not on half hour"
    except ValueError:
        print("Successfully rejected invalid time slot")

    print("\n=== TEST 9: Room Waiting List Priority ===")
    room_start = datetime.combine(booking_date.date(), datetime.min.time().replace(hour=9))
    #Create overlapping booking requests
    booking1 = system.request_room_booking("u2", "r1", room_start + timedelta(hours=3), room_start + timedelta(hours=4))
    booking2 = system.request_room_booking("u3", "r1", room_start + timedelta(hours=3), room_start + timedelta(hours=4))

    #Set different karma points
    system.users["u2"].karma_points = 800
    system.users["u3"].karma_points = 900
    system.process_request_queue()

    #Verify higher karma user gets priority
    waiting_list = system.room_waiting_lists["r1"]
    assert waiting_list[0][2] == booking2 #u3's booking
    print("Karma-based priority test passed!")

    print("\n=== TEST 10: Room Cancellation Processing ===")
    #Cancel original booking and verify waiting list processing
    system.process_room_cancellation(booking1)
    assert system.bookings[booking1].status == BookingStatus.CANCELLED
    
    #Verify appropriate waiting booking was confirmed
    assert system.bookings[booking2].status == BookingStatus.CONFIRMED
    print("Room cancellation processing test passed!")

    print("\n=== TEST 11: Desk Family Group Booking Confirmation ===")
    system = create_test_system()
    booking_date = datetime.now() + timedelta(days=1)
    system.clear_all_desk_bookings()

    #Request a group booking for 3 desks
    booking_id11 = system.request_booking(
        "u1", "d1", booking_date, TimeSlot.FULL_DAY, coworker_ids=["u2","u3"]
    )
    system.process_request_queue()

    #Verify booking and adjacent desks
    booking = system.bookings[booking_id11]
    assert booking.status == BookingStatus.CONFIRMED
    assert len(booking.coworkers) == 2
    
    # Check all related bookings 
    family = booking.resource.desk_family
    group_bookings = [
        b for b in system.bookings.values()
        if b.user.id in {"u1", "u2", "u3"} and b.start_time == booking.start_time
    ]
    assert len(group_bookings) == 3
    assert all(b.status == BookingStatus.CONFIRMED for b in group_bookings)
    assert all(b.resource.desk_family == family for b in group_bookings)
    print("Desk family group booking test passed!")

    #Print current booking status
    #system.print_booking_status()

if __name__ == "__main__":
    print("Starting tests...")
    run_tests()
    print("Tests completed successfully!")
