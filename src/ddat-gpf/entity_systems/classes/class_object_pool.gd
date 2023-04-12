extends Node

class_name ObjectPool
#
##############################################################################
#
# ObjectPools track objects from a specific class, cataloguing which are
# active and which are inactive. Instead of instancing new objects 

##############################################################################
#
# dev use only, for passing to error logging
const SCRIPT_NAME := "ObjectPool"
# dev use only, make sure to unset when not testing
const VERBOSE_LOGGING := false

##############################################################################

# signal for manually adding an object to the pool
signal object_added(object)
# signal for an object being instantiated by the poool
signal object_created(object)
# signal for manually removing an object from the pool
signal object_removed(object)
# signals for if the objectPool changes the active register state of an object
# if object is added to register as active, or changed to be active
signal object_active(object)
# if object is added to register as inactive, or changed to be unactive
signal object_inactive(object)

# the location to place the object within the scene tree, if it currently
# does not have a parent or the 'reset_parent_on_reuse' property is set
# when the object becomes active
# GLOBAL_POOL - the object is set as a child of the autoload, GlobalPool,
#	if the autoload is found (defaults to ROOT if the autoload is not found)
# SELF - the object is set as a child of the objectPool node itself, if the
#	pool itself is inside the scene tree (default to ROOT if not)
# ROOT - the object is added to the scene tree root
#	(this is the default and fallback setting)
enum PARENT {GLOBAL_POOL, SELF, ROOT}

# arguments for the _set_object_properties method
# each corresponds to one of the 'set_on_' properties ('set_on_init',
# 'set_on_active', or 'set_on_inactive')
# each property allows forcing properties on objects
# INITIAL - corresponds to 'set_on_init', for properties set when objects
#	are added to the pool initially
# ACTIVE - corresponds to 'set_on_active', for properties set when objects
#	are moved to the pool's active register
# INACTIVE - corresponds to 'set_on_inactive', for properties set when
#	objects are moved to the pool's inactive register
enum PROPERTY_REGISTER {INITIAL, ACTIVE, INACTIVE}

# the packed scene which is the object to be instanced
var target_scene: PackedScene

# record of objects assigned to this objectPool
# key = object
# value = whether the object is an active object
# value of true is set for active objects (objects in the scene tree that
#	are doing things in-game)
# value of false is set for inactive objects (objects that are disabled
#	and can be reused by the objectPool)
var object_register = {}

# automatically set specific properties on new objects
# key = property name, value = property value
# if key is not found in the object, property will not be set on new object
# if value type != property value type, property will not be set on new object
# these properties can be overridden on a per-instance case
# these properties are the default values to assign to a new object
# (this overrides object class defaults)
# if a property isn't found here it will be set to the object's class default
var set_on_init = {}

# the following properties function as the 'set_on_init' property except
# they override only when the object is registered as 'active' or
# 'inactive' by its corresponding objectPool.
# devnote: take care in assigning frequently used properties here, as these
#	properties will be assigned *every* time that the objectPool registers
#	the object as active/inactive (i.e. every time it is reused)
#	As such this property is best used for per-class flags to indicate
#	it can do things again.
# overrides for when registered as 'active' by the objectPool
var set_on_active = {}
# overrides for when registered as 'inactive' by the objectPool
var set_on_inactive = {}

# spawn parent is an option for where to place newly created and reused
# objects within the scene tree
var spawn_parent: int = PARENT.GLOBAL_POOL setget _set_spawn_parent

# if node parent doesn't match the parent type specified in spawn_parent,
# change the node parent whenever the node is activated by the object pool
# if set false, ignore this behaviour
var reset_parent_on_reuse := false

# if object pool falls below this number of inactive objects, the pool
# automatically readies a new object
# this is a useful property for pools whose callers don't want to wait for
# deferred instantiation, ensuring that there is always an inactive object
# waiting to be repurposed
# devnote: multiple calls within the span of a frame may result in the pool
#	not having a readied object nonetheless, and this behaviour subverts the
#	original purpose of the objectPool by constantly readying new objects
var minimum_pool_size := 0

##############################################################################

# setters and getters


# spawn_parent only accepts values from the PARENT enum
func _set_spawn_parent(arg_value: int):
	if arg_value in PARENT.values():
		spawn_parent = arg_value


##############################################################################

# virtual methods


