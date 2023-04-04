extends Position2D

class_name EntitySpawner

##############################################################################

# EntitySpawners create EntityArea nodes on demand, and act as an object
# pooling systems which track previous spawns and hide now-unused entities as
# well as re-using them.

# [To Use]
# Either
# 1) instance an entityArea beneath the entitySpawner and assign it in-editor
# to the NodePath export 'entity_path'
#		on '_new_spawn()' calls, entities will be duplicated from this node
# or
# 2) assign a prebuilt entity area scene to the 'entity_area_scene' export
#		on '_new_spawn()' calls, entities will be instanced from this preload
#
# If both above setups are valid, the first (duplicate) will be preferred
#
# Afterwards call the 'spawn()' method to ask the entitySpawner to create one
# of the

#//TODO
# test both usage methods above


##############################################################################

# on about to spawn (before joining tree/parent change, before parameters set)
signal entity_spawning(new_entity)
# when spawned (after in tree)
signal entity_spawned(new_entity)

# options for where to  place the newly spawned entity within the scene tree
# end goal
#enum SPAWN_PARENT {GLOBAL_POOL, SELF, OWNER, TREE_ROOT}
# temp
enum SPAWN_PARENT {TREE_ROOT}

export(PackedScene) var entity_area_scene

export(NodePath) var entity_path: NodePath

export(SPAWN_PARENT) var entity_parent := SPAWN_PARENT.TREE_ROOT

# by default the entity spawner is allowed to create ('spawn') its entity
# by setting this value to false the entity spawner will acknowledge requests
# to create entities (run timer loops, recieve signals, etc) but will not
# actually create new entities when asked.
export(bool) var is_enabled: bool = true

var active_entities = []

var inactive_entities = []

# node reference to the entity to create
# is set to null if the path is invalid
onready var spawner_entity :=\
		get_node_or_null(entity_path)


##############################################################################

# virtual methods




##############################################################################

# public methods


# object pooling system which will reference inactive/active registers of
# entities and either create a new entity, or reuse an old disabled entity.
func spawn():
	var new_entity
	if inactive_entities.empty():
		new_entity = _new_spawn()
	if new_entity is EntityArea:
		emit_signal("entity_spawning", new_entity)
		new_entity.global_position = global_position
		#// need to add movement behaviour
		#// need to add setup/validation for each spawner method?
		#// stick to one spawner method?
		new_entity.visible = true
		print("hi")
		_assign_entity_parent(new_entity)
#		yield(_assign_entity_parent(new_entity), "completed")
		emit_signal("entity_spawned", new_entity)
	else:
		print("fail")
	
	#//TODO add object pooling behaviour


func _assign_entity_parent(
		passed_entity: EntityArea,
		force_parent_change: bool = false
		) -> void:
	# if already in the tree, force a parent change
	if passed_entity.is_inside_tree() and force_parent_change:
		passed_entity.get_parent().call_deferred("remove_child", passed_entity)
		yield(passed_entity, "tree_exited")
	#
	#//TODO finish entity parent options
	match entity_parent:
		SPAWN_PARENT.TREE_ROOT:
			get_tree().root.call_deferred("add_child", passed_entity)


# whether an entity is made inactive or active
func _entity_state_update(arg_entity_node: EntityArea, arg_is_enabled: bool):
	# update active entity array 
	if (arg_is_enabled == true) and (not arg_entity_node in active_entities):
		active_entities.append(arg_entity_node)
	elif (arg_is_enabled == false) and (arg_entity_node in active_entities):
		active_entities.erase(arg_entity_node)
	# update inactive entity array
	if (arg_is_enabled == false) and (not arg_entity_node in inactive_entities):
		inactive_entities.append(arg_entity_node)
	elif (arg_is_enabled == true) and (arg_entity_node in inactive_entities):
		inactive_entities.erase(arg_entity_node)


# prioritise duplication spawning method
# returns null if unable to spawn an entity
func _new_spawn():
	var new_entity = null
	if spawner_entity is EntityArea:
		new_entity = _new_spawn_by_duplicate()
	elif entity_area_scene != null:
		new_entity = _new_spawn_by_instance()
	# if valid, update the registers
	if new_entity is EntityArea:
		_entity_state_update(new_entity, true)
		# when the entity changes active state it should update the spawner's
		# 'active_entities' and 'inactive_entities' registers
		new_entity.connect("is_active", self,
				"_entity_state_update", [new_entity])
	# make sure on return to check if new_entity is valid, this can return null
	return new_entity


# before calling should check the spawner_entity property is an EntityArea
# returns null if invalid
func _new_spawn_by_duplicate():
	var new_entity
	new_entity = spawner_entity.duplicate()
	# can return null
	return new_entity


# before calling should check the entity_area_scene property is valid
# returns null if invalid
func _new_spawn_by_instance():
	if entity_area_scene == null:
		return null
	var new_entity
	if entity_area_scene is PackedScene:
		new_entity = entity_area_scene.instance()
	# can return null
	return new_entity
	

func _old_new_spawn_method():
	var new_entity: Node2D = Node2D.new()
	new_entity.global_position = self.global_position
	#//replace with globalPool in future implementation
	var entity_root = get_tree().root
	# do not add new entities as a child of the spawner else it will produce
	# unwanted movement behaviour (inheriting spawner global position changes)
	entity_root.call_deferred("add_child", new_entity)


##############################################################################

# private methods



##############################################################################

