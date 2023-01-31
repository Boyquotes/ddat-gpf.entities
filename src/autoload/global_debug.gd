extends GameGlobal

#class_name GlobalDebug

##############################################################################

# DDAT Debug Manager (or, GlobalDebug) is a singleton designed to aid in
# debugging projects, through error logging, faciliating exposure  of game
# parameters to the developer, and allowing the developer to quickly add
# 'god-mode' actions accessible through a simple UI.
#
# DEPENDENCIES
# Set as an autoload *BEFORE* DDAT_Core.GlobalData
# Set as your first autoload, or as early as you can.

# TODO
#// add variation of logError that is just for minor errors (never pushes)

##############################################################################

# the debug info overlay is a child scene of GlobalDebug which is hidden
# by default in release builds (and visible by default in debug builds),
# consisting of a vbox column of key/value label node pairs on the side
# of the viewport. This allows the developer to set signals or setters within
# their own code to automatically push changes in important values to somewhere
# visible ingame. This is useful to get feedback in unstable release builds.
signal update_debug_overlay_item(item_key, item_value)

# for passing to error logging
const SCRIPT_NAME := "GlobalDebug"

# developer flag, if set then all errors called through the log_error method
# will pause project execution through a false assertion (this functionality
# only applies to project builds with the debugger enabled).
# This flag has no effect on non-debugger/release builds.
const ASSERT_ALL_ERRRORS := false
# developer flag, if set all errors called through log_error will, in any
# build with the debugger enabled, raise the error in the debugger instead of
# as a print statement. No effect on non-debugger/release builds.
const PUSH_ERRORS_TO_DEBUGGER := true
# developer flag, if set the debugger will print a full stack trace (verbose),
# when log_error encounters an error. If unset only a partial/pruned stack
# trace will be included. No effect on non-debugger/release builds.
const PRINT_FULL_STACK_TRACE := true

# the log_success method is intended to be used in conjunction with a bool
# passed by the calling script, a constant in the caller's scope which
# can be toggled on a script-by-script basis in order to provide finer
# logging/debugging control.
# if the dev prefers, they may enable this constant to force every call to
# the log_success method to run, regardless of the calling script's flag
const FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS := false

# This flag disables all log_error and log_success calls.
# This setting overrides all others, including any above 'FORCE_' constants.
# Enable this setting if you suspect your logging calls are becoming a
# performance drain and you would like to temporarily suspend them to improve
# game performance. Try to identify excessive calls instead of relying on this.
const OVERRIDE_DISABLE_ALL_LOGGING := false

# as with the constant OVERRIDE_DISABLE_ALL_LOGGING, this variable denies
# all logging calls. It is set and unset as part of the log_test method.
# Many unit tests will purposefully 
var _is_test_running = false

###############################################################################


# debug manager prints some basic information about the user when ready
# with stdout.verbose_logging
func _ready():
	# get basic information on the user
	var user_datetime = OS.get_datetime()
	var user_model_name = OS.get_model_name()
	var user_name = OS.get_name()
	
	# convert the user datetime into something human-readable
	var user_date_as_string =\
			str(user_datetime["year"])+\
			"/"+str(user_datetime["month"])+\
			"/"+str(user_datetime["day"])
	# seperate into both date and time
	var user_time_as_string =\
			str(user_datetime["hour"])+\
			":"+str(user_datetime["minute"])+\
			":"+str(user_datetime["second"])
	
	print("debug manager readied at: "+\
			user_date_as_string+\
			" | "+\
			user_time_as_string)
	print("[user] {name}\n{model}".format({\
			"name": user_name,\
			"model": user_model_name}))


###############################################################################

#// DEPRECATED since devDebugOverlay can just connect to globalDebug signals

## this method is called by the dev debug overlay to establish a connection
## arg is the node to set as the dev debug overlay for globalDebug
#func establish_dev_debug_overlay(caller: DevDebugOverlay):
#	# if this has already been run successfully, ignore
#	if is_dev_debug_overlay_connected:
#		return OK
#
#
#	# if the dev debug overlay was already set once, ignore
#	# do not attempt to set more than one node as the dev debug overlay
#	if dev_debug_overlay_node != null:
#		return ERR_ALREADY_EXISTS
#
#	# if this is the first caller then set as the dev debug overlay
#	dev_debug_overlay_node = caller
#	# establish connection of associated method
#	connect("update_debug_info_overlay",
#			dev_debug_overlay_node, "_update_debug_item_container")
#	is_dev_debug_overlay_connected = true


###############################################################################


