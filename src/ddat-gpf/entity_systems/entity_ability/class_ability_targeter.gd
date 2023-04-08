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

#//TODO - is this unused now?
# the target data to gather and update
enum RETURN_TYPE {
	NODE_REFERENCE,
	GLOBAL_POSITION,
}

# targeters can output different target properties
# the selection enums determine how, if at all, the targeter finds a property
# 'SELECTION_NODE' is how a targeter chooses a target (a node reference)
# SELECTION_NODE should be used by abilities that wish to affect, or target
# toward the position (or direction), a specific game entity
# NONE - no node reference is tracked, current_target will always be null
# CUSTOM_METHOD - the selector_method is used to get a node reference
enum SELECTION_NODE {
	NONE,
	CUSTOM_METHOD,
	}
# 'SELECTION_POSITION' is how a targeter chooses a position to target an
# ability toward
# SELECTION_POSITION should be used by abilities that just wish to target
# a specific location or direction relative to the ability owner
# NONE - no node reference is tracked, current_target_position is always null
# MOUSE_LOOK - tracks the global_position of the mouse cursor
# CUSTOM_METHOD - the selector_method is used to get a vector2 position
#	(if the method returns a node reference, the global_position of that
#	node will be used as the position output)
enum SELECTION_POSITION {
	NONE,
	MOUSE_LOOK,
	CUSTOM_METHOD,
	}

#//TODO
#replace SELECTION
#replace SELECTOR_METHOD,

# when to show the ability's relevant targeting reticule
# SHOW_IMMEDIATELY - targeter sets reticule visible then never adjusts it
# SHOW_ON_ACTIVATION - targeter sets reticule visible when it recieves the
#	'activate_ability' signal from an activation controller parent (this is
#	automatically configured), then sets it invisible after a brief period
#	(see the 'show_reticule_duration' property)
# SHOW_ON_TARGETING - targeter sets reticule visible or invisible when it
#	recieves the 'input_confirming' signal from an activation controller parent
#	(this is automatically configured), based on the included true/false arg.
# DO_NOT_SHOW - targeter sets reticule invisible then never adjusts it
enum RETICULE {
	SHOW_IMMEDIATELY,
	SHOW_ON_ACTIVATION,
	SHOW_ON_TARGETING,
	DO_NOT_SHOW,
	}

# for developer logging only (see ddat-gpf.core.GlobalDebug)
# disable verbose_logging when finished to prevent logspam
const CLASS_VERBOSE_LOGGING := false
const CLASS_SCRIPT_NAME := "ActivationController"

# toggles for which properties you wish the targeter to output by signal
# 'output_target_reference' -> emit signal 'update_target_reference'
export(bool) var output_target_reference := true
# 'output_target_position' -> emit signal 'update_target_position'
export(bool) var output_target_position := true

# for selector methods that wish use a node group to select their targets
# if utilising, remember to assign enemies to the group
# enemies can be assigned on _ready calls, when entering a specific collision
# area around the player, or when entering the screen (with visibility
# notifiers), to name a few ways.
# developers should be aware that custom selector methods and broad target
# groups (e.g. if all enemies are all in the group, there are many enemies,
# and the selector method frequently searches the group) have the potential
# for lag
export(String) var target_groupstring := "groupstring_enemy"

# the target selection mode for nodes
# see the SELECTION_NODE enum for more details
export(SELECTION_NODE) var target_node_selection := SELECTION_NODE.NONE
# the target selection mode for nodes
# see the SELECTION_POSITION enum for more details
export(SELECTION_POSITION) var target_position_selection := SELECTION_POSITION.NONE

# the method name of any custom selector method written in an extended
# targeter class; defaults to the sample 'get_closest_target' method included
# if the custom selector method returns a vector2 value, it can only be used
# if target_position_selection is set to SELECTION_POSITION.CUSTOM_METHOD
# if the custom selector method returns a node reference value, it can be used
# for the above and if target_node_selection is set to SELECTION_NODE.CUSTOM_METHOD
# (the node reference's global_position will be used as the targeter's
# current_target_position property)
export(String) var selector_method := "get_closest_target"

# how many frames between updating target
# this is not how frequently the target collects data about their target or
# who to target, but rather how often they pass that data along
export(float, 0.0, 10.0) var update_frequency := 0.5

