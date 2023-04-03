extends Position2D

class_name EntitySpawner

##############################################################################

# Companion class to entity class

# [Usage]
# EntitySpawners create pre-configured entities. To set up an entity spawner
# create a new scene with an entity spawner as part of the node tree, and place
# an entity node in the same node tree (ideally as a child of the spawner).
# Set the desired entity export args (i.e. sprite/collision), make sure to set
# the '.is_root' export property of the entity, and set the path export of the
# spawner to the location of the entity in the node tree.
# The entity spawner will not create entities unless a signal is connected
# to its .spawn() method, or an automated spawning behaviour (such as the
# .spawn_timeout property) is enabled.

######################################

#//TODO
#	Add GlobalPool to manage object pooling behaviour (on per-spawner basis?))

##############################################################################

export(NodePath) var entity_path: NodePath

# if this value is set a repeating autostart timer will be created
# changing this value will reset the timer
# set this value to nil (0.0) to disable the timer
export(float) var spawn_timeout: float = 0.0 setget _set_spawn_timeout

# by default the entity spawner is allowed to create ('spawn') its entity
# by setting this value to false the entity spawner will acknowledge requests
# to create entities (run timer loops, recieve signals, etc) but will not
# actually create new entities when asked.
var spawn_allowed: bool = true

# spawn timer node is only created if the spawn_timeout value is set
var spawn_timer_node: Timer = null

# node reference to the entity to create
onready var spawner_entity :=\
		get_node(entity_path) setget _set_spawner_entity

##############################################################################


# this setter confirms typing of the set entity to spawn
func _set_spawner_entity(arg_entity: EntityArea):
	spawner_entity = arg_entity


# this setter handles creating a timer node if none exists on setting
# a non-nil value to spawn_timoeout
func _set_spawn_timeout(arg_timeout: float):
	spawn_timeout = arg_timeout
	# configure spawn timer
	if spawn_timer_node != null:
		if spawn_timer_node is Timer:
			# reset timer
			if not spawn_timer_node.is_stopped():
				spawn_timer_node.stop()
			# disable on nil value
			if spawn_timeout > 0.0:
				spawn_timer_node.wait_time = spawn_timeout
				spawn_timer_node.start()
	# spawn timer not found, add it
	else:
		_create_spawn_timer()


##############################################################################

# virtual methods

##############################################################################

# public methods


func spawn():
	var new_entity = spawner_entity.duplicate()
	if new_entity == null:
		#//TODO replace w/globalDebug call (as with all printerr placeholders)
		printerr("spawn() unable to duplicate spawner entity")
	assert(new_entity is EntityArea)
	#//TODO _is_root shouldn't be private
	new_entity.is_root = false
	new_entity.is_active = true
	new_entity.is_valid = true
	# set initial position to spawner (place spawner as muzzle)
	new_entity.global_position = self.global_position
	#//replace with globalPool in future implementation
	var entity_root = get_tree().root
	# do not add new entities as a child of the spawner else it will produce
	# unwanted movement behaviour (inheriting spawner global position changes)
	entity_root.call_deferred("add_child", new_entity)


##############################################################################

# private methods


# if spawn timer doesn't already exist but spawn_timeout property is set,
# create a repeating autostart timer to handle spawn timeouts
func _create_spawn_timer():
	if spawn_timer_node != null:
		#//TODO replace w/globalDebug call (as with all printerr placeholders)
		printerr("call to _create_spawn_timer but spawn timer already exists")
		return
	spawn_timer_node = Timer.new()
	if spawn_timer_node.connect("timeout", self, "spawn") != OK:
		#//TODO replace w/globalDebug call (as with all printerr placeholders)
		printerr("spawn timer failed to connect to entity spawner")
		# discard timer (ref count should be nil for garbage collector)
		spawn_timer_node = null
	else:
		spawn_timer_node.autostart = true
		spawn_timer_node.one_shot = false
		spawn_timer_node.wait_time = spawn_timeout
		self.call_deferred("add_child", spawn_timer_node)
#	yield(spawn_timer_node, "tree_entered")
#	spawn_timer_node.start()


##############################################################################

