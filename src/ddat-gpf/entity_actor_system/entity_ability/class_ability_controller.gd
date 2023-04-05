extends ActivationController

class_name AbilityController

##############################################################################

# BRAINSTORMING
#Revising for 23-04-05
#
# [EntityAbilityTargeter]
# FiringArc (max rotate toward target, 0 for fixed) should go to EntityAbilityTargeter
# Targeter should have a 'allowed_to_rotate_toward' and rotate-toward-speed property
# Targeter 'rotation' should be an invisible line
# MOVE TO EntityAbilityTargeter:
#	TargetGuiding Line:
#		Visible line2d, for player guidance/optional arg for target-mouselook
#	TargetAcquisition:
#		Invisible line that checks if path would collide with ship
#		(for auto target modes to not fire if would fire through ship)

# [EntitySpawner]
# SpawnPattern (how many to spawn) is going to EntitySpawner
# SpawnPattern (spawn offset) is part of EntitySpawner
# SpawnPatterns can push properties to entities, influencing spawned
# entity behaviour (like lifespan/collision/movement)

# [EntityArea]
# SpawnPattern (movement patterns/args) should be part of the Entity itself
#	(maybe with optional properties pushed by spawner)
#	EntityMovementControllers can stack and apply multiple movement instructions per frame?
#	Entities contain options for different lifespan/collison/movement packages?

# [WeaponController/AbilityController]
# previously pegged as part of weapon controller, should these be moved to abilityController parent?
# Should these 
#	AbilityWarmup
#		How long it takes to fire when target found or input pressed
#		optional arg for whether tracking during warmup (signal to targeter)
#		need settings 
#	AbilityCooldown
#		how long before it can seek target or acknowledge input again
#	(scope?)
#	AbilityUses
#		How many times it can spawn total, negative for infinite
#		need signal update when spawning, reaching max spawns
#	AbilityRefresh
#		how long it takes to replenish spawn uses, nil or negative for never
#		need signal update when replenishing
#	RefreshAmount
#		how many uses are refreshed on refresh timeout, negative for all
#		need signal update when refreshed
#	RefreshMode
#		refresh-when-not-in-use, refresh-always, refresh-when-uses-spent
#	CooldownMode
#		as above (refreshMode)
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
