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
# if the is_valid property is changed it emits this signal
signal is_valid(valid_state)
# if the is_enabled state changes to true it emits this signal
signal is_enabled()
# if the is_enabled state changes to false it emits this signal
signal is_disabled()

# for passing to error logging
const CLASS_NAME := "EntityArea"
## for developer use, enable if making changes
#const CLASS_VERBOSE_LOGGING := false

# is the entity currently allowed to perform behaviour?
# disable this flag if you wish the entity to temporarily stop behaviour
var is_active := false setget _set_is_active
# was setup performed correctly for this entity
# enable this flag after all setup methods return succesfully
var is_valid := false setget _set_is_valid

##############################################################################

# setters and getters


# setter when is_active property is changed
# emits various signals
func _set_is_active(arg_value):
	# check whether is_enabled state would have changed by this value changing
	var is_value_changed = false
	if is_active != arg_value:
		is_value_changed = true
	# set value
	is_active = arg_value
	# signal for new value emitted if values weren't set to the same
	var is_enabled_state = is_enabled()
	if is_value_changed:
		emit_signal("is_active", is_active)
		_change_enabled_properties(is_enabled_state)


# setter when is_valid property is changed
# emits various signals
func _set_is_valid(arg_value):
	# check whether is_enabled state would have changed by this value changing
	var is_value_changed = false
	if is_valid != arg_value:
		is_value_changed = true
	# set value
	is_valid = arg_value
	# signal for new value emitted if values weren't set to the same
	var is_enabled_state = is_enabled()
	if is_value_changed:
		emit_signal("is_valid", is_valid)
		emit_signal("is_enabled", is_enabled_state)
		_change_enabled_properties(is_enabled_state)


##############################################################################

# public


# entity only performs behaviour whilst the is_active and is_valid flags
# are both set true
func is_enabled() -> bool:
	return (is_active and is_valid)


##############################################################################

# private


# set properties which are determined by the is_enabled() state
# this is checked whenever is_active or is_valid are changed
# an invalid entity will be invisible, ignore collison, and not perform any
# behaviour handled by process or physics_process
func _change_enabled_properties(new_state: bool):
	set_process(new_state)
	set_physics_process(new_state)
	visible = new_state
	monitorable = new_state
	monitoring = new_state
	# emit signal based on new state
	if (new_state == true):
		emit_signal("is_enabled")
	else:
		emit_signal("is_disabled")


func _on_change_property(property_name, property_value):
	if typeof(property_name) == TYPE_STRING:
		if property_name in self:
			# Assigns a new value to the given property; if it does not exist
			# or the given value's type doesn't match, nothing will happen.
			self.set(property_name, property_value)


##############################################################################

