extends Node2D


##############################################################################

var debug_value_tracker = {
	"is_cooldown_active": false,
	"is_warmup_active": false,
	"cooldown_progress": 0.0,
	"warmup_progress": 0.0,
}


onready var debug_label = $DebugLabel


func _ready():
	update_debug_label()


func update_debug_label():
	var debug_string = ""
	for key in debug_value_tracker:
		debug_string += (str(key)+": "+str(debug_value_tracker[key])+"\n")
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
