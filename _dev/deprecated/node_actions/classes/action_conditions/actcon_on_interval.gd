extends ActionCondition

#class_name ActionConditionOnInterval

##############################################################################
#
# An ActionCondition where the condition is true every x seconds for x seconds.
# 
# Has two timers as child nodes, an interval timer and an active period timer.
# The two timers fire in sequence, with the interval timer elapsing first,
# and the active period timer elapsing second. On timeout of the active
# period timer the interval timer will begin again, repeating the cycle.
#
# Whilst the active period timer runs, this condition evaluates to true.

#//legacy tod0
# need unit testing for growth property behaviour and all signals

##############################################################################

# this node sets up some required child nodes after readying itself, so you
# should never rely on it immediately after it joins the scene tree.
# Instead wait for this signal to be emitted.
# (more detail see 'timer_nodes_are_set' & '_initialise_timer_nodes()')
signal condition_ready()

# these signals are emitted whenever a new interval starts or ends
# parent action_condition class signals are used to manage activity periods
signal interval_started()
signal interval_ended()
# if maximum_intervals is set non-negative, this is emitted when total
# intervals meets the allowed maximum intervals
signal maximum_intervals_reached()

#07. constants
# for passing to error logging
const SCRIPT_NAME := "ActionConditionOnInterval"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true

# the time between intervals
# if set to nil or negative (by export or change over time) this condition
# will never set state to true
export(float) var interval_length := 0.0
# the period for which the state is set true
# if set to nil or negative the state condition will be set and immediately
# unset, then the next interval will start if nil, or the condition will
# halt completely if negative
export(float) var activity_length := 0.0

# the number of times a new interval can start, updated on interval conclusion
# if set negative (default) the interval can repeat indefinitely
export(int) var maximum_intervals := -1

# this is analogous to the timer autostart property, except for the
# ActionConditionOnInterval waiting until it is called by an ActionManager
# before starting.
# if this is set to false you will need to call the start_interval() method
# from elsewhere in your property to begin the interval behaviour.
export(bool) var interval_can_loop := true

# you can set interval and active period to automatically change over time
# with the following two variables. Consider your usage of these settings
# as they will cause dramatic shifts in behaviour over time.

# the change in interval length after an interval concludes
# if set negative the interval will shrink, positive it will grow over time
# leave nil to disable this behaviour
export(float) var interval_growth := 0.0
# the change active state duration, updated when an active state period ends
# if set negative the duration will shrink, positive it will grow over time
# leave nil to disable this behaviour
export(float) var activity_growth := 0.0

# the number of times an interval has concluded
# is compared against maximum_intervals if that export is not negative
# note: the following active period will still run after the final interval
var total_intervals := 0

# basically (active_period_timer_node.is_stopped() == false)
var is_active_period := false setget _set_is_active_period

# the timer node children (see below) are required for its behaviour, so if
# they have not been instantiated and added as children, suspend functionality.
# Because these nodes need to be set up after readying this node, you should
# never rely on ActionConditionOnInterval behaviour in the first few frames.
var timer_nodes_are_set := false setget _set_timer_nodes_are_set

onready var interval_timer_node: Timer
onready var active_period_timer_node: Timer

##############################################################################

# setters and getters


func _set_is_active_period(arg_value):
	is_active_period = arg_value
	self.condition_state = is_active_period


# setter that sends the signal this condition is ready
func _set_timer_nodes_are_set(arg_value):
	timer_nodes_are_set = arg_value
	if timer_nodes_are_set == true:
		# set actually ready
		condition_ready = true
		emit_signal("condition_ready")
		if interval_can_loop == true:
			start_interval()


##############################################################################

# virtual


# on entering tree is not actually ready, so get ready
func _ready():
	condition_ready = false
	_initialise_timer_nodes()


##############################################################################

# public


func start_interval():
	
	# ERR check
	if timer_nodes_are_set != true:
		return
	if maximum_intervals >= total_intervals\
	and maximum_intervals >= 0:
		return
	
	if interval_length <= 0.0:
		return
	
	interval_timer_node.wait_time = interval_length
	interval_timer_node.start()
	emit_signal("interval_started")


func start_active_period():
	# ERR check
	if timer_nodes_are_set != true:
		return
	self.is_active_period = true
	# must be positive length to set and start timer
	if activity_length > 0.0:
		active_period_timer_node.wait_time = activity_length
		active_period_timer_node.start()
	# if nil length, do once and continue
	elif activity_length == 0.0:
		_on_active_period_ended()
		self.is_active_period = false
	# if less than nil length, do once and stop
	else:
		self.is_active_period = false


##############################################################################

# private


func _on_interval_ended():
	emit_signal("interval_ended")
	total_intervals += 1
	if total_intervals == maximum_intervals:
		emit_signal("maximum_intervals_reached")
	# set growth to nil to disable, negative will shrink length over time
	# timer updates wait time whenever called
	interval_length += interval_growth
	start_active_period()


func _on_active_period_ended():
	self.is_active_period = false
	# set growth to nil to disable, negative will shrink length over time
	# timer updates wait time whenever called
	activity_length += activity_growth
	# if intervals autolooping wasn't disabled (default), run next interval
	if interval_can_loop == true:
		start_interval()


# both timers are instantiated and their initial properties set here
# neither should run automatically or loop, as their behaviour is controlled
# within the code of the ActionConditionOnInterval script.
func _initialise_timer_nodes():
	# timer 1
	interval_timer_node = Timer.new()
	interval_timer_node.autostart = false
	interval_timer_node.one_shot = true
	self.call_deferred("add_child", interval_timer_node)
	yield(interval_timer_node, "ready")
	# timer 2
	active_period_timer_node = Timer.new()
	active_period_timer_node.autostart = false
	active_period_timer_node.one_shot = true
	self.call_deferred("add_child", active_period_timer_node)
	yield(active_period_timer_node, "ready")
	
	# validate
	# properties accept timer or null only so if null, setup failed
	if interval_timer_node != null\
	and active_period_timer_node != null:
		# timer was made child
		if interval_timer_node.is_inside_tree()\
		and active_period_timer_node.is_inside_tree():
			# record whether signals are connected
			var t1_signal_connected = interval_timer_node.connect(
					"timeout", self, "_on_interval_ended")
			var t2_signal_connected = active_period_timer_node.connect(
					"timeout", self, "_on_active_period_ended")
			# check if signals were connected
			if t1_signal_connected == OK\
			and t2_signal_connected == OK:
				self.timer_nodes_are_set = true
				# success
				return
	
	# failure
	GlobalDebug.log_error(SCRIPT_NAME, "_initialise_timer_nodes",
			"timers for ActionConditionOnInterval did not initialise.")

