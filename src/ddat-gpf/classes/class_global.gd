extends Node

class_name GameGlobal

##############################################################################
#
# GameGlobal is the base class of all DDAT Globals
# Its purpose is twofold.
#	1) Avoid duplication of code between globals.
#	2) Allow configuration options to be easily set on all globals.
#
##############################################################################

# whether to log comprehensive information about the global classes behaviour
# this is for developer debugging purposes and shouldn't be set normally
var verbose_logging = false

##############################################################################
#
#12. optional built-in virtual _init method
#13. built-in virtual _ready method
#14. remaining built-in virtual methods
#15. public methods
#16. private methods

##############################################################################


## Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


##############################################################################


#const RELEASE_BUILD_VERBOSE_LOGGING := false
#const DEBUG_BUILD_VERBOSE_LOGGING := false
#
#var enable_verbose_logging := false
#
#var _override_verbose_logging = null setget _set_override_verbose_logging
#
###############################################################################
#
#
## can manually set on singletons to disable verbose logging when unnecessary
## globalAudio.play() I'm looking at you
#func _set_override_verbose_logging(value):
#	if value is bool\
#	or value == null:
#		_override_verbose_logging = value
#	if value is bool:
#		enable_verbose_logging = value
#
#
## Called when the node enters the scene tree for the first time.
#func _ready():
#	# all globals should continue to be accessible and operational
#	# within a tree pause state; it is up to the global script itself
#	# to handle what should happen whilst in a tree pause state, if such
#	# a case is relevant to its functionality
#	self.pause_mode = PAUSE_MODE_PROCESS
#
#	# toggle verbose logging for globals
#	var get_if_release
#	get_if_release = !OS.is_debug_build()
#	# must have release verbose log constant set and not be debug build
#	# or must have debug version of constant set and be debug build
#	if (RELEASE_BUILD_VERBOSE_LOGGING and get_if_release)\
#	or (DEBUG_BUILD_VERBOSE_LOGGING and !get_if_release):
#		enable_verbose_logging = true
#	else:
#		enable_verbose_logging = false
#

##############


func _ready():
	if verbose_logging:
		log_on_ready(name, true)
	_preload()


###############################################################################


#// TODO add this to ddat-gpf.core
# shadow this in derived classes
# this method is called by the preload handler as part of the runtime framework
# individual singletons that need to load from disk can signal to globalData
# to load their required resources at this time.
func _preload():
	pass


###############################################################################

func log_on_ready(singleton_name: String, is_readied: bool = false):
	var readying_is_readied = "ready!" if is_readied else "readying..."
	print(" ###[{name}]### {statement}".format(\
			{"name" : singleton_name,\
			"statement" : readying_is_readied}))
#
#
#func autoload_method_logging(\
#		singleton_name: String,\
#		method_name: String,\
#		passed_arg_names: Array = [],
#		passed_args: Array = []):
#	# match the args of each array whilst there's still some left
#	var args_parsed = " with args: "
#	while not passed_arg_names.empty() and not passed_args.empty():
#		var arg_string = "\n {arg_name}: [{arg}]".format(\
#		{"arg_name": str(passed_arg_names.pop_front()),\
#		"arg": str(passed_args.pop_front())})
#		args_parsed += arg_string
##	 {arg_list}
#	print(" #[{s_name} calling {m_name}]#{arg_statement}".format(\
#	{"s_name": singleton_name,
#	"m_name": method_name,
#	"arg_statement": args_parsed}))

