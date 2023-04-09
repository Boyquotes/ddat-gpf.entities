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

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# for ability warmup animations
# only emitted if 'ability_warmup' is positive
signal warming_up(warmup_remaining)
# for ui elements and ability cooldown animations
# only emitted if 'ability_cooldown' is positive
signal cooling_down(cooldown_remaining)
# indicates that the ability is about to fire
# only emitted if 'ability_warmup' is positive
signal ability_warmup_finished()
# indicates that the ability can be used again
# only emitted if 'ability_cooldown' is positive
signal ability_cooldown_finished()
# emitted alongside activate_ability, for ui elements to track usage remaining
# only emitted if 'max_usages' property is nil or positive
signal ability_use_spent(uses_remaining)
# emitted when a usage is refreshed, for ui elements
# only emitted if 'refresh_usages_time' and 'usages_refresh_amount' are valid
signal ability_use_refreshed(uses_refreshed)

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

##############################################################################

# public methods


# shadowed from activation controller to check conditions before activation
func activate():
	pass


##############################################################################

# private methods

##############################################################################

# 
