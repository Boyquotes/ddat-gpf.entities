extends Node

class_name EntityController

##############################################################################

# An entity controller is a child node of an entity responsible for changing
# a property of the parent entity. It automatically establishes a link with
# the parent entity, tracks when the parent entity is active, and performs
# behaviour only when the parent entity is active

# EntityControllers allow you to separate logic for different node behaviours
# into separate nodes, e.g. putting all jumping logic under one node, or
# all rotating logic under another. In doing so you can add comprehensive
# logic for each circumstance with toggleable options, so a jumpController
# might be the same script/node but with different exports set for different
# nodes.
# The design goals for the entityController were as follows:
# - Enable code re-use
# - Prevent repeating similar functions across nodes
# - Allow for modular node building
# - Decouple behaviours from central actors/entities
# - Improve behaviour readability

# Extend the EntityController class and use the included 'update' method
# when you wish to change the target property in the entity.
# See the included test_entity_controller scene within the actor entity
# system repository for an example of this.

#####
#//TODO
#	add support for node path to a non-parent entity?

##############################################################################

# NOTE: do not emit this directly
# call the 'update' public method to run validation checks beforehand
signal change_entity_property(property_name, property_value)

# the parent class to validate for
# if this is mis-set, the controller will fail to validate
# setting 'any' allows the property controller to work for any node, but
# disables the is_enabled() check in the 'update' method
enum PARENT_TYPE {ENTITY_AREA, ENTITY_BODY, ANY}

# for passing to error logging
const CLASS_NAME := "EntityController"
## for developer use, enable if making changes
#const CLASS_VERBOSE_LOGGING := false

export(PARENT_TYPE) var chosen_parent_type := PARENT_TYPE.ENTITY_AREA

# reference to the parent which is only set if validated
var valid_parent_node # setget _set_parent_node

# whether the entity controller established required refs and connects
var is_setup := false

##############################################################################

# setters and getters


#func _set_parent_entity_node(arg_value):
#	parent_entity_node = arg_value


##############################################################################

# virtual methods


# Called when the node enters the scene tree for the first time.
func _ready():
	# run setup steps in order
	if _setup_enter_and_exit_behaviour():
		_on_enter_tree()


##############################################################################

# public methods


# call this method when you wish to emit the signal
func update(arg_property_name, arg_property_value):
	# if setup isn't valid, the target or signal isn't valid
	if (is_setup == false):
		return
	# pass to the correct method
	if chosen_parent_type == PARENT_TYPE.ENTITY_AREA\
	or chosen_parent_type == PARENT_TYPE.ENTITY_BODY:
		_update_entity(arg_property_name, arg_property_value)
	elif chosen_parent_type == PARENT_TYPE.ANY:
		_update_any(arg_property_name, arg_property_value)


##############################################################################

# private methods


# preferred update method; called for valid entity_area and entity_body targets
# called from public update() method
func _update_entity(arg_property_name, arg_property_value):
	# if validated (is before this method), this should always be true
#	if not valid_parent_node.has_method("is_enabled"):
#		return
	if valid_parent_node.is_enabled():
		emit_signal("change_entity_property",
				str(arg_property_name), arg_property_value)


# alternate update method
# called from public update() method
# directly setting properties on the parent is not preferred behaviour
# devs if you find yourself constantly using the same class as a target for
# the controller, consider extending the class to support update_entity()
func _update_any(arg_property_name, arg_property_value):
	# following code duplicated from entityArea/entityBody class
	if str(arg_property_name) in valid_parent_node:
		# Assigns a new value to the given property; if it does not exist
		# or the given value's type doesn't match, nothing will happen.
		valid_parent_node.set(arg_property_name, arg_property_value)


func _on_enter_tree():
	if _setup_parent_ref():
		if _manage_setup_signal(true):
			is_setup = true


func _on_exit_tree():
	_manage_setup_signal(false)
	valid_parent_node = null
	is_setup = false


# check the entityController is child of an entity
func _setup_parent_ref() -> bool:
	var parent_node = get_parent()
	var outcome = false
	match chosen_parent_type:
		PARENT_TYPE.ENTITY_AREA:
			outcome = (parent_node is EntityArea)
		PARENT_TYPE.ENTITY_BODY:
			outcome = (parent_node is EntityBody)
		PARENT_TYPE.ANY:
			outcome = true
	if outcome:
		valid_parent_node = parent_node
	# whether was set
	return outcome


# before anything else make sure handling for tree changes is setup
func _setup_enter_and_exit_behaviour() -> bool:
	# attempt signal connections
	var enter_connection = connect("tree_entered", self, "_on_enter_tree")
	var exit_connection = connect("tree_exited", self, "_on_exit_tree")
	# validate and return
	if (enter_connection == OK)\
	and (exit_connection == OK):
		return true
	else:
		return false


# returns true 
func _manage_setup_signal(connect_new: bool = true) -> bool:
	# signal only used for entityArea and entityBody
	if chosen_parent_type == PARENT_TYPE.ANY:
		return true
	var outcome
	var target_method_string = "_on_change_property"
	# ERR check; parent should have the method
	if not valid_parent_node.has_method(target_method_string):
		return false
	if connect_new:
		outcome = connect("change_entity_property",
				valid_parent_node, target_method_string)
	else:
		outcome = is_connected("change_entity_property",
				valid_parent_node, target_method_string)
		if (outcome == OK):
			# no longer
			disconnect("change_entity_property",
					valid_parent_node, target_method_string)
	
	# if OK, return true, else false
	return (outcome == OK)

