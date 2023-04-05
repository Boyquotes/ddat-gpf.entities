extends Action

#class_name ActionCondition

##############################################################################
#
# An ActionCondition object verifies a specific condition/whether its target
# is in a specific state, and passes that information to an ActionEffect,
# ActionGroup, or ActionManager, parent node.
#
# This is a structure-only parent class, and does nothing by itself.
# Included with the ddat-gpf package should be some example classes extended
# from the actionCondition class, which actually have functionality.
#
##############################################################################

# these signals are emitted only when the condition state changes
# emitted only if the state changes to valid
signal condition_state_now_valid()
# emitted only if the state changes to invalid
signal condition_state_now_invalid()

# for passing to error logging
const CLASS_NAME := "ActionCondition"
# for developer use, enable if making changes
const CLASS_VERBOSE_LOGGING := true

# setting this property true changes the accepted value of the condition_state
# property, i.e. a 'false' value is desired rather than 'true'.
# if invert_condition is set true, this actionCondition will only evaluate
# true whilst the conditions it is checking against are not correct.
export(bool) var invert_condition := false

# this is the main condition property
# by default the value of this property is what the condition evaluates to
# if invert_condition is set (see above), the opposite is instead true
var condition_state := false setget _set_condition_state

# some actionCondition classes take a moment to get themselves ready.
# i.e. they are not ready to go on joining the scene tree.
# they will set this false on _ready(), then true when they are actually ready.
# actionManagers check this property before considering a condition, and
# consider any condition that isn't ready to be evaluated as false.
# (is not used in this script)
# warning-ignore:unused_class_variable
var condition_ready := true

##############################################################################


# setter for the condition state, passing information about state to nodes
# responsible for doing something based on the state
func _set_condition_state(arg_value):
	# store the state before setting
	var previous_condition_state = condition_state
	# set the state
	condition_state = arg_value
	# check if state matches the desired state
	var get_if_valid = is_valid()
	# if previous state was different, emit whether state matches desired
	if (previous_condition_state != condition_state):
		if get_if_valid:
			emit_signal("condition_state_now_valid")
		else:
			emit_signal("condition_state_now_invalid")


##############################################################################


# returns whether the condition has evaluated true or not
# called automatically when state changes but also can be called manually
func is_valid() -> bool:
	var is_valid := false
	if (invert_condition == true) and (condition_state == false)\
	or (invert_condition == false) and (condition_state == true):
		is_valid = true
	return is_valid

