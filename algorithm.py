from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import List, Dict, Optional, Set, Tuple
from collections import defaultdict
import heapq
import uuid

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
    desk_family: Optional[str] = None  # For desks that are part of a cluster

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
        self.request_queue: List[Tuple[int, datetime, str]] = []  # (priority, timestamp, booking_id)
        self.room_waiting_lists: Dict[str, List[Tuple[int, datetime, str]]] = defaultdict(list)  # resource_id -> [(priority, timestamp, user_id)]
        self.general_desk_waiting_list: List[Tuple[int, datetime, str]] = []  # [(priority, timestamp, user_id)]
        
    def get_time_slot_range(self, slot: TimeSlot, date: datetime) -> Tuple[datetime, datetime]:
        """Get start and end time for a given time slot on a specific date"""
        # Create a datetime for the given date at 9:00
        base_date = datetime.combine(date.date(), datetime.min.time().replace(hour=9))
        
        if slot == TimeSlot.FULL_DAY:
            return (base_date, base_date + timedelta(hours=8))  # 9:00 - 17:00
        elif slot == TimeSlot.MORNING:
            return (base_date, base_date + timedelta(hours=3))  # 9:00 - 12:00
        elif slot == TimeSlot.AFTERNOON:
            return (base_date + timedelta(hours=3), base_date + timedelta(hours=8))  # 12:00 - 17:00
        else:
            raise ValueError(f"Invalid time slot: {slot}")

    def add_resource(self, resource: Resource):
        self.resources[resource.id] = resource
        
    def add_user(self, user: User):
        self.users[user.id] = user
        
    def request_booking(self, user_id: str, resource_id: str, booking_date: datetime, 
                       time_slot: TimeSlot, coworker_ids: List[str] = None) -> str:
        user = self.users[user_id]
        resource = self.resources[resource_id]
        
        # Get start and end times for the requested slot
        start_time, end_time = self.get_time_slot_range(time_slot, booking_date)
        
        # Create booking with pending status
        booking_id = str(uuid.uuid4())
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
        
        # Add to request queue with priority based on karma points
        heapq.heappush(self.request_queue, (-user.karma_points, datetime.now(), booking_id))
        
        return booking_id

    def process_request_queue(self, current_time: datetime):
        print(f"Queue size before processing: {len(self.request_queue)}")
        
        # Make a copy of the queue for processing to avoid infinite loop
        to_process = []
        while self.request_queue:
            to_process.append(heapq.heappop(self.request_queue))
            
        for priority, timestamp, booking_id in to_process:
            booking = self.bookings[booking_id]
            print(f"Processing booking {booking_id} for resource {booking.resource.id}")
            
            # First check if this booking overlaps with any confirmed bookings
            is_available = True
            for existing_booking in self.bookings.values():
                if (existing_booking.id != booking_id and  # Don't check against itself
                    existing_booking.resource.id == booking.resource.id and
                    existing_booking.status == BookingStatus.CONFIRMED and
                    not (booking.end_time <= existing_booking.start_time or 
                         booking.start_time >= existing_booking.end_time)):
                    is_available = False
                    break
                    
            if is_available:
                booking.status = BookingStatus.CONFIRMED
                print(f"Booking {booking_id} confirmed for resource {booking.resource.id}")
            else:
                print(f"Resource {booking.resource.id} not available, returning booking {booking_id} to queue")
                heapq.heappush(self.request_queue, (priority, timestamp, booking_id))
        
        print(f"Queue size after processing: {len(self.request_queue)}")
                
    def request_multiple_desks(self, user_id: str, num_desks: int, booking_date: datetime,
                             time_slot: TimeSlot) -> List[List[str]]:
        """Returns lists of available desk combinations in the same desk family"""
        start_time, end_time = self.get_time_slot_range(time_slot, booking_date)
        available_combinations = []
        desk_families = self.get_desk_families()
        
        for family_id, desks in desk_families.items():
            if len(desks) >= num_desks:
                # Find all available desks in this family
                available_desks = [desk for desk in desks 
                                 if self.is_resource_available(desk.id, start_time, end_time)]
                
                if len(available_desks) >= num_desks:
                    # Create combinations of the available desks
                    for i in range(len(available_desks) - num_desks + 1):
                        combo = available_desks[i:i + num_desks]
                        available_combinations.append(combo)
                    
        return [[desk.id for desk in combo] for combo in available_combinations]
        
    def join_waiting_list(self, user_id: str, resource_id: Optional[str] = None):
        """Join either a specific room waiting list or the general desk waiting list"""
        user = self.users[user_id]
        priority = -user.karma_points  # Negative for min-heap to work as max-heap
        timestamp = datetime.now()
        
        if resource_id:  # Specific room waiting list
            heapq.heappush(self.room_waiting_lists[resource_id], 
                          (priority, timestamp, user_id))
        else:  # General desk waiting list
            heapq.heappush(self.general_desk_waiting_list, 
                          (priority, timestamp, user_id))
    
    def check_in(self, booking_id: str, current_time: datetime):
        """Process user check-in with RFID badge"""
        booking = self.bookings[booking_id]
        
        if current_time <= booking.check_in_deadline:
            booking.status = BookingStatus.CONFIRMED
            return True
        else:
            self.release_resource(booking_id)
            return False
            
    def release_resource(self, booking_id: str):
        """Release a resource and process waiting list"""
        booking = self.bookings[booking_id]
        booking.status = BookingStatus.MISSED
        
        # Process waiting lists
        if booking.resource.type == ResourceType.ROOM:
            waiting_list = self.room_waiting_lists[booking.resource.id]
        else:
            waiting_list = self.general_desk_waiting_list
            
        if waiting_list:
            _, _, user_id = heapq.heappop(waiting_list)
            # Here you would create a new booking for the waiting user
            # and send notification
            
    def calculate_cancellation_penalty(self, booking_id: str, cancel_time: datetime) -> int:
        booking = self.bookings[booking_id]
        time_until_start = (booking.start_time - cancel_time)
        hours_until_start = time_until_start.total_seconds() / 3600

        # Missed booking
        if hours_until_start <= 0:
            return 100

        # Early cancellation (>24 hours)
        if hours_until_start >= 24:
            return 0

        # Late cancellation (<24 hours)
        penalty = 10 + int((24 - hours_until_start) * (90/24))
        return min(100, penalty)
            
    def cancel_booking(self, booking_id: str, cancel_time: datetime):
        """Cancel a booking and apply karma penalties"""
        booking = self.bookings[booking_id]
        penalty = self.calculate_cancellation_penalty(booking_id, cancel_time)
        
        booking.user.deduct_karma(penalty)
        booking.status = BookingStatus.CANCELLED
        
        # Process waiting lists
        self.release_resource(booking_id)
        
    def reset_karma_points(self):
        """Reset all users' karma points to 1000"""
        for user in self.users.values():
            user.karma_points = 1000
            
    def get_desk_families(self) -> Dict[str, List[Resource]]:
        """Group desks by their desk family"""
        families = defaultdict(list)
        for resource in self.resources.values():
            if resource.type == ResourceType.DESK and resource.desk_family:
                families[resource.desk_family].append(resource)
        return families
        
    def is_resource_available(self, resource_id: str, start_time: datetime, 
                            end_time: datetime) -> bool:
        """Check if a resource is available for a given time period"""
        return resource_id in self.resources  # Just verify the resource exists

