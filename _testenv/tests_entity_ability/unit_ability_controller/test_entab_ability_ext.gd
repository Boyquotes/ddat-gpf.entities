extends Node2D


##############################################################################

var debug_value_tracker = {
	"is_cooldown_active": false,
	"cooldown_progress": 0.0,
	"is_warmup_active": false,
	"warmup_progress": 0.0,
	"current_uses": 0,
	"refresh_progress": 0.0,
	"delay_progress": 0.0,
}

var debug_special_messages = []

onready var debug_label_active = $DebugActive
onready var debug_label_historic = $DebugHistoric
onready var clear_debug_button = $ClearDebugButton


func _ready():
	update_debug_label()


func update_debug_label():
	#1
	var debug_string_1 = ""
	for key in debug_value_tracker:
		debug_string_1 += (str(key)+": "+str(debug_value_tracker[key])+"\n")
	if debug_label_active != null:
		debug_label_active.text = debug_string_1
	#2
	var debug_string_2 = ""
	for message_string in debug_special_messages:
		debug_string_2 += str(message_string)+"\n"
	if debug_label_historic != null:
		debug_label_historic.text = debug_string_2

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
	debug_special_messages.append(\
			"restored {x} uses!".format({"x": uses_refreshed}))
	update_debug_label()


func _on_AbilityController_ability_usage_spent(uses_remaining, uses_spent):
	debug_value_tracker["current_uses"] = uses_remaining
	debug_special_messages.append(\
			"spent {x} uses!".format({"x": uses_spent}))
	update_debug_label()


func _on_AbilityController_ability_usages_depleted():
	debug_special_messages.append("usages depleted!")
	update_debug_label()


func _on_AbilityController_ability_usages_full():
	debug_special_messages.append("usages full!")
	update_debug_label()


func _on_AbilityController_refresh_delay_active(delay_progress):
	debug_value_tracker["delay_progress"] = delay_progress
	update_debug_label()


func _on_AbilityController_refresh_delay_ended():
	debug_special_messages.append("refresh delay ended!")
	update_debug_label()


func _on_AbilityController_refresh_delay_started():
	debug_special_messages.append("refresh delay started!")
	update_debug_label()


func _on_AbilityController_failed_activation(error_code):
	var err_keys = AbilityController.ACTIVATION_ERROR.keys()
	debug_special_messages.append("failed activation, error {x}".format({
				"x": str(error_code)+" (ERR: {code})".format({
				"code": err_keys[error_code]})
	}))
	update_debug_label()


func _on_ClearDebugButton_pressed():
	if debug_label_historic != null:
		debug_special_messages = []
		debug_label_historic.text = ""
	clear_debug_button.release_focus()