# the active targeting reticule mode, see RETICULE
export(RETICULE) var reticule_mode := RETICULE.SHOW_IMMEDIATELY

# path to a sprite that displays as the targeting reticule for this ability
# if no path is set the reticule_mode property will default to
# RETICULE.DO_NOT_SHOW, and targeting reticules will be ignored
export(NodePath) var path_to_reticule_sprite

# duration to show the reticule on ActivationController activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
export(float, 0.0, 60.0) var show_reticule_duration := 0.4

# delta accumulation since last signal update
var frames_since_last_update := 0.0

# stored node reference of last target; should always be a node2D (or extended
# class), or null
var current_target
# stored position of last target; if current_target is set this will default
# to the global_position property of the current_target
var current_target_position

# tracking whether the reticule has been temporarily shown after activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
var showing_reticule_after_activation := false
# delta accumulation since targeting reticule was set visible
# used to track when to hide the reticule again
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
var frames_since_reticule_shown := 0.0

# reference to targeting reticule sprite, if unset will disable any reticule
# based methods such as _set_reticule_visibility
var targeting_reticule_node: Sprite = null

# property set when reticule signals and parent exit condition are connected,
# and the reticule node type is validated
var is_reticule_setup := false

##############################################################################

# setters and getters


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
				"activate_ability", "_on_activation_show_reticule")
		signal_connection_state_2 = GlobalFunc.confirm_signal(\
				true, parent_node, self,
				"input_confirming", "_on_targeting_set_reticule")
	is_reticule_setup =\
			(signal_connection_state_1 and signal_connection_state_2)


# called on node entering the tree for the first time only
func _ready():
	# reticule handling
	_setup_visibility()


# delta is time since last frame
func _process(arg_delta):
	# for an update to go ahead the frequency must be nil or enough time
	# must have passed (accumulated delta) to exceed the update frequency
	# (update frequency is measured in frames)
	var update_allowed := (update_frequency == 0.0)
	if not update_allowed:
		# external updates (output) have a forced delay or lag
		# set the 'update_frequency' property to nil to disable this
		frames_since_last_update += arg_delta
		if frames_since_last_update >= update_frequency:
			frames_since_last_update -= update_frequency
			update_allowed = true
#//TODO add separate target and position update check timers
# (so target can be set and then position gotten frequently)
	if update_allowed:
		# check the selector method, if specified
		var selector_method_output = _process_selector_method()
		# passed to the target reference and target position processing,
		# is only relevant if one the following is true:
		# (target_node_selection == SELECTION_REFERENCE.CUSTOM_METHOD)
		# (target_position_selection == SELECTION_POSITION.CUSTOM_METHOD)
		# prevents calculating the selector method twice
		_process_current_target_reference(selector_method_output)
		_process_current_target_position(selector_method_output)
#		_process_internal_target_data()
		_process_output_target_data()
	
	# if update doesn't happen this frame, pass along how long it will be
	# until the next target update (this is useful for ui elements)
	else:
		var frames_to_next_update = update_frequency-frames_since_last_update
		var proportion_to_next_update =\
				clamp(frames_since_last_update/frames_to_next_update, 0.0, 1.0)
		emit_signal("update_not_ready",
				frames_to_next_update, proportion_to_next_update)
	
	# reticule handling
	_process_reticule_handling(arg_delta)


# custom target selection methods can be added to extended targeter classes
# and specified (method name as string) as part of the selector_method export
# if the method is valid the output will be returned to the main _process
# call and checked against process subfunctions for target reference and
# position; the type will not be checked as part of the output of this method
# (this method only calls the selector method and returns the result)
func _process_selector_method():
	var selector_return_value = null
	# skip if selector method left unset
	if selector_method != "":
		# ERR check
		if not has_method(selector_method):
			GlobalDebug.log_error(CLASS_SCRIPT_NAME,
					"_process_selector_method",
					"invalid selector string provided, method not found")
		if selector_method != null:
			if has_method(selector_method):
				selector_return_value = call(selector_method)
	
	# no type checking at return point, this could be null
	return selector_return_value


# if the selector method doesn't return a node2d, but target_node_selection is
# set to SELECTION_NODE.CUSTOM_METHOD, current_target will be set to null
func _process_current_target_reference(arg_selector_output):
	# see SELECTION_NODE enum for more detail
	match target_node_selection:
		SELECTION_NODE.NONE:
			current_target = null
		SELECTION_NODE.CUSTOM_METHOD:
			if arg_selector_output is Node2D:
				_set_new_current_target(arg_selector_output)
			else:
				current_target = null

