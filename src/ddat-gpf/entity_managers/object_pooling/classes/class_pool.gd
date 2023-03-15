extends Node

#class_name ObjectPool
#
##############################################################################
#
# ObjectPools track objects from a specific class, cataloguing which are
# active and which are inactive. Instead of instancing new objects 

# need to make this part of ddat-gpf

# behaviour
# on instance:
#	which signals determine an object turning inactive or active
#	connect correct signals to the pool
#	which properties should be set/unset when the object turns inactive 

##############################################################################
#
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#
#05. signals
#06. enums
#
#07. constants
# for passing to error logging
const SCRIPT_NAME := "script_name"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true
#
#08. exported variables
#09. public variables
#10. private variables
#11. onready variables
#
##############################################################################
#
#12. optional built-in virtual _init method
#13. built-in virtual _ready method
#14. remaining built-in virtual methods
#15. public methods
#16. private methods

##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

