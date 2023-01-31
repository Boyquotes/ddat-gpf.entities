
# This is a slightly modified version of the 3.0 (rev 5f5a9378)  style guide
# Changes are documented below with <- indicators
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
#
#01. tool
#02. extends <- switched with class_name (originally 02.)
#03. class_name <- switched with extends (originally 03.)
#
##############################################################################
#
#04a. dependencies <- new addition
#
#04b. # docstring
#
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

