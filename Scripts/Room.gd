class_name Room
extends StaticBody2D

var RoomId : int
@export var Doors : Array[Area2D]

func _ready() -> void:
	# Make all doors viable on startup
	for door in Doors:
		MakeViable(door)

func MakeViable(Door : Area2D) -> void:
	Door.add_to_group("Viable")

func RemoveViable(Door : Area2D) -> void:
	Door.remove_from_group("Viable")
