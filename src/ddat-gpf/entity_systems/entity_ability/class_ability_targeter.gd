extends Area2D

class_name EntityAbilityTargeter

##############################################################################

# Use an EntityAbilityTargeter in conjunction with an ActivationController,
# or ActivationController extended node, to determine target selection for
# an ability.
# Can pass active target to a node independently of activation signals,
# allowing targeting to happen as frequently as need be whilst activation
# is only processed on the correct input (or other condition).

# An EntityAbilityTargeter's parent in the scene tree should ALWAYS be
# an ActivationController or ActivationController extended node (such as an
# AbilityController or ability controller extended node). Certain functions
# of the targeter may not work if this is not the case.

##############################################################################

#//TODO
# clean documentation

#//TODO 
# (search file)

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# pass along a reference to the target
signal update_target_reference(target_reference)
# pass along the current position of the target
signal update_target_position(target_position)
# emitted when not updating the target, along with the remaining frames until
# the next update and the proportion (as float) to the next update
signal update_not_ready(frames_left, proportion_to)
# if using a non-sprite reticule you can connect this signal to the node
# for when to show the reticule
signal change_reticule_visibility(is_visible)

# the target data to gather and update
enum RETURN_TYPE {
	NODE_REFERENCE,
	GLOBAL_POSITION,
}

# how to target the ability during target selection state
# when utilising an automatic (prefix AUTO_) target selection mode the position
# of this node is considered for distance to the target, so make sure your
# entityAbilityController nodes are scene tree children of your entities.
#
# NONE - disables all return options
# MOUSE_LOOK - can only return position, not target reference
# AUTOMATIC - automatic requires a specified target logic to be set on the
#	'selector_method' property. This should be a method that returns either a
# Node2D or null; extend this class to add your own selection methods.
enum SELECTION {
	NONE,
	MOUSE_LOOK,
	SELECTOR_METHOD,
	}

# when to show the ability's relevant targeting reticule
enum RETICULE {
	SHOW_ALWAYS,
	SHOW_ON_ACTIVATION,
	SHOW_ON_TARGETING,
	NEVER_SHOW,
	}

# disable when finished
# for dev logging
const CLASS_VERBOSE_LOGGING := false
const CLASS_SCRIPT_NAME := "ActivationController"

# toggles for which signals you wish to output
# 'output_target_reference' -> emit signal 'update_target_reference'
export(bool) var output_target_reference := true
# 'output_target_position' -> emit signal 'update_target_position'
export(bool) var output_target_position := true

# the node group string to pick potential targets from
# used as-is this has the potential to negatively impact performance,
# (especially calculating distance), so to prune potential targets consider;
#	adding a collision shape (change grouping as targets enter/exit shape),
#	change target grouping on screen enter/exit using visibility notifiers
export(String) var target_groupstring := "groupstring_enemy"

# the active target selection mode, see SELECTION
# if using an automatic target selection mode the properties following this
# property determine how to handle automatic target selection
export(SELECTION) var selection_mode

export(String) var selector_method := "_get_nearest"

# selector methods can be written to support node reference return (preferred)
# or global position return, but which they return must be set in this export
# note: returning node reference also allows output of global position, but
# returning global position does not allow output of node reference. This
# property exists to give devs leeway when extending the targeter class
# and writing their own selector methods.
export(RETURN_TYPE) var selector_returns := RETURN_TYPE.NODE_REFERENCE

# how many frames between updating target
# lower values may cause lag with large numbers of entityAbilityTargeters
export(float, 0.0, 10.0) var update_frequency := 0.5

# the active targeting reticule mode, see RETICULE
export(RETICULE) var reticule_mode =\
		RETICULE.SHOW_ALWAYS

# path to a sprite that displays as the targeting reticule for this ability
# if no path is set the chosen_targeting_reticule property will default to
# RETICULE.NEVER_SHOW, and targeting reticules will be ignored
export(NodePath) var path_to_reticule_sprite

# duration to show the reticule on ActivationController activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
export(float, 0.0, 60.0) var show_reticule_duration := 0.4

# delta accumulation since last signal update
var frames_since_last_update := 0.0

# stored reference of last target
var current_target
# stored position of last target
var current_target_position

# if on and in RETICULE.SHOW_ON_TARGETING mode, shows targeting graphics
var is_targeting_active := false setget _set_is_targeting_active

# tracking whether the reticule has been temporarily shown after activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
var showing_reticule_after_activation := false
# delta accumulation since targeting reticule was set visible
# used to track when to hide the reticule again
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
var frames_since_reticule_shown := 0.0

# reference to targeting reticule sprite, if unset will disable any reticule
# based methods such as _change_targeting_reticule_visibility
var targeting_reticule_node: Sprite = null

# property set when reticule signals and parent exit condition are connected,
# and the reticule node type is validated
var is_reticule_setup := false

##############################################################################

# setters and getters

func _set_is_targeting_active(arg_value):
	is_targeting_active = arg_value
	if reticule_mode == RETICULE.SHOW_ON_TARGETING:
		_change_targeting_reticule_visibility(arg_value)


##############################################################################

# virtual methods

