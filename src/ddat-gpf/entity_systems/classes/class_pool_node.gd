extends ObjectPool

class_name NodePool
#
##############################################################################
#
# NodePools function as object pools, except they have behaviour for 
# interacting with the scene tree in addition to the default objectPool
# behaviour. NodePools should be preferred over ObjectPools, unless the
# class in question does not extend from node.

##############################################################################
#
# dev use only, for passing to error logging
const SCRIPT_NAME := "NodePool"
# dev use only, make sure to unset when not testing
const VERBOSE_LOGGING := false

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

# spawn parent is an option for where to place newly created and reused
# objects within the scene tree
var spawn_parent: int = PARENT.GLOBAL_POOL setget _set_spawn_parent

# if node parent doesn't match the parent type specified in spawn_parent,
# change the node parent whenever the node is activated by the object pool
# if set false, ignore this behaviour
var reset_parent_on_reuse := false

##############################################################################

# setters and getters


# spawn_parent only accepts values from the PARENT enum
func _set_spawn_parent(arg_value: int):
	if arg_value in PARENT.values():
		spawn_parent = arg_value


##############################################################################

# virtual methods


#func _ready():
#	pass


##############################################################################

# public methods


#func _placeholder_dostuff():
#	pass


##############################################################################

# private methods

## registers that an object waiting to join the pool has managed to do so
## [parameters]
## #1, 'arg_object_ref', object to change the parent of
#func _on_object_joined_pool(arg_object_ref: Object):
#	pass


# sets the parent of a node according to the 'spawn_parent' property
# and PARENT enum
# [parameters]
# #1, 'arg_object_ref', object to change the parent of
func _set_object_parent(arg_object_ref: Object):
	arg_object_ref = arg_object_ref
	pass
