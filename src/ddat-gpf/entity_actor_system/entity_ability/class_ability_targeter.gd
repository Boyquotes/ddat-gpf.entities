extends Area2D

class_name EntityAbilityTargeter

##############################################################################

# Use an EntityAbilityTargeter in conjunction with an EntityAbilityController
# to get the appropriate target for an ability.

#//TODO
# clean documentation

#// TODO - area2D/collider based target selection
#//see below
## whether targets are anything within the selection_collider shape2D
#export(bool) var selection_use_collider:bool = false
## if above flag is set, this is the area around
## setting this automatically generates an area2D child beneath this node
#export(Shape2D) var selection_collider: Shape2D
## whether 
#export(bool) var selection_use_group:bool = false
# selection_invert_collider ~ targets within collision are exempt from
#	groupstring selection

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# pass along the current position of the target
signal update_target(target_position)
# if using a non-sprite reticule you can connect this signal to the node
# for when to show the reticule
signal change_reticule_visibility(is_visible)


# how to target the ability during target selection state
# when utilising an automatic (prefix AUTO_) target selection mode the position
# of this node is considered for distance to the target, so make sure your
# entityAbilityController nodes are scene tree children of your entities.
#
# NONE
# MOUSE_LOOK
# AUTOMATIC - automatic requires a specified target logic to be set on the
#	'selector_method' property. This should be a method that returns a vector
#	toward a Node2D; extend this class to add your own.
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
const CLASS_VERBOSE_LOGGING := true
const CLASS_SCRIPT_NAME := "ActivationController"

# the active targeting reticule mode, see RETICULE
export(RETICULE) var reticule_mode =\
		RETICULE.SHOW_ALWAYS

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

# how many frames between updating target
# lower values may cause lag with large numbers of entityAbilityTargeters
export(float, 0.0, 10.0) var update_frequency := 0.5

# path to a sprite that displays as the targeting reticule for this ability
# if no path is set the chosen_targeting_reticule property will default to
# RETICULE.NEVER_SHOW, and targeting reticules will be ignored
export(NodePath) var path_to_reticule_sprite

# duration to show the reticule on ActivationController activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
export(float, 0.0, 60.0) var show_reticule_duration := 0.4

# delta accumulation since last signal update
var frames_since_last_update := 0.0

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

##############################################################################

# setters and getters

func _set_is_targeting_active(arg_value):
	is_targeting_active = arg_value
	if reticule_mode == RETICULE.SHOW_ON_TARGETING:
		_change_targeting_reticule_visibility(arg_value)


##############################################################################

# virtual methods


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
		current_target_position = get_target_position_by_selection()
		# if target was found, update all
		# can assume in receipient nodes that this passed param is vec2
		if current_target_position != null:
			# if it isn't null should only ever pass a vec2
			assert(current_target_position is Vector2)
			emit_signal("update_target", current_target_position)
	#
	# reticule handling
	# (checked during RETICULE.SHOW_ON_ACTIVATION mode)
	if showing_reticule_after_activation:
		frames_since_reticule_shown += arg_delta
		if frames_since_reticule_shown >= show_reticule_duration:
			frames_since_reticule_shown = 0.0
			_change_targeting_reticule_visibility(false)


##############################################################################

# public methods


# should return vector2 if target is found, or null if no target was found
# methods for SELECTION.SELECTOR_METHOD should return a vector2 or null as per
func get_target_position_by_selection():
	var potential_target_position = null
	
	match selection_mode:
		# get mouse pos
		SELECTION.MOUSE_LOOK:
#			potential_target_position = get_local_mouse_position()
			potential_target_position = get_global_mouse_position()
		
		# to add
		SELECTION.SELECTOR_METHOD:
			if selector_method != null:
				if has_method(selector_method):
					potential_target_position = call(selector_method)
	
	if potential_target_position is Vector2:
		return potential_target_position
#		return global_position.direction_to(potential_target_position)
	else:
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
	return closest_target.global_position


func _show_reticule_on_activation():
		if reticule_mode == RETICULE.SHOW_ON_ACTIVATION:
			_change_targeting_reticule_visibility(true)
			showing_reticule_after_activation = true


# activation controller INPUT_CONFIRMED_PRESS or INPUT_CONFIRMED_HOLD
func _show_reticule_on_targeting(target_state: bool):
	self.is_targeting_active = target_state

