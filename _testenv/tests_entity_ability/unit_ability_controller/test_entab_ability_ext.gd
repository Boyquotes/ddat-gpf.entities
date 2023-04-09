extends Node2D


##############################################################################

onready var debug_label = $DebugLabel

func _ready():
	pass



func _on_AbilityController_activate_ability():
	print("test activate")
