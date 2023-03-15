extends Area2D

class_name Entity

##############################################################################

# An entity is anything in the game project that has behaviour, whether that
# behaviour is controlled by the player or in response to other game events.

##############################################################################

# for passing to error logging
const CLASS_NAME := "Entity"
## for developer use, enable if making changes
#const CLASS_VERBOSE_LOGGING := false

# is the entity currently allowed to perform behaviour?
# disable this flag if you wish the entity to temporarily stop behaviour
var is_active := false
# was setup performed correctly for this entity
# enable this flag after all setup methods return succesfully
var is_valid := false

##############################################################################

# public


# entity only performs behaviour whilst the is_active and is_valid flags
# are both set true
func is_enabled() -> bool:
	return (is_active and is_valid)


##############################################################################

# private


func _on_change_entity_property(property_name, property_value):
	if typeof(property_name) == TYPE_STRING:
		if property_name in self:
			# Assigns a new value to the given property; if it does not exist
			# or the given value's type doesn't match, nothing will happen.
			self.set(property_name, property_value)


##############################################################################

