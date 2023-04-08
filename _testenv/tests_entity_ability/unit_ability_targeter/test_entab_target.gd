extends Node2D


##############################################################################

# for different types of targeter test and specifying which to run
enum TEST_TYPE {STANDARD_TEST, TARGET_DELETED_TEST}
export(TEST_TYPE) var current_test_type := TEST_TYPE.STANDARD_TEST

# for debug label
# for debugging whether an ability input is actually being recieved
var ability_activation_count := 0
var last_target_position := Vector2.ZERO
var target_name := ""
var current_target

# for enemy tweening/movement simulation
var tween_reverse_state := false
var test1_positions = [Vector2(0, 300), Vector2(1720, 300)]
var test2_positions = [Vector2(1700, 420), Vector2(0, 420)]

# node references
onready var rot_target_line = $CenterOfScreen/RotTargetLine
onready var debug_label = $DebugLabel
onready var tween_node = $Tween
onready var enemy_test_1 = $EnemyTest1
onready var enemy_test_2 = $EnemyTest2
onready var delete_test_timer = $DeleteTestTimer

onready var all_test_enemies = [enemy_test_1, enemy_test_2]

##############################################################################


func _ready():
	tween_node.connect("tween_all_completed", self, "restart_tween_test")
	restart_tween_test()
	enemy_test_1.add_to_group("groupstring_enemy")
	enemy_test_2.add_to_group("groupstring_enemy")
	update_debug_label()
	if current_test_type == TEST_TYPE.TARGET_DELETED_TEST:
		randomize()
		var rnd_delete_timer = rand_range(1.0, 4.0)
		delete_test_timer.wait_time = rnd_delete_timer
		delete_test_timer.connect("timeout", self, "delete_current_target")
		delete_test_timer.start()


##############################################################################


func delete_current_target():
	if current_target is Sprite:
		current_target.call_deferred("queue_free")


func delete_random_enemy():
	randomize()
	var enemy_to_delete = randi() % all_test_enemies.size() + 1
	var get_enemy = all_test_enemies[enemy_to_delete-1]
	if get_enemy is Sprite:
		get_enemy.call_deferred("queue_free")


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
	if enemy_test_1 != null:
		tween_node.interpolate_property(enemy_test_1,\
				"global_position",
				test1[0], test1[1],
				3.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	if enemy_test_2 != null:
		tween_node.interpolate_property(enemy_test_2,\
				"global_position",
				test2[0], test2[1],
				1.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()


func update_debug_label():
	debug_label.text =\
			"target: "+str(target_name)+"\n"+\
			"last known position: "+str(last_target_position)+"\n"+\
			"activation count: "+str(ability_activation_count)


##############################################################################


func _on_ActivationController_activate_ability():
	ability_activation_count += 1
	update_debug_label()


func _on_EntityAbilityTargeter_update_target_position(arg_target_position):
	rot_target_line.look_at(arg_target_position)
#	rot_target_line.rotation = rot_target_line.global_position.angle_to(arg_target_position)
	last_target_position = arg_target_position
#	print("target_position is {tp}".format({"tp": arg_target_position}))
	update_debug_label()


func _on_EntityAbilityTargeter_update_target_reference(arg_target_reference):
	current_target = arg_target_reference
	if arg_target_reference is Node2D:
		target_name = arg_target_reference.name
	update_debug_label()

