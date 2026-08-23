extends Area2D

@export var direction : String = "east"   # "north", "south", "east", "west"

# References to the connected door and its room
var connected_door : Area2D = null
var connected_room : Room = null
