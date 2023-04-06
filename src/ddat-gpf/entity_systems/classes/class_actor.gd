extends Node2D

class_name Actor

##############################################################################
#
# Actors are a node type responsible for intelligently manging gaem systems.
# Actors consist of four key parts;
#	Components - tags that define how an actor behaves in response to stimuli
#	Stats - numerical properties that can be temporarily modified
#	Actions - methods that are called in response to predefined conditions

#//TODO
#	Add records to stat changes of all operations?

##############################################################################

#05. signals
#06. enums
#07. constants
# for passing to error logging
const CLASS_NAME := "script_name"
# for developer use, enable if making changes
const CLASS_VERBOSE_LOGGING := true

# warning-ignore:unused_class_variable
# record of all actorComponents assigned to this actor
var components := []

# warning-ignore:unused_class_variable
# record of all actorStats assigned to this actor
var stats := {}
# warning-ignore:unused_class_variable
# record of all actorStatMods assigned to this actor
var active_mods = []

# warning-ignore:unused_class_variable
# record of all actorActions assigned to this actor
var actions := []
# warning-ignore:unused_class_variable
# actorActions assigned to this actor that have not been resolved this gametick
var pending_actions := []

##############################################################################


# add group strings to parent
class Component:
	var name := ""
	var state := true
#	var group_string := ""
	
	func _init(arg_name: String, arg_state: bool = true):
		self.name = arg_name
		self.state = arg_state
	
	class comp2:
		pass


##############################################################################


