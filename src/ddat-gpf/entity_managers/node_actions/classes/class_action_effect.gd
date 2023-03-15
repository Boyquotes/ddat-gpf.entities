extends Action

class_name ActionEffect

##############################################################################
#
# An ActionEffect object is a container for a method that works alongside
# the actionManager, actionGroup, and actionCondition, classes to provide
# conditional customisable modular behaviour.

# This is a structure-only parent class, and does nothing by itself.
# Included with the ddat-gpf package should be some example classes extended
# from the ActionEffect class, which actually have functionality.

#//TODO	add behaviour for propagating action_owner through action classes
#		(see _init_action_owner)

##############################################################################

# emitted before the action is called
signal action_firing()
# emitted after the action is called
signal action_fired()

#07. constants
# for passing to error logging
const CLASS_NAME := "ActionEffect"
# for developer use, enable if making changes
const CLASS_VERBOSE_LOGGING := true

# set a limit on how many times the action can fire
# if set negative (default) the action can repeat indefinitely
# is checked by an ActionManager (not used in this script)
# warning-ignore:unused_class_variable
export(int) var do_x = -1

# if you set this in-editor the action_owner property is automatically set
# to this ndoe on actionEffect ready (assuming it is a valid Actor object)
export(NodePath) var path_to_actor
# if you set this in-editor the action_target property is automatically set
# to this node on actionEffect ready (assuming it is a valid Node2D)
export(NodePath) var path_to_target

# node2D that this action is performed by
# if not set by the export path_to_actor, this will default to parent
var action_owner: Actor
# node2D that this action is performed toward
# the target and actor 
# NOTE: some actionEffect behaviour may not fire without a valid target
var action_target: Node2D

# amount of times the action has resolved
var done = 0

# actionConditions set as children of this node
var conditions = []

##############################################################################

# virtual


func _ready():
	_init_action_owner()
	_init_action_target()
	_init_auto_node_handling()


##############################################################################

# public


# this is the default action effect calling method
# it runs basic validation checks before actually calling the 
# call this method with arg 'true' to ignore actionConditions
func do(ignore_validation: bool = false):
	if _validate_action(ignore_validation):
		emit_signal("action_firing")
		_action_function()
		emit_signal("action_fired")
		done += 1


##############################################################################

# private


# the most important method
# this is what distinguishes actionEffects from each other
# in the parent class it is intentionally empty
# shadow this method in extended ActionEffect classes where you've
# included actual behaviour
func _action_function():
	pass


func _validate_action(arg_validation_override) -> bool:
	# if overridden, immediately return
	if arg_validation_override == true:
		return arg_validation_override
	# if action do limit is reached, return invalid
	if do_x >= done:
		return false
	
	# skip checking conditions if there aren't any
	if not conditions.empty():
		# check condition validity (actionCondition state vs invert properties)
		for actcon in conditions:
			if actcon is ActionCondition:
				if (actcon.is_valid() == false):
					return false
	
	# if all validation checks passed without returning invalid, success!
	return true


##############


# if path_to_actor is set and valid, set the action_owner
# if path_to_actor is not set and valid, action_owner will default to parent
# if parent is an action derived class, the action_owner property will be set
# to the parent of that node, propagating until it reaches a non-action object.
func _init_action_owner():
	var potential_action_owner = null
	# check the path is to a valid actor
	if path_to_actor != null:
		potential_action_owner = get_node_or_null(path_to_actor)
	# or check if parent is a valid actor
	elif action_owner == null:
		potential_action_owner = get_parent()
	# set if valid
	if potential_action_owner != null:
		if potential_action_owner is Actor:
			action_owner = potential_action_owner


# if path_to_target is set and valid, set the action_target
func _init_action_target():
	var potential_action_target = null
	# check the path is to a valid actor
	if path_to_actor != null:
		potential_action_target = get_node_or_null(path_to_actor)
	# set if valid
	if potential_action_target != null:
		if potential_action_target is Node2D:
			action_target = potential_action_target

	if path_to_target != null:
		action_target = action_target


func _init_auto_node_handling():
	# ERR handling
	if connect("child_entered_tree", self, "_add_child_to_record") != OK:
		GlobalDebug.log_error(CLASS_NAME, "ready()", "signal exit invalid")
	if connect("child_entered_tree", self, "_remove_child_from_record") != OK:
		GlobalDebug.log_error(CLASS_NAME, "ready()", "signal enter invalid")
	# setup initial child actionConditions
	for child in get_children():
		_add_child_to_record(child)


# recording child actionConditions of the actionEffect node
# called on _ready and child entering tree
func _add_child_to_record(arg_child_node):
	# since children can be (shouldn't, but it could happen) added to the
	# actionEffect that aren't actionConditions, validate beforehand
	if not arg_child_node is ActionCondition:
		return
	# ERR check
	if arg_child_node.connect(
			"tree_exiting", self, "_remove_child_from_record", [arg_child_node]) !=OK:
				GlobalDebug.log_error(CLASS_NAME, "_add_child_to_record",
						"condition added as child couldn't connect signal")
				return
	# only add to record if signal to remove successfully connects
	conditions.append(arg_child_node)


# recording child actionConditions of the actionEffect node
# called on child exiting tree
func _remove_child_from_record(arg_child_node):
	# since children can be (shouldn't, but it could happen) added to the
	# actionEffect that aren't actionConditions, validate beforehand
	if not arg_child_node is ActionCondition:
		return
	if conditions.has(arg_child_node):
		conditions.erase(arg_child_node)

