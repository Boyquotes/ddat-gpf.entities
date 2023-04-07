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
# if spawn_method is set to NEW_SPAWN_METHOD.EITHER
#
# Afterwards call the 'spawn()' method to ask the entitySpawner to either
# create a new entity, if none are available in the inactive entity register,
# or repurpose an older entity.

# [Notes]
# Spawners can set entities active but cannot set them inactive, only an
# entity can decide when it is no longer in use (such as when it leaves the
# screen, moves outside of a maximum range, exists for its maximum duration,
# or has a collision event).


##############################################################################

# on about to spawn (before joining tree/parent change, before parameters set)
signal entity_spawning(new_entity)
# when spawned (after in tree)
signal entity_spawned(new_entity)

# options for spawn_method export
# for dev testing spawn methods, in practice probably best to leave to default
enum NEW_SPAWN_METHOD {EITHER, DUPLICATE, INSTANCE}
# options for where to  place the newly spawned entity within the scene tree
enum SPAWN_PARENT {GLOBAL_POOL, SPAWNER_SELF, SPAWNER_OWNER, SCENE_TREE_ROOT}

# for debugging
const CLASS_NAME := "EntitySpawner"
const CLASS_VERBOSE_LOGGING := false

# by default the entity spawner is allowed to create ('spawn') its entity
# by setting this value to false the entity spawner will acknowledge requests
# to create entities (run timer loops, recieve signals, etc) but will not
# actually create new entities when asked.
export(bool) var is_enabled: bool = true
# whether to duplicate a root entity node or instance a presaved entity scene
export(NEW_SPAWN_METHOD) var spawn_method := NEW_SPAWN_METHOD.EITHER
# scene tree path to a root entity node (see NEW_SPAWN_METHOD.DUPLICATE)
export(NodePath) var entity_path: NodePath
# resource path to a presaved entity scene (see NEW_SPAWN_METHOD.INSTANCE)
export(PackedScene) var entity_area_scene
# where to place the entity in the scene tree when created
export(SPAWN_PARENT) var entity_parent := SPAWN_PARENT.GLOBAL_POOL

# position offset of newly spawned entity, based on spawner position
export(Vector2) var spawn_offset := Vector2.ZERO

# allows you to configure initial properties on a spawned entity
# use -> list property name as key, and property value as value
export(Dictionary) var force_properties := {}

# entity registers, for whether an entity is currently active or not
# entities removed from play should change their .is_active property to false
# in order to trigger the signal that updates the register on their spawner
#//note: would dict with reference key and bool value be faster?
var active_entities = []
var inactive_entities = []

# node reference to the entity to create (set to null if the path is invalid)
onready var spawner_entity := get_node_or_null(entity_path)


##############################################################################

# virtual methods


#func _ready():
#	pass


##############################################################################

# public methods


# object pooling system which will reference inactive/active registers of
# entities and either create a new entity, or reuse an old disabled entity.
# returns null if invalid
func spawn() -> void:
	if not is_enabled:
		return
	var new_entity
	# attempt to create a new entity if there are no unused entities available
	if inactive_entities.empty():
		new_entity = _new_spawn()
	# else use the oldest entity in the inactive entity register
	else:
		#//note: better to use pop back and update active register?
		new_entity = inactive_entities[0]
		_on_entity_enabled(new_entity)
	
	# check if valid,
	# must be correct class (or extended from) and inside tree
	var entity_spawn_successful := false
	if new_entity is EntityArea:
		if new_entity.is_inside_tree():
			# start of spawn process
			emit_signal("entity_spawning", new_entity)
			new_entity.global_position = global_position+spawn_offset
			entity_spawn_successful = true
			# end of spawn process
			emit_signal("entity_spawned", new_entity)
	# invalid endpoint, log
	if not entity_spawn_successful:
		GlobalDebug.log_error(CLASS_NAME, "spawn", "invalid entity")


##############################################################################

# private methods


func _assign_entity_parent(
		passed_entity: EntityArea,
		force_parent_change: bool = false
		) -> void:
	# if already in the tree, force a parent change or abandon
	if passed_entity.is_inside_tree():
		if force_parent_change:
			passed_entity.get_parent().call_deferred("remove_child", passed_entity)
			yield(passed_entity, "tree_exited")
		# if in tree already, do nothing
		else:
			return
	
	match entity_parent:
		SPAWN_PARENT.GLOBAL_POOL:
			GlobalPool.call_deferred("add_child", passed_entity)
		SPAWN_PARENT.SPAWNER_SELF:
			self.call_deferred("add_child", passed_entity)
		SPAWN_PARENT.SPAWNER_OWNER:
			owner.call_deferred("add_child", passed_entity)
		SPAWN_PARENT.SCENE_TREE_ROOT:
			get_tree().root.call_deferred("add_child", passed_entity)


# from the spawner's 'force_properties' dict assigns properties (by dict key)
# in the entity
# assigns properties in the passed entity (getting them by the keys within
# the spawners 'force_properties' dict) to the values within the 'force_properties' dict
func _force_entity_properties(
		passed_entity: EntityArea
		):
	for property_name in force_properties.keys():
		if (typeof(property_name) == TYPE_STRING):
			# Assigns a value to the given property. If the property doesn't
			# exist or the given value's type doesn't match, nothing will happen.
			passed_entity.set(property_name, force_properties[property_name])


# prioritise duplication spawning method
# returns null if unable to spawn an entity
func _new_spawn():
	var new_entity = null
	# spawn_method duplicate root entity
	if (spawn_method == NEW_SPAWN_METHOD.EITHER)\
	or (spawn_method == NEW_SPAWN_METHOD.DUPLICATE):
		if spawner_entity is EntityArea:
			new_entity = _new_spawn_by_duplicate()
	# spawn_method instance entity from premade scene
	if (spawn_method == NEW_SPAWN_METHOD.EITHER)\
	or (spawn_method == NEW_SPAWN_METHOD.INSTANCE):
		if entity_area_scene != null:
			new_entity = _new_spawn_by_instance()
	#
	# if valid, update the registers
	if new_entity is EntityArea:
		_on_entity_enabled(new_entity)
		# when the entity changes active state it should update the spawner's
		# 'active_entities' and 'inactive_entities' registers
		new_entity.connect("_on_entity_disabled", self,
				"_entity_disabled", [new_entity])
		# if new entity, assign it a parent and add it to the tree
		_assign_entity_parent(new_entity)
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


# gateway for _entity_state_update, called if entity emits 'is_enabled' signal
func _on_entity_enabled(arg_entity_node: EntityArea):
	if (arg_entity_node in inactive_entities):
		inactive_entities.erase(arg_entity_node)
	if not (arg_entity_node in active_entities):
		active_entities.append(arg_entity_node)
	# if not in tree, add a parent
	if not arg_entity_node.is_inside_tree():
		_assign_entity_parent(arg_entity_node, true)


# gateway for _entity_state_update, called if entity emits 'is_disabled' signal
func _on_entity_disabled(arg_entity_node: EntityArea):
	if (arg_entity_node in active_entities):
		active_entities.erase(arg_entity_node)
	if not (arg_entity_node in inactive_entities):
		inactive_entities.append(arg_entity_node)



##############################################################################