# auto connect reticule handling behaviours to parent activation controller
# automatically connects confirmed_hold and confirmed_press activation signals
# to methods that show the reticule for a brief predetermined period
func _enter_tree():
	var parent_node = get_parent()
	var signal_connection_state_1 := false
	var signal_connection_state_2 := false
	if parent_node is ActivationController:
		signal_connection_state_1 = GlobalFunc.confirm_signal(\
				true, parent_node, self,
				"activate_ability", "_show_reticule_on_activation")
		signal_connection_state_2 = GlobalFunc.confirm_signal(\
				true, parent_node, self,
				"input_confirming", "_show_reticule_on_targeting")
	is_reticule_setup =\
			(signal_connection_state_1 and signal_connection_state_2)


# auto connect reticule handling behaviours to parent activation controller
# automatically disconnects reticule handling signals from the parent
# disabled as should happen automatically when a node is removed
#func _exit_tree():
#	var parent_node = get_parent()
#	var signal_connection_state_1 := false
#	var signal_connection_state_2 := false
#	if parent_node is ActivationController:
#		signal_connection_state_1 = GlobalFunc.confirm_signal(\
#				false, parent_node, self,
#				"activate_ability", "_show_reticule_on_activation")
#		signal_connection_state_2 = GlobalFunc.confirm_signal(\
#				false, parent_node, self,
#				"input_confirming", "_show_reticule_on_targeting")
#	is_reticule_setup =\
#			(signal_connection_state_1 and signal_connection_state_2)


# call setters and getters
func _ready():
	self.selection_mode = selection_mode
	#
	# reticule handling
	self.reticule_mode = reticule_mode
	_attempt_to_set_targeting_reticule()


# delta is time since last frame
func _process(arg_delta):
	frames_since_last_update += arg_delta
	if frames_since_last_update >= update_frequency:
		frames_since_last_update -= update_frequency
		
		# multiple output methods exist, even though a node reference is
		# enough to get position, because certain abilities may just wish
		# to send an ability toward a position or in a specific direction
		
		# reference to target handling
		if output_target_reference:
			current_target =\
					get_target_data_by_selection(RETURN_TYPE.NODE_REFERENCE)
			if current_target != null:
				emit_signal("update_target_reference", current_target)
		
		# position of target handling
		if output_target_position:
			if current_target is Node2D:
				current_target_position = current_target.global_position
			else:
				current_target_position =\
						get_target_data_by_selection(
						RETURN_TYPE.GLOBAL_POSITION)
			if current_target_position != null:
				emit_signal("update_target_position", current_target_position)
		
		current_target_position =\
				get_target_data_by_selection(RETURN_TYPE.GLOBAL_POSITION)
		# if target was found, update all
		# can assume in receipient nodes that this passed param is vec2
		if current_target_position != null\
		and output_target_position:
			# if it isn't null should only ever pass a vec2
			assert(current_target_position is Vector2)
			emit_signal("update_target_position", current_target_position)
	# if update doesn't happen this frame, pass along how long it will be
	# until the next target update (this is useful for ui elements)
	else:
		var frames_to_next_update = update_frequency-frames_since_last_update
		var proportion_to_next_update =\
				clamp(frames_since_last_update/frames_to_next_update, 0.0, 1.0)
		emit_signal("update_not_ready",
				frames_to_next_update, proportion_to_next_update)
	#
	# reticule handling
	# (checked during RETICULE.SHOW_ON_ACTIVATION mode)
	if showing_reticule_after_activation:
		frames_since_reticule_shown += arg_delta
		if frames_since_reticule_shown >= show_reticule_duration:
			frames_since_reticule_shown = 0.0
			showing_reticule_after_activation = false
			_change_targeting_reticule_visibility(false)


##############################################################################

# public methods


func get_target_data_by_selection(arg_return_type: int):
	var potential_target = null
	var potential_target_position = null
	
	# ERR catch
	if not arg_return_type in RETURN_TYPE.values():
		GlobalDebug.log_error(CLASS_SCRIPT_NAME,
				"get_target_data_by_selection",
				"return type argument invalid")
	
	# selection mode determines available return types
	# set selection mode to SELECTION.NONE to disable targeter
	match selection_mode:
		# get mouse pos
		# mouse look cannot return node references
		SELECTION.MOUSE_LOOK:
#			potential_target_position = get_local_mouse_position()
			potential_target_position = get_global_mouse_position()
		
		# by custom method
		# selector methods can return node ref or global position
		SELECTION.SELECTOR_METHOD:
			if selector_method != null:
				if has_method(selector_method):
					# 'selector returns' export allows for specifying the
					# return value of the selector method
					# if the chosen method does not return the specified type,
					# the target ref or position will be null
					if selector_returns == RETURN_TYPE.NODE_REFERENCE:
						potential_target = call(selector_method)
					if selector_returns == RETURN_TYPE.GLOBAL_POSITION:
						potential_target_position = call(selector_method)
	
	# if potential target is null, cannot return a node ref even if asked for
	if potential_target is Node2D:
		if arg_return_type == RETURN_TYPE.NODE_REFERENCE:
				return potential_target
		# if not returning node reference we are returning position
		else:
			potential_target_position = potential_target.global_position
	
	# if no potential target is set (such as in the case of mouse look
	# selection) then the potential_target_position is set elsewhere
	if potential_target_position is Vector2:
		if arg_return_type == RETURN_TYPE.GLOBAL_POSITION:
				return potential_target_position
	
	# if no valid output then
	# catchall end statement
	return null


