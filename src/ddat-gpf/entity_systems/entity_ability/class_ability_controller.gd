extends ActivationController

class_name AbilityController

##############################################################################

# An AbilityController is an extended ActivationController with finer control
# over when and how an activation can occur. It is designed to provide
# activation conditions for player and enemy abilities, things that might
# have a warmup before activating, a cooldown after activating, or a set
# number of uses before they go on a longer cooldown.

#//TODO
# property for activation controller that prevents activation if ability is
# waiting (i.e. if cooldown is waiting or warmup is going) - perhaps just
# as an abilityController shadowed method?

#//TODO
# need a property that prevents delta accumulation (see below) whilst the
# ability isn't ready (also prevent confirmed_press)
# - INPUT_CONFIRMED_PRESS activation mode allows the priming/initial input
#	even whilst the ability is on warmup/coodlwon
#	same applies for INPUT_CONFIRMED_HOLD, you can start priming a new input
#	same applies for INPUT_MINIMUM_HOLD
#	same applies for ON_INTERVAL
#	if the accumulation triggers activation whilst ability is on cooldown,
#	the activation is discarded - should it queue?

#//TODO/REVIEW
#	warmup and cooldown currently work with INPUT_CONFIRMED_HOLD,
#	INPUT_MINIMUM_HOLD, INPUT_WHILST_HELD < is this desired behaviour?

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# for ability warmup animations
# only emitted if 'ability_warmup' is positive
# warmup_progress is the % of warmup completed
# (this value can for ui elements and animations)
signal ability_warmup_active(warmup_progress)
# for ui elements and ability cooldown animations
# only emitted if 'ability_cooldown' is positive
# cooldown_progress is the % of warmup completed
# (this value can for ui elements and animations)
signal ability_cooldown_active(cooldown_progress)
# indicates that the ability is preparing to fire
# only emitted if 'ability_warmup' is positive
# separate from corresponding 'active' signal for simply getting the first
# frame in which the warmup started without having to check a passed value
# (catches edge cases of frame lag also)
signal ability_warmup_started()
# indicates that the ability is entering cooldown
# only emitted if 'ability_cooldown' is positive
# separate from corresponding 'active' signal for simply getting the first
# frame in which the cooldown started without having to check a passed value
# (catches edge cases of frame lag also)
signal ability_cooldown_started()
# indicates that the ability is about to fire
# only emitted if 'ability_warmup' is positive
signal ability_warmup_finished()
# indicates that the ability can be used again
# only emitted if 'ability_cooldown' is positive
# warning-ignore:unused_signal
signal ability_cooldown_finished()
# emitted alongside the 'activate_ability' signal
# useful for ui elements to track usage remaining
# only emitted if 'max_usages' property is nil or positive
# warning-ignore:unused_signal
signal ability_usage_spent(uses_remaining)
# emitted when a usage is refreshed, for ui elements
# only emitted if 'refresh_usages_time' and 'usages_refresh_amount' are valid
# 'uses_refreshed' value will be equal to 'usages_refresh_amount' unless the
# number of usages to be refreshed would take the usages over the maximum
# warning-ignore:unused_signal
signal ability_usage_refreshed(uses_refreshed)

# signal for indicating an activation would have happened, but a specific
# abilityController condition blocked it activating
# (useful for ui element animations/feedback)
# should pass a specific error code (see 'ACTIVATION_ERROR' enum) as to why
# warning-ignore:unused_signal
signal failed_activation(error_code)

# error codes that should be passed with the 'failed_activation' signal
# ERR_NO_USES_LEFT - ability had no usages remaining on activation call
# ERR_ON_COOLDOWN - ability was on cooldown on activation call
# ERR_ON_WARMUP - ability was already warming up on activation call
enum ACTIVATION_ERROR {
	ERR_NO_USES_LEFT,
	ERR_ON_COOLDOWN,
	ERR_ON_WARMUP,
}

