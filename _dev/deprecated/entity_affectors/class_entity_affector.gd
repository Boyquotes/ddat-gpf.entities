extends Area2D

#class_name EntityAffector

##############################################################################

# Parent class to the Projectile and AreaOfEffect classes

# This class is designed so that it can be used without a root scene, instead
# configuring itself and adding required child nodes automatically.
# It will create a child Sprite and CollisionShape2D based on initial args.

# For performance do not instantiate these scenes on demand; instead create an
# entity node as a child in the scene that creates the entity, and
# set the exported .is_root property on said entity to 'false'. Then have the
# creating scene call .duplicate() on a creation event. Newly duplicated scenes
# will already have the texture and collision nodes set up.

# Projectiles and AreaOfEffect will need some additional args configured
# either in-editor, on-init, or via code, in order to have expected behaviour.

##############################################################################

# do not set this normally, set only on sample entities you wish your
# spawners to call .duplicate() from. Root entities do not have behaviour,
# as though they had the 'is_active' or 'is_valid' flag unset.
export(bool) var _is_root: bool = false setget _set_is_root
# exports that are used to build the child Sprite
export(Texture) var ex_sprite_texture: Texture
export(Shape2D) var ex_collision_shape: Shape2D

# references to child nodes
var my_sprite_node: Sprite
var my_collision_node: CollisionShape2D

# set when the entity is enabled, must be called by the spawner
# can be unset when the entity should be disabled (i.e. destroyed/despawns)
var _is_active: bool = false setget _set_is_active
# can be set based on the entity setup checks
var _is_valid: bool = true setget _set_is_valid

##############################################################################

# setters and getters


func _set_is_root(value):
	_is_root = value
	# check if entity state has changed
	_enable_entity()


func _set_is_active(value):
	_is_active = value
	# check if entity state has changed
	_enable_entity()


func _set_is_valid(value):
	_is_valid = value
	# check if entity state has changed
	_enable_entity()


##############################################################################

# virtual init methods


# on init you can override the (default null) vars or leave them to their values
# if instantiated in-editor you can set the values there
# if instantiated via code opt to override the values
func _init(
		arg_texture: Texture = ex_sprite_texture,
		arg_shape: Shape2D = ex_collision_shape):
	self.ex_sprite_texture = arg_texture
	self.ex_collision_shape = arg_shape


##############################################################################

# virtual ready methods


# set up sprite and collider if not already found
func _ready():
	_ready_entity_sprite_node()
	_ready_entity_collider_node()
	# after all setup, call setters
	self._is_root = _is_root
	self._is_active = _is_active
	self._is_valid = _is_valid


# first time entering scene tree if there is not yet a sprite child node set
# up, create it. If the relevant export isn't set, or the relevant node
# reference is set, the method won't progress.
func _ready_entity_sprite_node():
	var new_sprite
	if ex_collision_shape != null\
	and my_collision_node == null:
		new_sprite = CollisionShape2D.new()
		new_sprite.shape = ex_collision_shape
		my_collision_node = new_sprite
	#
	if new_sprite != null:
		call_deferred("add_child", new_sprite)


# first time entering scene tree if there is not yet a collision shape child
# node set up, create it. If the relevant export isn't set, or
# the relevant node reference is set, the method won't progress.
func _ready_entity_collider_node():
	var new_collider
	if ex_collision_shape != null\
	and my_collision_node == null:
		new_collider = CollisionShape2D.new()
		new_collider.shape = ex_collision_shape
		my_collision_node = new_collider
	#
	if new_collider != null:
		call_deferred("add_child", new_collider)


##############################################################################

# public methods


# returns if the entity is enabled, i.e. isn't root, is active, is valid
# root entities are placeholder entities to duplicate, for spawner use
# inactive entities are entities that have been destroyed or are despawning
# invalid entities are entities who failed their instantiation checks
# these are all flags the dev can configure to control entity behaviour
func get_enabled():
	if _is_root == false\
	or _is_active == false\
	or _is_valid == false:
		return false
	# else
	return true
#	return (true and _is_root and _is_active and _is_valid)


##############################################################################

# private methods


# whenever the entity sets one of the three behaviour controlling flags
# (root, active, valid)
# check to see if all three are true, or if any are false
# entity behaviour is disabled whilst any flag is false
# a disabled entity will not monitor or be monitored by other collision
# objects, will ignore process behaviours, and be hidden from player view.
# calls to entity methods can still proceed as normal if the dev has not
# included any get_enabled() checking in the method logic.
func _enable_entity():
	var entity_state = get_enabled()
	monitoring = entity_state
	monitorable = entity_state
	if my_collision_node != null:
		my_collision_node.disabled = !entity_state
	visible = !entity_state
	set_process(entity_state)
#	set_process_input(entity_state)
	set_physics_process(entity_state)

