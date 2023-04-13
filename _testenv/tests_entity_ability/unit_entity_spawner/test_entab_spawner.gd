extends Node2D


##############################################################################

onready var debug_label = $DebugLabel
var pre_player = preload("res://src/ddat-gpf/entity_systems/player_controllers/player_main.tscn")

func _ready():
	var new_player = pre_player.instance()
	print(new_player.get_script())
	print(pre_player.instance().get_script())
	test_pool_manual_add_remove()

	
# need to test
func test_pool_manual_add_remove():
	var objpool_test = ObjectPool.new(pre_player)
	var player2inst = pre_player.instance()
	player2inst.name = "testPlayer"
	print("testPlayer instance is ", player2inst)
	print("pool should be empty (sample instance not in pool)")
	print("register print 1 = ", objpool_test.object_register)
	print("adding test instance")
	objpool_test.add_to_pool(player2inst)
	print("register print 2 = ", objpool_test.object_register)
	print("removing test instance")
	objpool_test.remove_from_pool(player2inst)
	print("register print 3 = ", objpool_test.object_register)