# if target_position_selection is set to SELECTION_POSITION.CUSTOM_METHOD and the
# selector_method doesn't return a node2d or vector2, the property
# 'current_target_position' will be set null
# if the selector_method instead returns a node2d the current_target_position
# will be set to the global_position property of the returned node2d
func _process_current_target_position(arg_selector_output):
	# see SELECTION_POSITION enum for more detail
	match target_position_selection:
		SELECTION_POSITION.NONE:
			current_target_position = null
		SELECTION_POSITION.MOUSE_LOOK:
			current_target_position = get_global_mouse_position()
		SELECTION_POSITION.CUSTOM_METHOD:
			if arg_selector_output is Node2D:
				current_target_position = arg_selector_output.global_position
			elif arg_selector_output is Vector2:
				current_target_position = arg_selector_output
			else:
				current_target_position = null

#
## this method uses the target selection mode to update the current_target
## and current_target_position properties
## the targeter tracks this data even when not outputting it
#func _process_internal_target_data():
#	# selection mode determines available return types
#	# set selection mode to SELECTION.NONE to disable targeter
#	match selection_mode:
#		# get mouse pos
#		# mouse look cannot return node references
#		# mouse look is a lightweight selection method and can be called
#		# every _process loop
#		SELECTION.MOUSE_LOOK:
##			potential_target_position = get_local_mouse_position()
#			current_target_position = get_global_mouse_position()
#
#		# by custom method
#		# selector methods can return node ref or global position
#		# warning: if the selector method does not return the expected type
#		# it will unset the current target and/or current target position by
#		# setting the property/properties to null
#		# selector methods can be intensive to call every _process loop and
#		# developers are encouraged to consider increasing the
#		# 'selection_frequency' property if they encounter any lag
#		SELECTION.SELECTOR_METHOD:
#			if selector_method != null:
#				if has_method(selector_method):
#					# 'selector returns' export allows for specifying the
#					# return value of the selector method
#					if selector_returns == RETURN_TYPE.NODE_REFERENCE:
#						current_target = call(selector_method)
#					if selector_returns == RETURN_TYPE.GLOBAL_POSITION:
#						current_target_position = call(selector_method)
#

# method to handle signals that pass along target properties, based on the
# export selections made on the targeter
func _process_output_target_data():
	# multiple output methods exist, even though a node reference is enough to get
	# get all properties, because certain selector methods may collect less data
	# about a potential target and certain abilities may only require a position
	# or specific direction to activate. It is up to the developer to determine
	# the needs of each ability they design.
	if output_target_reference:
		if current_target != null:
				emit_signal("update_target_reference", current_target)
		
	# if a target reference is set it will override position-only values
	# to use the global_position property of the target reference
	if output_target_position:
		if current_target_position != null:
			emit_signal("update_target_position", current_target_position)


func _process_reticule_handling(arg_delta):
	# reticule handling
	# (checked during RETICULE.SHOW_ON_ACTIVATION mode)
	if showing_reticule_after_activation:
		frames_since_reticule_shown += arg_delta
		if frames_since_reticule_shown >= show_reticule_duration:
			frames_since_reticule_shown = 0.0
			showing_reticule_after_activation = false
			_set_reticule_visibility(false)


##############################################################################

# public methods


# (the following method is included as an example selector method)
# compares global_positions of node2D within the target_groupstring to find
# the closest to the abilityTargeter. In order for the abilityTargeter to
# accurately represent the position of the parent entity, make sure it is
# a child node of the entity.
# method returns a node2D or node2D extended node if it finds a target
# method returns null if no valid target
func get_closest_target():
	var potential_target_group = get_target_group()
	if potential_target_group.empty():
		return null
	# if target group exists, check distances
	var closest_target: Node2D
	var dist_to_closest_target: float
	var dist_to_potential_target: float
	# loop through target group
	# gather distances but only remember the closest node
	for potential_target_node in potential_target_group:
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


