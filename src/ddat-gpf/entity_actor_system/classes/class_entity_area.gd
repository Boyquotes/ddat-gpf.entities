extends Area2D

class_name EntityArea

##############################################################################

# An entity is anything in the game project that has behaviour, whether that
# behaviour is controlled by the player or in response to other game events.

# There are two different types of entity,
# EntityArea, extending from the Area2D class,
# and EntityBody, extending from the KinematicBody class.

# This is the EntityArea class.

##############################################################################

# if the is_active property is changed it emits this signal
signal is_active(active_state)

# for passing to error logging
const CLASS_NAME := "EntityArea"
## for developer use, enable if making changes
#const CLASS_VERBOSE_LOGGING := false

# is the entity currently allowed to perform behaviour?
# disable this flag if you wish the entity to temporarily stop behaviour
var is_active := false setget _set_is_active
# was setup performed correctly for this entity
# enable this flag after all setup methods return succesfully
var is_valid := false

##############################################################################

# setters and getters


func _set_is_active(arg_value):
	is_active = arg_value
	emit_signal("is_active", is_active)


##############################################################################

# public


# entity only performs behaviour whilst the is_active and is_valid flags
# are both set true
func is_enabled() -> bool:
	return (is_active and is_valid)


##############################################################################

# private


func _on_change_property(property_name, property_value):
	if typeof(property_name) == TYPE_STRING:
		if property_name in self:
			# Assigns a new value to the given property; if it does not exist
			# or the given value's type doesn't match, nothing will happen.
			self.set(property_name, property_value)


##############################################################################

