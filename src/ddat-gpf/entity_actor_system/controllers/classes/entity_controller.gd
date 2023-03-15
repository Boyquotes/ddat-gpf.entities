extends Node

class_name EntityController

##############################################################################

# An entity controller is a child node of an entity responsible for changing
# a property of the parent entity. It automatically establishes a link with
# the parent entity, tracks when the parent entity is active, and performs
# behaviour only when the parent entity is active

# Extend the EntityController class and use the included 'update' method
# when you wish to change the target property in the entity.

#//TODO
#	add support for node path to a non-parent entity?

##############################################################################

# NOTE: do not emit this directly
# call the 'update' public method to run validation checks beforehand
signal change_entity_property(property_name, property_value)

# for passing to error logging
const CLASS_NAME := "EntityController"
## for developer use, enable if making changes
#const CLASS_VERBOSE_LOGGING := false

var parent_entity: Entity

# whether the entity controller established required refs and connects
var is_setup := false

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
	if (is_setup == false):
		return
	if parent_entity.is_enabled():
		emit_signal("change_entity_property",
				str(arg_property_name), arg_property_value)


##############################################################################

# private methods


func _on_enter_tree():
	if _setup_parent_ref():
		if _manage_setup_signal(true):
			is_setup = true


func _on_exit_tree():
	_manage_setup_signal(false)
	parent_entity = null
	is_setup = false


# check the entityController is child of an entity
func _setup_parent_ref():
	var parent_node = get_parent()
	if parent_node is Entity:
		parent_entity = parent_node


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


func _manage_setup_signal(connect_new: bool = true) -> bool:
	var outcome
	if connect_new:
		outcome = connect("change_entity_property",
				parent_entity, "_on_change_entity_property")
	else:
		outcome = is_connected("change_entity_property",
				parent_entity, "_on_change_entity_property")
		if (outcome == OK):
			# no longer
			disconnect("change_entity_property",
					parent_entity, "_on_change_entity_property")
	
	# if OK, return true, else false
	return (outcome == OK)