# how the usage refresh properties work
# NEVER - refresh delay and timer counts constantly (default behaviour)
# IN_USE - refresh delay and timer will pause if the ability is in
#	either the warmup or cooldown state
# ON_COOLDOWN - refresh delay and timer pause if ability on cooldown
# ON_WARMUP - refresh delay and timer pause if ability is warming up
# IF_NOT_NIL - refresh timer only starts if all usages have been spent
#	(this setting is best used with a low 'refresh_usages_time' or high
#	'usages_refresh_amount' value)
enum REFRESH_PAUSE {
	NEVER,
	IN_USE,
	ON_COOLDOWN,
	ON_WARMUP,
	IF_NOT_NIL,
	}

# how long (in frames) it takes for the ability to fire
# this applies after input is confirmed by default, and all other input or
# attempted activations are prevented whilst an activation is in the queue
# (applying a long warmup will slow ability resolution)
# note: when considering multiple usage timings, warmup applies on every use
# set nil to disable
export(float, 0.0, 20.0) var ability_warmup = 0.0
# how long (in frames) before the ability can fire again
# attempted activations are prevented whilst cooldown is active
# note: when considering multiple usage timings, cooldown applies on every use
# set nil to disable
export(float, 0.0, 600.0) var ability_cooldown = 0.0

# abilities can have a finite number of uses; each activation consumes a set
# amount of uses and an ability can no longer activate once usages are consumed
# uses can be restored by signal (public method), or on a fixed duration
# (ability usage properties below)

# the chosen refresh setting (see the REFRESH_PAUSE enum for detail)
export(REFRESH_PAUSE) var refresh_pause_mode := REFRESH_PAUSE.NEVER
# max_usages is the total number of uses the ability has
# abilities start at their maximum number of uses by default
# set nil to disable the ability
# set negative to give the ability unlimited uses
export(int, -1, 100) var max_usages = -1
# how many uses of the ability are consumed on each activation
# set nil to prevent the ability consuming uses on activation
export(int, 0, 100) var usages_consumed_on_activation = 1
# how long (in frames) before an ability regains a set number of uses
# set nil to prevent usage refresh
# if current usages >= maximum uses, the refresh timer is not checked
export(float, 0.0, 100.0) var refresh_usages_time = 1.0
# how long (in frames) before the refresh timer begins
# set nil to disable
# the refresh timer provides signal updates for ui elements
# this property is useful if you want a delay for refresh time whenever
# the condition for REFRESH_PAUSE is met
export(float, 0, 10.0) var refresh_delay_time = 0.0
# how many usages are refreshed when the use_refresh_time is exceed
# usages refreshed are capped at maximum usages
# set nil to prevent usage refresh
export(int, 0, 100) var usages_refresh_amount = 1

# ability state trackers
var is_in_cooldown := false
var is_in_warmup := false

# track how long ability state has lasted (for purpose of ending states)
var frames_since_cooldown_started := 0.0
var frames_since_warmup_started := 0.0

# set to max usages on ready
# if negative, usages are infinite
var current_usages := -1

# track whether refresh timer should be counting
var ability_usages_can_refresh := false

# track how long since refresh timer started, for purpose of refreshing usages
var frames_since_refresh_started := 0.0
# track how long since refresh delay started
var frames_since_delay_started := 0.0


##############################################################################

# virtual methods

func _ready():
#	ACTIVATION.INPUT_ACTIVATED
#	ACTIVATION.INPUT_CONFIRMED_HOLD
#	ACTIVATION.INPUT_CONFIRMED_PRESS
#	ACTIVATION.INPUT_TOGGLED
#	ACTIVATION.CONTINUOUS
#	ACTIVATION.ON_INTERVAL
#	ACTIVATION.ON_SIGNAL
	pass
	# need to connect signals?


func _process(arg_delta):
	# accumulate delta trackers
	# ability cooldown
	if is_in_cooldown:
		frames_since_cooldown_started += arg_delta
		# if exceed the cooldown length, end cooldown
		if frames_since_cooldown_started > ability_cooldown:
			change_cooldown_state(false)
		# else, track cooldown
		else:
			# pass along %done for ui elements and animations
			var cooldown_completed = clamp(\
					(frames_since_cooldown_started/ability_cooldown),
					0.0, 1.0)
			emit_signal("ability_cooldown_active", cooldown_completed)
	# ability warmup
	if is_in_warmup:
		frames_since_warmup_started += arg_delta
		# if exceed the warmup length, end warmup
		if frames_since_warmup_started > ability_warmup:
			change_warmup_state(false)
		# else, track warmup
		else:
			# pass along %done for ui elements and animations
			var warmup_completed = clamp(\
					(frames_since_warmup_started/ability_warmup),
					0.0, 1.0)
			emit_signal("ability_warmup_active", warmup_completed)

