extends Node2D


##############################################################################

onready var rot_target_line = $CenterOfScreen/RotTargetLine
onready var debug_label = $DebugLabel
onready var tween_node = $Tween
onready var enemy_test_1 = $EnemyTest1
onready var enemy_test_2 = $EnemyTest2


# TEST OUTCOMES
# input activated has a minimum cooldown/delay it seems < SOLVED*
# *relates to activation cap per frame, default should probably be higher
# input toggled works
# input confirmed press needs to unset after successful activate < FIXED
# input confirmed hold works

func _ready():
	tween_node.connect("tween_all_completed", self, "restart_tween_test")
	restart_tween_test()
	enemy_test_1.add_to_group("groupstring_enemy")
	enemy_test_2.add_to_group("groupstring_enemy")


var tween_reverse_state := false
var test1_positions = [Vector2(0, 300), Vector2(1720, 300)]
var test2_positions = [Vector2(1700, 420), Vector2(0, 420)]
func restart_tween_test():
	var test1 =\
			[test1_positions[0], test1_positions[1]] if\
			tween_reverse_state else\
			[test1_positions[1], test1_positions[0]]
	var test2 =\
			[test2_positions[0], test2_positions[1]] if\
			tween_reverse_state else\
			[test2_positions[1], test2_positions[0]]
	
	tween_reverse_state = !tween_reverse_state
	tween_node.interpolate_property(enemy_test_1,\
			"global_position",
			test1[0], test1[1],
			3.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.interpolate_property(enemy_test_2,\
			"global_position",
			test2[0], test2[1],
			1.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()


func _on_EntityAbilityTargeter_update_target(arg_target_position):
	rot_target_line.look_at(arg_target_position)
#	rot_target_line.rotation = rot_target_line.global_position.angle_to(arg_target_position)
	debug_label.text = str(arg_target_position)
#	print("target_position is {tp}".format({"tp": arg_target_position}))

#func _process(_arg_delta):
#	rot_target_line.look_at(get_global_mouse_position())