# initialising a new objectPool
# [parameters]
# #1, arg_object_scene, is the target scene you wish the objectPool to manage,
#	and instantiate on any 'spawn' method calls
#	(see 'target_scene' for more detail)
# #2, arg_forced_properties, is a dictionary register of properties you wish to
#	automatically set on any 
#	(see 'set_on_init' for more detail)
# #3, arg_forced_on_active, is as the above except occurs when an object is
#	registered as 'active' by the objectPool
#	(see 'set_on_active' for more detail)
# #4, arg_forced_on_inactive, is as the above except occurs when an object is
#	registered as 'inactive' by the objectPool
#	(see 'set_on_inactive' for more detail)
# #5, arg_initial_pool_size, is the number of objects (instanced from the
#	arg_object_scene given as argument 1) to begin the pool with
#	(be cautious creating large pools as it may have a performance impact)
func _init(
		arg_object_scene: PackedScene,
		arg_forced_properties: Dictionary = {},
		arg_forced_on_active: Dictionary = {},
		arg_forced_on_inactive: Dictionary = {},
		arg_initial_pool_size: int = 0
		):
	self.target_scene = arg_object_scene
	self.set_on_init = arg_forced_properties
	self.set_on_active = arg_forced_on_active
	self.set_on_inactive = arg_forced_on_inactive
	# not currently using created objects, just discarding returned references
	# to them immediately (new objects will be set inactive)
	var _discard_obj
	for i in range(arg_initial_pool_size):
		_discard_obj = _create_object(false)


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################

# public methods


# method to manually add a pre-existing object to the object pool
# the object in question must be a match for the packedScene value of the
# property 'target_scene', otherwise it will not be added
# method returns OK if object was succesfully added, and an ERR code otherwise
# objects manually added to the pool will be subject to the same property
# forcing (see PROPERTY_REGISTER enum) as newly created objects
func add_to_pool(arg_object_ref: Object):
	arg_object_ref = arg_object_ref
	pass


# method to return a valid object
func get_object():
	pass


# method to return the entire contents of the pool
# returns the active register and any pending changes
func get_pool():
	pass


## method to completely remove an object from the object pool
## if an object is removed from the object pool it does not cease to exist,
## it is just no longer tracked by the pool for active/inactive registering
## devnote: once outside the object pool any properties set by active or
##	inactive state will remain as such unless manually changed
#func remove_from_pool(arg_object_ref: Object):
#	arg_object_ref = arg_object_ref
#	pass
#	# state for waiting_to_join_tree, is_active, is_turning_active,
#	# is_inactive, is_turning_inacitve, waiting_to_leave_tree
#	# etc


##############################################################################

# private methods


# method to turn an inactive object within the pool into an active object
# this is a contemporary to the '_create_object' method
func _activate_object(arg_object_ref: Object):
	arg_object_ref = arg_object_ref
	pass


# method to instantiate a new object and add it to the object pool
# this is a contemporary to the '_activate_object' method
# returns null if unable to create object
# is_active argument determines whether to add the new object to the active
# register (if true) or inactive register (if false)
# if attempting to get an object via the 'get_object' method, this should be
# left as the default value of true (for a readied object)
func _create_object(is_active: bool = true):
	return null


# method to turn an active object within the pool into an inactive object
func _deactivate_object(arg_object_ref: Object):
	arg_object_ref = arg_object_ref
	pass


# checks the object_register for the next inactive object
# either returns an object if an inactive object is found, or null if
# no object is currently inactive
# called by the 'get_object' method to check whether a new object needs to be
# created or an object could be reused
func _get_next_inactive_object(arg_object_ref: Object):
	arg_object_ref = arg_object_ref
	pass


# sets the parent of a node according to the 'spawn_parent' property
# and PARENT enum
func _set_object_parent(arg_object_ref: Object):
	arg_object_ref = arg_object_ref
	pass


# sets object properties according to a 'set_on_' properties ('set_on_init',
# 'set_on_active', or 'set_on_inactive')
# see the PROPERTY_REGISTER enum for more detail
# if a property isn't valid for the object (the property can't be found or
# the value is the wrong type) the object's property will not be changed
# [parameters]
# #1, 'arg_object_ref', object to alter the properties of
# #2, 'arg_register_id', value from the PROPERTY_REGISTER enum to select
#	the correct 'set_on' dictionary
func _set_object_properties(
		arg_object_ref: Object,
		arg_register_id: int):
	arg_object_ref = arg_object_ref
	pass


##############################################################################

