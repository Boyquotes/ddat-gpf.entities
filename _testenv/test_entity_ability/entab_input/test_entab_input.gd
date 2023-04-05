extends Node2D

##############################################################################

# testenv for activation controller

##############################################################################

var debug_string_1_key = "ability uses"
var debug_string_1_value = ""
var debug_string_2_key = "confirmed press hold%"
var debug_string_2_value = "0.0"

var ability_activation_count = 0

onready var debug_label = $DebugLabel

#############################################################################


func _ready():
	update_debug_label()


#############################################################################


func update_debug_label():
	debug_label.text =\
			debug_string_1_key+": "+debug_string_1_value+"\n"+\
			debug_string_2_key+": "+debug_string_2_value+"\n"#+\


#############################################################################


func _on_ActivationController_activate_ability():
	ability_activation_count += 1
	print("ability activated, count: {x}".format({"x": ability_activation_count}))
	debug_string_1_value = str(ability_activation_count)
	update_debug_label()


func _on_ActivationController_input_held(hold_remaining):
	debug_string_2_value = str(hold_remaining)
	update_debug_label()