# by default this is equivalent to get_nodes_in_group(target_groupstring),
# however certain targeting options allow discounting specific targets that
# would otherwise be considered (such as within a specific proximity) and
# pruning the target group for these now-invalid targets
func get_target_group() -> Array:
	var potential_targets := []
	if target_groupstring != "":
		potential_targets = get_tree().get_nodes_in_group(target_groupstring)
	
	# developers can shadow this method in extended targeters to modify how
	# these groups are passed along. Shadow the method (example below) but
	# call the shadowed method as the first operation to get the group as-is.
	# e.g.
	#	func get_target_group() -> Array:
	#		# get contents of parent method
	#		var potential_targets = .get_target_group()
	#		# do own stuff to group
	
	#//TODO
	# future exclusionary or pruning behaviour can be written here
	
	return potential_targets


##############################################################################

# private methods


# removes the current target reference on target exiting tree, to prevent
# a potential null reference error when getting target properties
func _clear_current_target(arg_target):
	if arg_target is Node2D:
		_set_new_current_target(arg_target, true)


# if argument for is_cleared parameter is true, the current target will
# be removed and signal connections updated; if left to default of false
# this method will attempt to set the current target to the argument arg_target
func _set_new_current_target(
			arg_target: Node2D,
			arg_is_cleared: bool = false):
	# attempt to add target
	if not arg_is_cleared:
		# target must be in scene tree to be valid
		if arg_target.is_inside_tree():
			# connect target to target_clear method
			# output error if signal doesn't exist and fails to be added
			if (GlobalFunc.confirm_signal(false,
					arg_target, self, "tree_exiting", "_clear_current_target",
					[arg_target]) == false):
				GlobalDebug.log_error(CLASS_SCRIPT_NAME,
						"_set_new_current_target",
						"unable to remove signals to existing target")
			else:
				current_target = arg_target
	# attempt to remove target
	else:
		# removed connection of target to target_clear method
		# output error if signal exists and fails to be removed
		if (GlobalFunc.confirm_signal(false,
				arg_target, self, "tree_exiting", "_clear_current_target")\
				== false):
			GlobalDebug.log_error(CLASS_SCRIPT_NAME,
					"_set_new_current_target",
					"unable to remove signals to existing target")
		# clear target
		current_target = null


# some targeting styles need reticule preconfiguration
# maybe change to setter?
func _set_reticule_visibility(arg_show: bool = false):
	# setup failure, this will be false if parent didn't accept signal
	# connections on targeter enter_tree, or parent wasn't activationController
	if not is_reticule_setup:
		return
	if targeting_reticule_node != null:
		targeting_reticule_node.visible = arg_show
		emit_signal("change_reticule_visibility", arg_show)


# attempt to establish the targeting reticule sprite
func _setup_visibility():
	# ERR checking
	if path_to_reticule_sprite == null:
		return
	var get_potential_reticule = get_node_or_null(path_to_reticule_sprite)
	if get_potential_reticule == null:
		reticule_mode = RETICULE.DO_NOT_SHOW
		if CLASS_VERBOSE_LOGGING:
			GlobalDebug.log_error(CLASS_SCRIPT_NAME, "path_to_reticule_sprite",
					"reticule sprite path invalid")
		return
	if get_potential_reticule is Sprite:
		targeting_reticule_node = get_potential_reticule
		if reticule_mode == RETICULE.SHOW_IMMEDIATELY:
			_set_reticule_visibility(true)
		elif reticule_mode == RETICULE.DO_NOT_SHOW:
			_set_reticule_visibility(false)



##############################################################################

# private methods on signal receipt


func _on_activation_show_reticule():
	GlobalDebug.log_success(CLASS_VERBOSE_LOGGING, CLASS_SCRIPT_NAME,
			"_on_activation_show_reticule", "signal received")
	if reticule_mode == RETICULE.SHOW_ON_ACTIVATION:
		frames_since_reticule_shown = 0.0
		_set_reticule_visibility(true)
		showing_reticule_after_activation = true


# activation controller INPUT_CONFIRMED_PRESS or INPUT_CONFIRMED_HOLD
func _on_targeting_set_reticule(target_state: bool):
	GlobalDebug.log_success(CLASS_VERBOSE_LOGGING, CLASS_SCRIPT_NAME,
			"_on_targeting_set_reticule", "signal received")
	if reticule_mode == RETICULE.SHOW_ON_TARGETING:
		_set_reticule_visibility(target_state)