##############################################################################

# public methods


# shadowed from activation controller to check conditions before activation
# ability controller will check warmup, cooldown, and usages, before it
# actually activates the ability
func activate():
	# check conditions before activating
	if not _is_warmup_active()\
	and not _is_cooldown_active()\
	and _are_usages_remaining():
		# call ability if no warmup, else 
		if ability_warmup > 0.0:
			change_warmup_state(true)
		else:
			activate_with_cooldown()


# precursor to calling the _call_ability method
# to handle cooldowns
func activate_with_cooldown():
	change_cooldown_state(true)
	# activate
	_call_ability()


func change_usages(usage_change: int):
	usage_change = usage_change


# start a new cooldown period or end an active cooldown period
# if 'activate_cooldown' is true, starts cooldown (if not already active)
# if 'activate_cooldown' is false, ends the active cooldown period (if any)
func change_cooldown_state(activate_cooldown: bool = true) -> void:
	# skip if called without valid cooldown
	if _is_cooldown_valid() == false:
		return
	# start cooldown and reset timer (if not already in cooldown)
	if activate_cooldown and not is_in_cooldown:
		is_in_cooldown = activate_cooldown
		frames_since_cooldown_started = 0.0
		emit_signal("ability_cooldown_active", 0.0)
		emit_signal("ability_cooldown_started")
	# end cooldown state
	elif not activate_cooldown and is_in_cooldown:
		is_in_cooldown = activate_cooldown
		emit_signal("ability_cooldown_finished")


# start a new warmup period
# if 'activate_warmup' is true, starts warmup (if not already active)
# if 'activate_warmup' is false, ends the active warmup period (if any)
func change_warmup_state(activate_warmup: bool = true) -> void:
	# skip if called without valid warmup
	if _is_warmup_valid() == false:
		return
	# start warmup and reset timer (if not already in warmup)
	if activate_warmup and not is_in_warmup:
		is_in_warmup = true
		frames_since_warmup_started = 0.0
		emit_signal("ability_warmup_active", 0.0)
		emit_signal("ability_warmup_started")
	# end warmup state, automatically start cooldown
	elif not activate_warmup and is_in_warmup:
		is_in_warmup = false
		emit_signal("ability_warmup_finished")
		# warmup always proceeds to activation
		activate_with_cooldown()


##############################################################################

# private methods


# method to determine whether ability has usages remaining
func _are_usages_remaining() -> bool:
	return true


# method to determine whether ability is currently in the cooldown state
func _is_cooldown_active() -> bool:
	# if cooldown is used, check whether ability is in cooldown
	if _is_cooldown_valid():
		return is_in_cooldown
	else:
		return false


# method to determine whether ability uses a cooldown
func _is_cooldown_valid() -> bool:
	# if cooldown isn't used, cooldown is never active
	var is_cooldown_enabled = (ability_cooldown > 0.0)
	return is_cooldown_enabled


# method to determine whether ability is currently in the warmup state
func _is_warmup_active() -> bool:
	# if warmup  is used, check whether ability is in warmup 
	if _is_warmup_active():
		return is_in_warmup
	else:
		return false
	

# method to determine whether ability uses a warmup
func _is_warmup_valid() -> bool:
	# if warmup isn't used, warmup  is never active
	var is_warmup_enabled = (ability_warmup > 0.0)
	return is_warmup_enabled


## after conclusion of cooldown period
#func _on_cooldown_expired():
#	is_in_cooldown = false
#	emit_signal("ability_cooldown_finished")


## after conclusion of warmup period
#func _on_warmup_expired():
#	is_in_warmup = false
#	emit_signal("ability_warmup_finished")
#	# warmup always proceeds to activation
#	activate_with_cooldown()


##############################################################################

# 
