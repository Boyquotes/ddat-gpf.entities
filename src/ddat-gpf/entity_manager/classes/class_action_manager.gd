extends Action

class_name ActionManager

##############################################################################
#
# an ActionManager should have actionEffect nodes as children, and
# actionCondition nodes as grandchildren (nested beneath actionEffects).
# the actionManager then manages calling these effects when the conditions
# are evaluating correctly.

#//TODO
# add actionGroup behaviour
# update docs for actionGroups
# actionCondition grandchildren signal setup

##############################################################################

#//TODO
# [ActorAction system 0.1]
# ActionGroups are excluded in this initial implementation.
# Instead the ActionManager directly manages actions and will perform every
# action in sequence.

# [ActorAction system 0.1.1]
# actionManager may not even be necessary
# actions should flag themselves as ready any tick their conditions are met
# actions should have a 'do every x ticks' property (default/min 1)
# actions should have a target they're init with (defaults to parent if null)
#
# if priority system is needed, then an actionMgr could do it
# actionMgr could have the target in that case


##############################################################################

# for passing to error logging
const CLASS_NAME := "ActionManager"
# for developer use, enable if making changes
const CLASS_VERBOSE_LOGGING := true

# the action resolution step is the length of time before calling the
# actionEfffect nodes tied to this actionManager
# actionConditions will evaluate at normal scene tree speed so their states
# must be true when the action resolution step period comes around for the
# associated action to actually fire
#
# for simple actions you can disable the action_resolution_step_period by
# setting it to nil or negative, and instead call actions by connecting the
# actionCondition signal 'condition_state_now_valid' to the actionEffect
# method 'do()'.

# defaults to a value of once per frame (1.00)
# set to higher values to decrease (2.00 = attempts on every second frame)
# set to lower values to increase (0.5 = attempts twice per frame)
export(float) var action_resolution_step_period := 1.00

# time since last frame (tracked via _process(), set 0 on action resolution)
# will be set to nil(0) again AFTER actions have attempted to resolve
var time_since_last_action_resolution = 0

# record of all actionEffect nodes nested under this node
var all_actions = []
# dict where key is actionEffects
var actions_by_condition = {}

# actions that have not been resolved this action resolution step
#var pending_actions = []

# don't try to resolve actions on next process loop/s if prevous started to
var is_resolving_actions := false

# are signals setup for this node to function
# normal behaviour is suspended if this isn't true
var is_setup_correctly := false

##############################################################################

#//TODO
#	connect signal to actionEffect children added to the tree (and on init)
# 	to track when actionCondition grandchildren are added/removed (and can
#	update actions_by_condition)
#	behaviour is out of scope for initial setuo-by-editor-only implmentation
#
# add back the following method:
#
# method to remove an actionCondition from associated array of an actionEffect
#func _actions_by_condition_erase_value(
#		arg_action_effect_key: ActionEffect,
#		arg_action_condition_value: ActionCondition):
#	if actions_by_condition.has(arg_action_effect_key):
#		var get_entry_value = actions_by_condition[arg_action_effect_key]
#		if typeof(get_entry_value) == TYPE_ARRAY:
#			arg_action_condition_value.erase(arg_action_condition_value)

##############################################################################

# virtual ready


# Called when the node enters the scene tree for the first time.
func _ready():
	# get all current actionEffects setup correctly
	_initialise_all_actions()
#	pending_actions = all_actions
	_initialise_actions_by_condition()
	# validate setup signals
	var child_signal_1_setup = self.connect(
			"child_entered_tree", self, "_on_child_entered_tree")
	var child_signal_2_setup = self.connect(
			"child_exiting_tree", self, "_on_child_exiting_tree")
	if child_signal_1_setup == OK\
	and child_signal_2_setup == OK:
		is_setup_correctly = true

##############################################################################

# virtual process


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_since_last_action_resolution += delta
	if time_since_last_action_resolution >= action_resolution_step_period:
		_attempt_resolve_all_actions()


##############################################################################

# private methods


func _attempt_resolve_all_actions():
	# don't double down
	if is_resolving_actions:
		return
	# block attempts to resolve more actions
	is_resolving_actions = true
	# do actions
	for action_node in all_actions:
		if action_node is ActionEffect:
			if _is_action_valid(action_node):
				action_node.do()
	
	# reset pending action list, action resolution step check
#	pending_actions = all_actions
	time_since_last_action_resolution = 0
	# ready to check again
	is_resolving_actions = false


func _is_action_valid(arg_action: ActionEffect) -> bool:
	# check hasn't hit 'do action this many times' limit
	if arg_action.do_x <= arg_action.done\
	and arg_action.do_x >= 0:
		print("1")
		return false
	
	# check conditions all evaluate to true
	var get_conditions: Array
	if actions_by_condition.has(arg_action):
		get_conditions = actions_by_condition[arg_action]
	for condition_node in get_conditions:
		if condition_node is ActionCondition:
			if not condition_node.is_valid():
				return false
	
	# all checks passed
	return true


func _actions_by_condition_add_key(arg_action_effect_node: ActionEffect):
	# set prospective dict entry value to an empty array
	var get_condition_grandchildren: Array = []
	# get if any children
	var get_action_children = arg_action_effect_node.get_children()
	# if no children, skip next step
	if not get_action_children.empty():
		# otherwise fill the empty array
		for grandchild_action_condition_node in get_action_children:
			if grandchild_action_condition_node is ActionCondition:
				get_condition_grandchildren.append(\
						grandchild_action_condition_node)
	# set key(actionEffect node) and value(array of actionCondition nodes)
	actions_by_condition[arg_action_effect_node] = get_condition_grandchildren


# method to manage removing actionEffects from actions_by_condition dict
func _actions_by_condition_erase_key(arg_action_effect: ActionEffect):
	# only if it is in the dict do we remove it
	if actions_by_condition.has(arg_action_effect):
		actions_by_condition.erase(arg_action_effect)


##############################################################################

# private methods, setup


func _initialise_all_actions():
	for child_node in get_children():
		if child_node is ActionEffect:
			all_actions.append(child_node)


func _initialise_actions_by_condition():
	# search children conditions of each action effect
	for child_action_node in all_actions:
		if child_action_node is ActionEffect:
			_actions_by_condition_add_key(child_action_node)


##############################################################################

# private, on signal receipt


func _on_child_entered_tree(arg_entering_node: Node):
	if arg_entering_node is ActionEffect:
		_actions_by_condition_add_key(arg_entering_node)


func _on_child_exiting_tree(arg_exiting_node: Node):
	if arg_exiting_node is ActionEffect:
		_actions_by_condition_erase_key(arg_exiting_node)