##############################################################################

# private methods


# attempt to establish the targeting reticule sprite
func _attempt_to_set_targeting_reticule():
	# ERR checking
	if path_to_reticule_sprite == null:
		return
	var get_potential_reticule = get_node_or_null(path_to_reticule_sprite)
	if get_potential_reticule == null:
		if CLASS_VERBOSE_LOGGING:
			GlobalDebug.log_error(CLASS_SCRIPT_NAME, "path_to_reticule_sprite",
					"reticule sprite path invalid")
		return
	if get_potential_reticule is Sprite:
		targeting_reticule_node = get_potential_reticule
		if reticule_mode == RETICULE.SHOW_ALWAYS:
			_change_targeting_reticule_visibility(true)
		elif reticule_mode == RETICULE.NEVER_SHOW:
			_change_targeting_reticule_visibility(false)


# some targeting styles need reticule preconfiguration
# maybe change to setter?
func _change_targeting_reticule_visibility(arg_show: bool = false):
	# setup failure, this will be false if parent didn't accept signal
	# connections on targeter enter_tree, or parent wasn't activationController
	if not is_reticule_setup:
		return
	if targeting_reticule_node != null:
		targeting_reticule_node.visible = arg_show
		emit_signal("change_reticule_visibility", arg_show)


# sample valid method for SELECTION.AUTOMATIC
# compares global_positions of node2D within the target_groupstring to find
# the closest to the abilityTargeter. In order for the abilityTargeter to
# accurately represent the position of the parent entity, make sure it is
# a child node of the entity.
# method returns a node2D or node2D extended node if it finds a target
# method returns null if no valid target
func _get_nearest():
	var get_target_group = get_tree().get_nodes_in_group(target_groupstring)
	if get_target_group.empty():
		return null
	# if target group exists, check distances
	var closest_target: Node2D
	var dist_to_closest_target: float
	var dist_to_potential_target: float
	# loop through target group
	# gather distances but only remember the closest node
	for potential_target_node in get_target_group:
		#err handling, type check
		if not (potential_target_node is Node2D):
			continue
		# if closest_target doesn't exist, first target is closest
		if closest_target == null:
			closest_target = potential_target_node
			dist_to_closest_target =\
					closest_target.global_position.distance_to(global_position)
		else:
			# get potential target distance for comparison
			dist_to_potential_target =\
					potential_target_node.global_position.distance_to(
					global_position)
			# new closest target
			if dist_to_closest_target < dist_to_potential_target:
				closest_target = potential_target_node
				dist_to_closest_target =\
						closest_target.global_position.distance_to(\
						global_position)
	# retun the globpos of the chosen target
	return closest_target


func _show_reticule_on_activation():
	GlobalDebug.log_success(CLASS_VERBOSE_LOGGING, CLASS_SCRIPT_NAME,
			"_show_reticule_on_activation", "signal received")
	if reticule_mode == RETICULE.SHOW_ON_ACTIVATION:
		frames_since_reticule_shown = 0.0
		_change_targeting_reticule_visibility(true)
		showing_reticule_after_activation = true


# activation controller INPUT_CONFIRMED_PRESS or INPUT_CONFIRMED_HOLD
func _show_reticule_on_targeting(target_state: bool):
	GlobalDebug.log_success(CLASS_VERBOSE_LOGGING, CLASS_SCRIPT_NAME,
			"_show_reticule_on_targeting", "signal received")
	self.is_targeting_active = target_state


#//TODO test the tree exit connection
func _target_clear(arg_target):
	if arg_target is Node2D:
		_target_reference_update(arg_target, true)


# if argument for is_cleared parameter is true, the current target will
# be removed and signal connections updated; if left to default of false
# this method will attempt to set the current target to the argument arg_target
func _target_reference_update(
			arg_target: Node2D,
			arg_is_cleared: bool = false):
	# attempt to add target
	if not arg_is_cleared:
		# target must be in scene tree to be valid
		if arg_target.is_inside_tree():
			# connect target to target_clear method
			# output error if signal doesn't exist and fails to be added
			if (GlobalFunc.confirm_signal(false,
					arg_target, self, "tree_exiting", "_target_clear",
					[arg_target]) == false):
				GlobalDebug.log_error(CLASS_SCRIPT_NAME,
						"_target_reference_update",
						"unable to remove signals to existing target")
			else:
				current_target = arg_target
	# attempt to remove target
	else:
		# removed connection of target to target_clear method
		# output error if signal exists and fails to be removed
		if (GlobalFunc.confirm_signal(false,
				arg_target, self, "tree_exiting", "_target_clear")\
				== false):
			GlobalDebug.log_error(CLASS_SCRIPT_NAME,
					"_target_reference_update",
					"unable to remove signals to existing target")
		# clear target
		current_target = null

