extends Node

signal rooms_done

@export var RoomScenes : Array[PackedScene]
@export var MaxRooms : int = 100
@export var MinRooms : int = 10
@export var GenerationDelay : float = 0.3

var Rooms : Array[Room]
var is_generating : bool = false

# Direction helpers
func _direction_to_angle(dir: String) -> float:
	match dir:
		"east": return 0.0
		"north": return -PI/2
		"west": return PI
		"south": return PI/2
		_: return 0.0

func _opposite_direction(dir: String) -> String:
	match dir:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
		_: return ""

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	GenerateRooms()

func GenerateRooms() -> void:
	seed((Rooms.size()+10)*10 + randi_range(0,103647))
	randomize()
	if is_generating: return
	is_generating = true

	# First room at origin
	var first = CreateRoom(Vector2.ZERO)
	if first == null:
		push_error("Failed to create first room")
		return
	Rooms.append(first)
	await get_tree().create_timer(GenerationDelay).timeout

	var room_count = 1
	var consecutive_failures = 0
	const MAX_FAILURES = 30

	while room_count < MaxRooms and consecutive_failures < MAX_FAILURES:
		var source_room = GetRoomWithViableDoor()
		if source_room == null:
			print("No more viable doors – stopping.")
			emit_signal("rooms_done")
			break

		var new_room = CreateRoomAttachedTo(source_room)
		if new_room != null:
			Rooms.append(new_room)
			room_count += 1
			consecutive_failures = 0
			await get_tree().create_timer(GenerationDelay).timeout
		else:
			consecutive_failures += 1

	is_generating = false
	print("Generation finished. Total rooms: ", Rooms.size())

	# ---- Set labels on first and last rooms ----
	if Rooms.size() > 0:
		SetRoomLabel(Rooms[0], "First Room")
	if Rooms.size() > 1:
		SetRoomLabel(Rooms[-1], "Last Room")

# Helper: set label text (finds child named "Label")
func SetRoomLabel(room: Room, text: String) -> void:
	var label = room.get_node_or_null("Label")
	if label and label is Label:
		label.text = text
	else:
		push_warning("Room has no Label node, or it's not a Label.")

func GetRoomWithViableDoor() -> Room:
	var shuffled = Rooms.duplicate()
	shuffled.shuffle()
	for room in shuffled:
		for door in room.Doors:
			if door.is_in_group("Viable"):
				return room
	return null

func CreateRoom(pos: Vector2) -> Room:
	if RoomScenes.is_empty():
		push_error("No room scenes!")
		return null
	var type = randi_range(0, RoomScenes.size() - 1)
	var R = RoomScenes[type].instantiate()
	add_child(R)
	R.position = pos
	return R

func CreateRoomAttachedTo(source_room: Room) -> Room:
	var source_door = GetRandDoor(source_room)
	if source_door == null:
		return null

	var attempts = 0
	while attempts < 3:
		if RoomScenes.is_empty():
			return null
		var type = randi_range(0, RoomScenes.size() - 1)
		var R = RoomScenes[type].instantiate()
		add_child(R)

		var new_door = GetDoorWithOppositeDirection(R, source_door.direction)
		if new_door != null:
			var target_dir = _opposite_direction(source_door.direction)
			var target_angle = _direction_to_angle(target_dir)
			var current_angle = _direction_to_angle(new_door.direction)
			var rotation_needed = target_angle - current_angle
			R.rotation = rotation_needed

			var new_door_global = R.to_global(new_door.position)
			R.position = source_door.global_position - new_door_global

			source_room.RemoveViable(source_door)
			R.RemoveViable(new_door)
			return R
		else:
			R.queue_free()
			attempts += 1

	return null

func GetRandDoor(room: Room) -> Area2D:
	var viable = []
	for door in room.Doors:
		if door.is_in_group("Viable"):
			viable.append(door)
	if viable.is_empty():
		return null
	return viable[randi_range(0, viable.size() - 1)]

func GetDoorWithOppositeDirection(room: Room, dir: String) -> Area2D:
	var target = _opposite_direction(dir)
	for door in room.Doors:
		if door.is_in_group("Viable") and door.direction == target:
			return door
	return null
