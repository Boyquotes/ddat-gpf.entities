extends EntityController

#class_name Accelerate

##############################################################################

# EntityController that moves the entity according to the value of the speed
# vector whilst increasing the speed vector over time.

##############################################################################

export(float, -1000.0, 1000.0) var base_speed_x := 50.0
export(float, -1000.0, 1000.0) var base_speed_y := 50.0
export(float, -100.0, 100.0) var acceleration_x := 10.0
export(float, -100.0, 100.0) var acceleration_y := 10.0

var current_speed := Vector2.ZERO

export(bool) var debug_log := false

##############################################################################


func _ready():
	current_speed = Vector2(base_speed_x, base_speed_y)


func _process(delta):
	current_speed.x += (acceleration_x*delta)
	current_speed.y += (acceleration_y*delta)
	if debug_log:
		print("updating: ", "current_speed is "+str(current_speed))
	update("velocity", current_speed)

