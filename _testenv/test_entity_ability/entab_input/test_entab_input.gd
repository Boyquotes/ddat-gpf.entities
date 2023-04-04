extends Node2D


##############################################################################

# TEST OUTCOMES
# input activated has a minimum cooldown/delay it seems < SOLVED*
# *relates to activation cap per frame, default should probably be higher
# input toggled works
# input confirmed press needs to unset after successful activate < FIXED
# input confirmed hold works


var ability_activation_count = 0
func _on_EntityAbilityController_activate_ability():
	ability_activation_count += 1
	print("ability activated, count: {x}".format({"x": ability_activation_count}))