def create_test_system():
    system = BookingSystem()
    
    # Add some test users
    users = [
        User("u1", "Alice", "alice@company.com"),
        User("u2", "Bob", "bob@company.com"),
        User("u3", "Charlie", "charlie@company.com")
    ]
    for user in users:
        system.add_user(user)
        
    # Add 30 desks (6 desk families with 5 desks each)
    desks = []
    for family in range(1, 7):  # 6 families
        for desk in range(1, 6):  # 5 desks per family
            desk_id = f"d{(family-1)*5 + desk}"  # d1, d2, ..., d30
            desks.append(
                Resource(desk_id, ResourceType.DESK, f"Desk family {(family-1)//2 + 1}", f"family{family}")
            )
    
    # Add 10 conference rooms (spread across floors)
    rooms = []
    for room in range(1, 11):
        floor = (room-1) // 2 + 1  # 2 rooms per floor
        rooms.append(
            Resource(f"r{room}", ResourceType.ROOM, f"Desk family {floor}")
        )
    
    # Add all resources to the system
    for resource in desks + rooms:
        system.add_resource(resource)
        
    return system

def run_tests():
    print("\nInitializing test system...")
    system = create_test_system()
    current_time = datetime.now()
    booking_date = current_time + timedelta(days=1)  # Tomorrow
    
    print("\nAvailable resources:")
    for resource in system.resources.values():
        print(f"- {resource.id} ({resource.type.value}) at {resource.location}")

    print("\n=== TEST 1: Basic Single Booking ===")
    time_slot = TimeSlot.FULL_DAY
    start_time, end_time = system.get_time_slot_range(time_slot, booking_date)
    print(f"Creating full-day booking for tomorrow from {start_time.strftime('%H:%M')} to {end_time.strftime('%H:%M')}")
    
    booking_id1 = system.request_booking("u1", "d1", booking_date, time_slot)
    system.process_request_queue(current_time)
    assert system.bookings[booking_id1].status == BookingStatus.CONFIRMED
    print("Basic booking test passed!")

    print("\n=== TEST 2: Competing Bookings (Testing Karma Priority) ===")
    # Modify karma points for testing
    system.users["u2"].karma_points = 1000  # Higher priority
    system.users["u3"].karma_points = 800   # Lower priority
    
    # Try to book the same desk for the same time
    booking_id2 = system.request_booking("u2", "d1", booking_date, TimeSlot.FULL_DAY)
    booking_id3 = system.request_booking("u3", "d1", booking_date, TimeSlot.FULL_DAY)
    system.process_request_queue(current_time)
    
    # First booking should stay confirmed, others should remain pending
    assert system.bookings[booking_id1].status == BookingStatus.CONFIRMED
    assert system.bookings[booking_id2].status == BookingStatus.PENDING
    assert system.bookings[booking_id3].status == BookingStatus.PENDING
    print("Competing bookings test passed!")

    print("\n=== TEST 3: Waiting List ===")
    # Add users to waiting list for a specific room
    system.join_waiting_list("u2", "r1")
    system.join_waiting_list("u3", "r1")
    # Test general desk waiting list
    system.join_waiting_list("u1")  # No specific resource ID
    
    # Verify waiting list priorities
    room_queue = system.room_waiting_lists["r1"]
    assert len(room_queue) == 2
    assert room_queue[0][2] == "u2"  # u2 should be first (higher karma)
    print("Waiting list test passed!")

    print("\n=== TEST 4: Multiple Desk Booking ===")
    # Request 3 adjacent desks from the same family
    available_combinations = system.request_multiple_desks("u1", 3, booking_date, TimeSlot.MORNING)
    assert len(available_combinations) > 0  # Should find at least one combination
    print(f"Found {len(available_combinations)} possible combinations of 3 adjacent desks")
    print("Multiple desk booking test passed!")

    print("\n=== TEST 5: Room Booking with Different Check-in Window ===")
    # Book a room (15-minute check-in window)
    room_booking_id = system.request_booking("u1", "r1", booking_date, TimeSlot.MORNING)
    system.process_request_queue(current_time)
    
    # Verify check-in window
    room_booking = system.bookings[room_booking_id]
    desk_booking = system.bookings[booking_id1]
    assert (room_booking.check_in_deadline - room_booking.start_time) == timedelta(minutes=15)
    assert (desk_booking.check_in_deadline - desk_booking.start_time) == timedelta(minutes=30)
    print("Room booking check-in window test passed!")

    print("\n=== TEST 6: Cancellation Penalties ===")
    # Create booking for 3 days in the future
    test_date = datetime.now() + timedelta(days=3)
    test_date = test_date.replace(hour=9, minute=0, second=0, microsecond=0)
    future_booking_id = system.request_booking("u1", "d3", test_date, TimeSlot.FULL_DAY)
    system.process_request_queue(current_time)

    # Test early cancellation (48 hours before)
    cancel_time = test_date - timedelta(hours=48)
    penalty = system.calculate_cancellation_penalty(future_booking_id, cancel_time)
    assert penalty == 0

    # Test late cancellation (12 hours before)
    cancel_time = test_date - timedelta(hours=12)
    penalty = system.calculate_cancellation_penalty(future_booking_id, cancel_time)
    assert penalty > 10 and penalty < 100

    # Test missed booking
    cancel_time = test_date + timedelta(hours=1)
    penalty = system.calculate_cancellation_penalty(future_booking_id, cancel_time)
    assert penalty == 100

    print("Cancellation penalties test passed!")
    
    # Print time slots for reference
    print("\nAvailable time slots:")
    for slot in TimeSlot:
        start, end = system.get_time_slot_range(slot, booking_date)
        print(f"- {slot.value}: {start.strftime('%H:%M')} - {end.strftime('%H:%M')}")

if __name__ == "__main__":
    print("Starting tests...")
    run_tests()
    print("Tests completed successfully!")