# [Purpose]
# stats are essentially enhanced floats that allow for automatic bounding
# limitations, have comprehensive signal integration, and allow for
# conditional changes to their value ('mods')
# there are two intended ways to use an Actor.Stat
#	1) track a value that is damaged and healed over time, which must stay
#	within a minimum and maximum bound (e.g. for health/mana/stamina values)
#	2) track a value that is only temporarily changed, or is the basis of
#	further calculations as more modifiers are gained (e.g. for strength/
#	damage/intelligence, or other attribute-like values)
# [Usage]
# you should use the damage/heal methods in the first instance above, and the
# apply_mod/remove_mod methods in the second. Whilst you could mix and match
# these methods, the base value of a stat (the value which is damaged and
# healed) happens *before* any recorded mods; i.e. you will change the effect
# of applied mods by altering the base value without a mod. It will cause
# unexpected results (and consequently behaviour in the stat's Actor).
class Stat:
	signal stat_mod_applied(mod_type)
	signal stat_mod_removed(mod_type)
	signal stat_min_changed(new_min_value)
	signal stat_max_changed(new_max_value)
	signal stat_damaged(new_base_value)
	signal stat_healed(new_base_value)
	signal stat_state_changing(is_stat_active)
	signal stat_state_changed(is_stat_active)
	
	var _owner: Actor
	# bounds of the current value
	var _maximum_base_value := 0.0
	var _minimum_base_value := 0.0
	# the value of stat, before any mods
	var _base_value := 0.0 setget _set_base_value
	var is_active := false setget _set_is_active
	var is_setup_correctly := false
	# set mods with apply mod methods
	var mods_flat := []
	var mods_variance := []
	var mods_coefficient := []
	
	# value cannot be below minimum or above maximum
	# if value equals minimum, stat is deactivated, else active
	func _set_base_value(arg_new_value: float):
		var potential_value = arg_new_value
		if arg_new_value > _maximum_base_value:
			potential_value = _maximum_base_value
		if arg_new_value < _minimum_base_value:
			potential_value = _minimum_base_value
		if potential_value == _minimum_base_value:
			if is_active == true:
				emit_signal("stat_state_changing", false)
				is_active = false
				emit_signal("stat_state_changed", false)
		else:
			if is_active == false:
				emit_signal("stat_state_changing", true)
				is_active = true
				emit_signal("stat_state_changed", true)
		_base_value = potential_value
	
	
	# if not setup correctly stat can never be valid
	func _set_is_active(arg_new_value: bool):
		if is_setup_correctly == true:
			is_active = arg_new_value
		else:
			is_active = false
	
	
	# arg owner should be the actor that owns the stat
	# arg value should be the initial current and maximum value of stat
	func _init(arg_owner: Actor, arg_initial_value: float = 0.0):
		_owner = arg_owner
		# set max and min before to prevent current value setter breaking
		_maximum_base_value = arg_initial_value
		_minimum_base_value = 0.0
		# set owner to influence current value setter (stat is always
		# inactive if setup was a failure)
		if _owner != null:
			is_setup_correctly = true
		self._base_value = arg_initial_value
	
	
	func get_value(get_base: bool = false):
		if get_base:
			return _base_value
		else:
			return _calculate_mods()
	
	
	func set_value(arg_new_value: float):
		self._base_value = arg_new_value
	
	
	func adjust_min(arg_new_minimum: float):
		_minimum_base_value = arg_new_minimum
		emit_signal("stat_min_changed", _minimum_base_value)
	
	
	func adjust_max (arg_new_maximum: float):
		_maximum_base_value = arg_new_maximum
		if _base_value > _maximum_base_value:
			_base_value = _maximum_base_value
		if _minimum_base_value > _maximum_base_value:
			_minimum_base_value = _maximum_base_value
		emit_signal("stat_max_changed", _maximum_base_value)
	
	
	# returns an error code or OK
	func apply_mod(
			arg_mod_type: int,
			arg_mod_value: float,
			arg_mod_duration: float = 0.0) -> int:
		# type err check
		if not arg_mod_type in Mod.MOD_TYPES.values():
			return ERR_PARAMETER_RANGE_ERROR
		
		# create the mod
		var new_mod: Mod
		new_mod = Mod.new(
				arg_mod_type, arg_mod_value, arg_mod_duration)
		
		# err check - was mod created correctly
		if new_mod == null:
			return ERR_CANT_CREATE
		if new_mod.is_valid == false:
			return ERR_UNCONFIGURED
		
		# validate setting up signal
		if new_mod.is_valid:
			if new_mod.connect("mod_disabled",
					self, "remove_mod", [arg_mod_type]) != OK:
				GlobalDebug.log_error(
						CLASS_NAME, "_apply_mod",
						"mod {m} didn't connect mod_disabled".format({
							"m": str(self)
						}))
				return ERR_CANT_CONNECT
		
		# assign the mod to the relevant mod register
		match arg_mod_type:
			Mod.MOD_TYPES.FLAT:
				mods_flat.append(new_mod)
			Mod.MOD_TYPES.VARIANCE:
				mods_variance.append(new_mod)
			Mod.MOD_TYPES.COEFFICIENT:
				mods_coefficient.append(new_mod)
		# final edge case check
		if new_mod in mods_flat\
		or new_mod in mods_variance\
		or new_mod in mods_coefficient:
			emit_signal("stat_mod_applied", arg_mod_type)
			return OK
		else:
			return ERR_INVALID_DATA
	
	
	# lowers the base value, down to maximum base value constraint
	# method is separate from heal method for readability
	func damage(arg_damage: float):
		_base_value -= arg_damage
		emit_signal("stat_damaged", _base_value)
	
	
	# restores the base value, up to maximum base value constraint
	# method is separate from damage method for readability
	func heal(arg_healing: float):
		_base_value += arg_healing
		emit_signal("stat_healed", _base_value)
	
	
	# removes a mod from the respective mod register record
	# called automatically when timed mods expire, or can be called via
	# a manual signal connection, or just a manual method call
	func remove_mod(arg_mod_type: int, arg_mod_id: Mod):
		match arg_mod_type:
			Mod.MOD_TYPES.FLAT:
				mods_flat.erase(arg_mod_id)
				emit_signal("stat_mod_removed", arg_mod_type)
			Mod.MOD_TYPES.VARIANCE:
				mods_variance.erase(arg_mod_id)
				emit_signal("stat_mod_removed", arg_mod_type)
			Mod.MOD_TYPES.COEFFICIENT:
				mods_coefficient.erase(arg_mod_id)
				emit_signal("stat_mod_removed", arg_mod_type)
	
	
	# checks against existing mods, clamps to min/max bounds before returning
	# order of operations when calculating a mod
	#	1. start at base value
	#	2. apply all flat modifiers as addition or subtraction
	#	3. apply the variance modifier as a single coefficient
	#	4. apply the remaining coefficient modifiers in sequence
	func _calculate_mods():
		var modified_value: float
		modified_value = _base_value
		
		var total_flat := 0.0
		for flatmod in mods_flat:
			if flatmod is Mod:
				total_flat += flatmod.value
		modified_value += total_flat
		
