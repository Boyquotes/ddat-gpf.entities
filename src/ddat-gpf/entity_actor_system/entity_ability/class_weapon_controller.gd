extends EntityAbilityController

class_name WeaponController

##############################################################################

# docstring

# BRAINSTORMING
#
#AbilityController is a node that spawns entities (entityArea, entityProjectile)
#and acquires targets.
#Previously named 'WeaponController'
#
#Key properties of the weapon controller are:
#	FiringArc
#		How much it can rotate (0 for fixed)
#	SpawnPattern
#		How many entities to spawn
#		Where to spawn them relative to muzzle pos2D
#		What entityMovement arguments to give them
#	AbilityWarmup
#		How long it takes to fire when target found or input pressed
#		optional arg for whether tracking during warmup
#	AbilityCooldown
#		how long before it can seek target or acknowledge input again
#	(scope?)
#	AbilityUses
#		How many times it can spawn total, negative for infinite
#	AbilityRefresh
#		how long it takes to replenish spawn uses, nil or negative for never
#	RefreshAmount
#		how many uses are refreshed on refresh timeout, negative for all
#	RefreshMode
#		refresh-when-not-in-use, refresh-always, refresh-when-uses-spent
#	CooldownMode
#		as above (refreshMode)
#
#Key subnodes of the weapon controller are:
#	TargetGuiding Line:
#		Visible line2d, for player guidance/optional arg for target-mouselook
#	TargetReticule
#		Shown when off cooldown and trying to target
#		need INPUT_CONFIRMED_PRESS or INPUT_CONFIRMED_HOLD
#	TargetAcquisition:
#		Invisible line that checks if path would collide with ship
#		(for auto target modes to not fire if would fire through ship)
#


##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# signals to be implemented
#signal on_warmup(warmup_remaining)
#signal on_cooldown(cooldown_remaining)
#signal ability_used(uses_remaining)
#signal ability_uses_refreshed()

##############################################################################

# virtual methods

##############################################################################

# public methods

##############################################################################

# private methods

##############################################################################

# 
