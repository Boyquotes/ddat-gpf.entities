extends Node

class_name Action

##############################################################################
#
# A parent class for the ActionEffect, ActionCondition, ActionGroup,
# and ActionManager classes.
#
# Originally existed to avoid repeating methods and setup for tracking child
# nodes that are of a specific type (i.e. actionConditions for actionEffects).
# However this created cyclic referencing problems so have reverted.
# Superclass remains for future use.
#
##############################################################################

# extended Action classes (next step down) use 'CLASS_NAME'
# The specific actionEffects and actionConditions extended from there (two
# steps down) use the standard 'SCRIPT_NAME'.
# for passing to error logging
# no longer in use
#const SUPERCLASS_NAME := "ActionParent"

# priority is a common property across ActionEffect, ActionCondition,
# and ActionGroup; it determines wehether the action is being managed by a
# parent or managing itself.
# warning-ignore:unused_class_variable
export(bool) var manage_self := true

# priority is a common property across ActionEffect, ActionCondition,
# and ActionGroup; it determines the order in which the action is checked
# or resolved when the action is being managed by a parent (see manage_self).
# warning-ignore:unused_class_variable
export(int) var priority := 0

# specify the class type to be added to the 'valid_child_nodes'
# no longer in use
#var valid_child_type = ActionCondition

# nodes that are a valid type
# no longer in use
#var valid_child_nodes := []

##############################################################################


#func _ready():
#	_init_auto_node_handling()


##############################################################################

#
#func _init_auto_node_handling():
#	# ERR handling
#	if connect("child_entered_tree", self, "_add_child_to_record") != OK:
#		GlobalDebug.log_error(SUPERCLASS_NAME, "ready()", "signal exit invalid")
#	if connect("child_entered_tree", self, "_remove_child_from_record") != OK:
#		GlobalDebug.log_error(SUPERCLASS_NAME, "ready()", "signal enter invalid")
#	# setup initial child actionConditions
#	for child in get_children():
#		_add_child_to_record(child)
#
#
## recording child actionConditions of the actionEffect node
## called on _ready and child entering tree
#func _add_child_to_record(arg_child_node):
#	# since children can be (shouldn't, but it could happen) added to the
#	# actionEffect that aren't actionConditions, validate beforehand
#	if not arg_child_node is valid_child_type:
#		return
#	# ERR check
#	if arg_child_node.connect(
#			"tree_exiting", self, "_remove_child_from_record", [arg_child_node]) !=OK:
#				GlobalDebug.log_error(SUPERCLASS_NAME, "_add_child_to_record",
#						"condition added as child couldn't connect signal")
#				return
#	# only add to record if signal to remove successfully connects
#	valid_child_nodes.append(arg_child_node)
#
#
## recording child actionConditions of the actionEffect node
## called on child exiting tree
#func _remove_child_from_record(arg_child_node):
#	# since children can be (shouldn't, but it could happen) added to the
#	# actionEffect that aren't actionConditions, validate beforehand
#	if not arg_child_node is valid_child_type:
#		return
#	if valid_child_nodes.has(arg_child_node):
#		valid_child_nodes.erase(arg_child_node)


##############################################################################

#	~ Previous planning/documentation
#
#
# [The ActorAction System]
# The ActorAction class system consists of four classes that work with the
# Actor class (itself a class to manage game object stats, components, and
# behaviour) in order to create simple automatic modular behaviour trees.
# These four classes are;
#	ActionManager,
#	ActionGroup,
#	ActionEffect,
#	and ActionCondition.
#
# [ActorAction System Tree]
# ActionManager, ActionEffect and ActionCondition make up the ActorAction system.
# An Actor is a node with a regular Godot tree of nodes beneath it, as well as
# nodes of the ActorAction system classes as nested children.
#
# An example tree might look like this:
#	Actor
#	-> ActionManager
#		-> ActionGroup1
#			-> ActionEffect1
#			-> ActionEffect2
#				-> ActionCondition1
#				-> ActionCondition2
#			-> ActionEffect3
#				-> ActionCondition2
#				-> ActionCondition3
#		-> ActionGroup2
#			-> ActionCondition2
#			-> ActionEffect4
#				-> ActionCondition3
#				-> ActionCondition4
#			-> ActionEffect5
#				-> ActionCondition1
#				-> ActionCondition2
#				-> ActionCondition3
#				-> ActionCondition4
#			-> ActionEffect5
#				-> ActionCondition1
#				-> ActionCondition3
#	-> (rest of scene tree)
#
# As the above tree suggests, conditions are not exclusive to an effect,
# effects are not exclusive to a group, and effects do not need to be unique
# within a group (conditions beneath an effect should be unique else they
# would be redundant).
#
# [ActionManager]
# [Purpose]
# An ActionManager is the brain of the ActorAction system.
# The ActionManager should be unique (don't add multiple) and will recognise
# ActionGroup, ActionEffect, and ActionCondition, nodes as children.
# ActionManagers determine what happen every 'action resolution step' (when an
# action is chosen; i.e. per frame, on signal, or on interval (configurable).
# [Usage]
# The ActionManager will choose an ActionGroup to resolve (default behaviour
# is to select only one) each action resolution step. The ActionGroup chosen
# will be the highest priority (an action property) whose conditions are met.
# An ActionEffect child will resolve every action resolution step.
# An ActionCondition child will force a condition on all actionManager
# behaviour, and should be used carefully, as it will result in no/idle
# behaviour if all actions are blocked.
#
# [ActionGroup]
# An ActionGroup is a collection of effects and conditions, a node holder.
# If the ActionManager is a finite state machine, the ActionGroup is a state.
# ActionGroups recognise either ActionEffect or ActionCondition children.
# ActionEffect nodes are resolved if the group is chosen by the ActionManager.
# ActionEffect nodes are resolved in order of priority (an action property).
# ActionCondition nodes prevent the group from being chosen if they aren't met.
# ActionGroups can have multiple of either type of node, and ActionEffects can
# have their own ActionConditions as children, leading to group behaviour.
#
# [ActionEffect]
# ActionEffects have methods that take a node2D object as an argument, and
# then tell that node2D object to do things. They have validation methods that
# check if the properties referenced in their action/'do' methods are present.
# An example would be EffectMoveTowardPosition; an ActionEffect that tells
# an Actor to move toward the target position argument.
#
# [ActionCondition]
# ActionConditions are querying methods that check whether a specified
# condition is met or not.
# Conditions have an 'invert' property that allows them to be considered 'met'
# only if they evaluate to false instead of true.
# An example would be ConditionEntitiesWithinDistance; an ActionCondition that
# checks the distance_to() between the global position of two node2D objects.
# If distance is beneath the specified distance argument, it evaluates true.
# Conditions typically evaluate faster than Effects, as conditions can evaluate
# at game logic speed but effects are bound to the action resolution step. 
