extends Node2D


##############################################################################

var debug_value_tracker = {
	"is_cooldown_active": false,
	"cooldown_progress": 0.0,
	"is_warmup_active": false,
	"warmup_progress": 0.0,
	"current_uses": 0,
	"refresh_progress": 0.0,
}


onready var debug_label = $DebugLabel


func _ready():
	update_debug_label()


func update_debug_label():
	var debug_string = ""
	for key in debug_value_tracker:
		debug_string += (str(key)+": "+str(debug_value_tracker[key])+"\n")
	if debug_label != null:
		debug_label.text = debug_string

func _on_AbilityController_activate_ability():
	print("test activate")


func _on_AbilityController_ability_cooldown_active(cooldown_progress):
	debug_value_tracker["cooldown_progress"] = cooldown_progress
	update_debug_label()


func _on_AbilityController_ability_cooldown_finished():
	debug_value_tracker["is_cooldown_active"] = false
	update_debug_label()


func _on_AbilityController_ability_cooldown_started():
	debug_value_tracker["is_cooldown_active"] = true
	update_debug_label()


func _on_AbilityController_ability_warmup_active(warmup_progress):
	debug_value_tracker["warmup_progress"] = warmup_progress
	update_debug_label()


func _on_AbilityController_ability_warmup_finished():
	debug_value_tracker["is_warmup_active"] = false
	update_debug_label()


func _on_AbilityController_ability_warmup_started():
	debug_value_tracker["is_warmup_active"] = true
	update_debug_label()




func _on_AbilityController_ability_refresh_active(refresh_progress):
	debug_value_tracker["refresh_progress"] = refresh_progress
#	debug_value_tracker["is_refresh_active"] = true
	update_debug_label()


func _on_AbilityController_ability_usage_refreshed(uses_remaining, uses_refreshed):
	debug_value_tracker["current_uses"] = uses_remaining
	print("restored {x} uses!".format({"x": uses_refreshed}))
	update_debug_label()


func _on_AbilityController_ability_usage_spent(uses_remaining, uses_spent):
	debug_value_tracker["current_uses"] = uses_remaining
	print("spent {x} uses!".format({"x": uses_spent}))
	update_debug_label()


func _on_AbilityController_ability_usages_depleted():
	print("usages depleted!")


func _on_AbilityController_ability_usages_full():
	print("usages full!")
