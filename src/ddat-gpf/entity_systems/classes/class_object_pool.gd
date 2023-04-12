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
var forced_properties_on_init = {}

# the following properties function as the 'forced_properties_on_init'
# property, but override only when the object is registered as 'active' or
# 'inactive' by its corresponding objectPool.
# devnote: take care in assigning frequently used properties here, as these
#	properties will be assigned *every* time that the objectPool registers
#	the object as active/inactive (i.e. every time it is reused)
#	As such this property is best used for per-class flags to indicate
#	it can do things again.
# overrides for when registered as 'active' by the objectPool
var forced_properties_on_active = {}
# overrides for when registered as 'inactive' by the objectPool
var forced_properties_on_inactive = {}

##############################################################################

#//TODO
# method to set default properties
# method to change active/inactive state (and force properties)
# method to remove an object from the objectPool
# method to spawn by instancing
# spawn method arguments that can override forced/default properties

# older notes
# behaviour
# on instance:
#	which signals determine an object turning inactive or active
#	connect correct signals to the pool
#	which properties should be set/unset when the object turns inactive 

# virtual methods


# initialising a new objectPool
# [parameters]
# #1, arg_object_scene is the target scene you wish the objectPool to manage,
#	and instantiate on any 'spawn' method calls
#	(see 'target_scene' for more detail)
# #2, arg_forced_properties is a dictionary register of properties you wish to
#	automatically set on any 
#	(see 'forced_properties_on_init' for more detail)
# #3, arg_forced_on_active is as the above except occurs when an object is
#	registered as 'active' by the objectPool
#	(see 'forced_properties_on_active' for more detail)
# #4, arg_forced_on_inactive is as the above except occurs when an object is
#	registered as 'inactive' by the objectPool
#	(see 'forced_properties_on_inactive' for more detail)
func _init(
		arg_object_scene: PackedScene,
		arg_forced_properties: Dictionary = {},
		arg_forced_on_active: Dictionary = {},
		arg_forced_on_inactive: Dictionary = {}
		):
	self.target_scene = arg_object_scene
	self.forced_properties_on_init = arg_forced_properties
	self.forced_properties_on_active = arg_forced_on_active
	self.forced_properties_on_inactive = arg_forced_on_inactive


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################

# public methods

##############################################################################

# private methods

##############################################################################