# [Usage]
# use GlobalDebug.log_error() in methods at points where you do not expect
# the project to reach during normal runtime
# it is best practice to at least call this method with the name of the calling
# script and an identifier for the method, as release builds (non-debugger
# enabled builds) cannot pass detailed stack information.
# As an optional third argument, you may pass a more detailed string or
# code to help you locate the error.
# in release builds only these arguments will be printed to console/log.
# in debug builds, depending on developer settings, stack traces, error
# warnings, and project pausing can be forced through this method.
func log_error(\
		calling_script: String = "",\
		calling_method: String = "",\
		error_string: String = "") -> void:
	# if suspending logging, stop immediately
	if OVERRIDE_DISABLE_ALL_LOGGING\
	or _is_test_running:
		return
	
	# build error string through this method then print at end of method
	# open all errors with a new line to keep them noticeable in the log
	var print_string = "\nDBGMGR raised error"
	
	# whether release or debug build, basic information must be logged
	if calling_script != "":
		print_string += " at {script}".format({"script": calling_script})
	
	if calling_method != "":
		print_string += " in {method}".format({"method": calling_method})
		
	if error_string != "":
		print_string += " [error code: {error}]".format({"error": error_string})
	
	# debug builds have additional error logging behaviour
	if OS.is_debug_build():
		# get stack trace, split into something more readable
		var full_stack_trace = get_stack()
		var error_stack_trace = full_stack_trace[1]
		var error_func_id = error_stack_trace["function"]
		var error_node_id = error_stack_trace["source"]
		var error_line_id = error_stack_trace["line"]
		# entire stack trace is verbose, so multi-line for readability
		
		print_string += "\nStack Trace: [{f}] [{s}] [{l}]".format({\
				"f": error_func_id,
				"s": error_node_id,
				"l": error_line_id})
		print_string += "\nFull Stack Trace: "
	
	# close all errors with a new line to keep them noticeable in the log
	print_string += "\n"
	
	# with debugger running, and flag set, push as error rather than log print
	if OS.is_debug_build() and PUSH_ERRORS_TO_DEBUGGER:
		push_error(print_string)
	# print regardless
	print(print_string)
	
	# if the appropriate flag is enabled, pause project on error call
	if OS.is_debug_build() and ASSERT_ALL_ERRRORS:
		assert(false, "fatal error, see last error")


# [Usage]
# use GlobalDebug.log_success in methods at points where you expect the
# project to reach during normal runtime
# it is best practice to call this method with at least the script name, and
# the method name, as release builds (non-debugger enabled builds) cannot
# pass detailed stack information.
# unlike with its counterpart log_error, log_success requires the calling
# script's name or id (str(self) will suffice) and calling method to be passed
# as arguments. This is to prevent log_success calls being left in the
# release build without a quick means of identifying where the call was made.
# [Rationale]
# LogSuccess is a replacement for the dev practice of leaving print statements
# in a release-candidate build as a method of debugging. It should be used
# in conjunction with a script-scope bool passed as the first argument. This
# flag can be disabled per script to provide finer debugging control.
# Devs can enable the FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS to ignore the
# above behaviour and always print log_success calls to console.
# [Disclaimer]
# LogSuccess is not intended as catch-all solution, it is to be used in
# conjunction with testing, debug builds, and debugging tools such as
# the editor debugger and inspector.
func log_success(
		verbose_logging_enabled: bool,\
		calling_script: String,\
		calling_method: String,\
		success_string: String = "") -> void:
	# if suspending logging, stop immediately
	if OVERRIDE_DISABLE_ALL_LOGGING\
	or _is_test_running:
		return
	
	# log success is a debugging tool that should always be passed a bool
	# from the calling script; if the bool arg is false, and the optional
	# dev flag FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS isn't set, this
	# method will not do anything
	if not verbose_logging_enabled\
	and not FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS:
		return
	
	# build the print string from arguments
	var print_string = ""
	print_string += "DBGMGR.log({script}.{method})".format({\
			"script": calling_script,
			"method": calling_method,
			})
	
	# if an optional argument was included, append it ehre
	if success_string != "":
		print_string += " [{success}]".format(\
				{"success": success_string})
	
	print(print_string)


# decorator for running a test function with globalDebug logging disabled
# returns a comparison of expected outcome and the bool result of the unit test
##1, 'unit_test', should be a function that returns a bool
##2, 'expected_outcome', is the bool you expect the func in param1 to return
func log_test(
		unit_test: FuncRef,
		expected_outcome: bool):
	# for checking whether the funcRef is set up correctly
	# and whether it returns a bool
	var is_test_valid: bool
	var test_outcome: bool
	
	# first, check the funcRef validity
	is_test_valid = unit_test.is_valid()
	
	# if can run the test
	if is_test_valid:
		# disable logging then run the function
		self._is_test_running = true
		test_outcome = unit_test.call_func()
		self._is_test_running = false
		# check return argument was valid
		if typeof(test_outcome) == TYPE_BOOL:
			is_test_valid = true
		else:
			is_test_valid = false
	
	# logging statement for test
	if is_test_valid:
		var compare_outcomes = (expected_outcome == test_outcome)
		var log_string =\
				"SUCCESS - test outcome matches expected outcome."\
				if compare_outcomes else\
				"FAILURE - test outcome does not match expected outcome."
		
		print("DBGMGR.log_test.{x} [{r}]".format({
			"x": str(unit_test.function),
			"r": log_string
		}))
		return compare_outcomes
	
	# if either validation test failed
	if not is_test_valid:
		GlobalDebug.log_error(SCRIPT_NAME, "log_test",
				"invalid test, is not valid funcref or does not return bool")


# update_debug_info is a method that interfaces with the debug_info_overlay
# child of GlobalDebug (automatically instantiated at runtime)
# arg1 is the key for the debug item.
# this argument should be different when the dev wishes to update the debug
# info overlay for a different debug item, e.g. use a separate key for player
# health, a separate key for player position, etc.
# arg1 shoulod always be a string key
# arg2 can be any type, but it will be converted to string before it is set
# to the text for the value label in the relevant debug info item container
func update_debug_overlay(debug_item_key: String, debug_item_value) -> void:
	# everything works, pass on the message to the canvas info overlay
	# validation step added due to strange method-not-declared bug that
	# ocassionally occurs
	emit_signal("update_debug_overlay_item",
			debug_item_key,
			debug_item_value)