#		var value_after_flat = modified_value
		
		var base_variance := 1.0
		var total_variance := 0.0
		total_variance += base_variance
		for varmod in mods_variance:
			if varmod is Mod:
				total_variance += varmod.value
		modified_value *= total_variance
		
#		var value_after_variance = modified_value
		
		for coeffmod in mods_coefficient:
			if coeffmod is Mod:
				modified_value *= coeffmod
		
#		var value_after_coefficient = modified_value
		return modified_value


	#//TODO need to add conditionals property for what triggers is_active
	class Mod:
		# if mod expiry timestamp is reached the actorStat should remove it
		signal mod_disabled()
		
		# How the modifier is applied i.e;
		# ModFlat
		# mods that are additive or subtractive, applied before any other mod
		# Flat mods can be passed as any value
		
		# ModVariance	
		# mods that are increased/decreased type values, e.g. +/-10%
		# differs from coefficient mods as variance mods are added together
		# before they are multiplied on the base+flat value
		# Variance mods values should be -0.1 (-10%), 0.25 (+25%), etc
		
		# ModCoefficient
		# mods that are multiplier/divisor type values, e.g. 1.1x
		# differs from variance mods as each coefficient applies to the
		# previous total value, e.g. affecting each previous coefficient
		# Coefficient mods should be 0.7 (30% less), 1.4 (40% more), etc
		enum MOD_TYPES {FLAT, VARIANCE, COEFFICIENT}
		
		# duration in seconds, calculated from unix time
		# if duration is nil or negative, duration is ignored
	#		var base_duration: float
		var initial_timestamp: float
		var expiry_timestamp: float
		# validity calculated from unix time
		var is_valid := true setget _set_is_valid
		
		var type := 0
		# see mod type enum and stat 'calculate_mods' method
		var value := 0.0
		
		func _set_is_valid(arg_value: bool):
			is_valid = arg_value
			if is_valid == false:
				emit_signal("mod_disabled")
		
		# arg_duration is in seconds
		# mods automatically expire if a duration is set, when the unix time
		# reaches {unixtime mod was created}+{duration}
		func _init(
				arg_mod_type: int = 0,
				arg_value: float = 0.0,
				arg_duration: float = 0.0):
			# set time calculations
			initial_timestamp = Time.get_unix_time_from_system()
			if arg_duration > 0.0:
				expiry_timestamp = (initial_timestamp + arg_duration)
			# set value
			value = arg_value
			# if mod type is invalid the mod will be deleted immediately
			if arg_mod_type in MOD_TYPES.values():
				type = arg_mod_type
			else:
				self.is_valid = false
		
		
		# shadowed in other classes
		# this is when timestamp is checked
		# not sure how performative repeated calls to Time will be, but
		# arguably an inbuilt class will be faster than any gdscript method
		# if mod timestamp has passed the mod will emit signal to be removed
		func is_expired() -> bool:
			# cannot be expired if a duration was never set
			if expiry_timestamp == null:
				return false
			var get_current_timestamp = Time.get_unix_time_from_system()
			if get_current_timestamp >= expiry_timestamp:
				self.is_valid = false
				return true
			# checks passed, return true
			return false
		
		
		# force the mod to be disabled
		# on initialisation connect a signal to this method to disable
		# mods without using a duration
		# this will force the signal to remove the mod
		func disable():
			self.is_valid = false


##############################################################################
	


##############################################################################


## should actor actions be nodes beneath an actor action manager/holder node?
#class ActorActionManager:
#	pass
#
#	func _init():
#		pass


##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	


#func apply_mod_to_stat(arg_stat: Stat, arg_mod: Mod):
#	match arg_mod.type:
#		Mod.MOD_TYPES.FLAT:
#			pass
#		Mod.MOD_TYPES.VARIANCE:
#			pass
#		Mod.MOD_TYPES.COEFFICIENT:
#			pass
##		Mod.MOD_TYPES.V
#
#
#	arg_stat = arg_stat



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

