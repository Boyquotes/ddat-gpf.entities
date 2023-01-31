extends Control

#class_name DevActionMenu

##############################################################################

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

# DEPENDENCY: GlobalDebug

# NOTES

# [debug action menu feature list]
# - disclaimer at top of menu informing devs to add buttons if none are present
# - command line input for written dev commands
# - keyboard/input typing solution as part of ddat_core
# - dict to add a new method, key is button text and value is method name in file
# - after dev updates dict they add a method to be called when button is pressed
# - buttons without found methods aren't shown when panel is called
# - globalDebug adds action under F2 (default0 for showing debug action panel (auto-behaviour, can be overriden)

##############################################################################
#
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#
#05. signals
#06. enums

#07. constants
# for passing to error logging
const SCRIPT_NAME := "script_name"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true

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

