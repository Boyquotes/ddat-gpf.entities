extends Node2D

#
##############################################################################
#
# Sample Scene to demonstrate the functionality of GlobalDebug
# This currently covers:
# [ ] error logging
# [ ] success logging
# [X] the developer debugging overlay
# [ ] the developer action menu

#//TODO for globalDebug sample scene
# line with and without verbose_logging arguments (comment explaining why again, refernce notes on log_success/how it works),
# behaviour of debugInfoOverlay via tracking data like player input, time since scene started
# behaviour/implementation of both devMode action buttons and devMode command line,
# scene text background showing what key to press to call debugOverlay or devModeMenu (default to on/off)
#
##############################################################################

# for passing to error logging
const SCRIPT_NAME := "ddat-gpf.core debug manager sample scene"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true

# which events to monitor (generated from project inputMap)
var monitored_events := []
# record of how many times a monitored event has been pressed
var pressed_event_register := {}

# timer of how many seconds have passed since scene started
var scene_duration_seconds := 0
var scene_duration_minutes := 0
var scene_duration_hours := 0

##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	# test values
#	GlobalDebug.update_debug_overlay("testlabel2", 45)
#	GlobalDebug.update_debug_overlay("testlabel3", "supercallifragilistic")
#	GlobalDebug.update_debug_overlay("testlabel4", true)
#	GlobalDebug.update_debug_overlay("testlabel5", HBoxContainer)
#	GlobalDebug.update_debug_overlay("testlabel6_with_a_longer_name", self.position)
	#
	for action_string in InputMap.get_actions():
		monitored_events.append(action_string)
	
	# initial scene duration push to overlay
	update_scene_duration_string()
	
#	if 2 >= 3:
#		GlobalDebug.log_success(VERBOSE_LOGGING, SCRIPT_NAME,
#				"_ready", "math.broken")
#	else:
#		GlobalDebug.log_error(SCRIPT_NAME,
#				"_ready", "2 is not greater or equal to 3")
	
	GlobalDebug.log_test(funcref(self, "unit_test_math_is_valid"), true)
	GlobalDebug.log_test(funcref(self, "unit_test_false_is_false"), false)
	GlobalDebug.log_test(funcref(self, "unit_test_false_is_false"), true)


func _input(event):
	var increment := 1
	for action_string in monitored_events:
		if event.is_action_pressed(action_string):
			if action_string in pressed_event_register:
				pressed_event_register[action_string] += increment
			else:
				pressed_event_register[action_string] = increment
			# action string key, instances for value
			GlobalDebug.update_debug_overlay(
					action_string,
					pressed_event_register[action_string])


func update_scene_clock_vars():
	if scene_duration_seconds >= 60:
		scene_duration_seconds = 0
		scene_duration_minutes += 1
	if scene_duration_minutes >= 60:
		scene_duration_minutes = 0
		scene_duration_hours += 1


func update_scene_duration_string():
	var duration_string := ""
	var hours_elapsed_as_string := "0"
	var minutes_elapsed_as_string := "00"
	var seconds_elapsed_as_string := "00"
	
	if scene_duration_hours > 0:
		hours_elapsed_as_string = str(scene_duration_hours)
	
	if scene_duration_minutes > 0:
		minutes_elapsed_as_string = str(scene_duration_minutes)
	
	# account for 01 -> 09
	var scene_seconds_elapsed_as_string = str(scene_duration_seconds)
	if scene_seconds_elapsed_as_string.length() == 1:
		scene_seconds_elapsed_as_string =\
				"0"+scene_seconds_elapsed_as_string
		seconds_elapsed_as_string = scene_seconds_elapsed_as_string
	else:
		seconds_elapsed_as_string = str(scene_duration_seconds)
	
	duration_string =\
			hours_elapsed_as_string + ":" +\
			minutes_elapsed_as_string + ":" +\
			seconds_elapsed_as_string
	
	# push to debug overlay
	GlobalDebug.update_debug_overlay(
		"Scene Duration",
		duration_string
	)


# sample unit test
func unit_test_math_is_valid() -> bool:
	if 2 < 3:
		return true
	else:
		return false


# sample unit test
func unit_test_false_is_false() -> bool:
	var false_statement = false
	# added log call to test whether the call is blocked by log_test
	GlobalDebug.log_error(SCRIPT_NAME, "unit_test_false_is_false",
			"this error should never be logged if log_test is blocking "+\
			"calls to log_error and log_success properly.")
	return false_statement



func _on_SceneDuration_timeout():
	scene_duration_seconds += 1
	update_scene_clock_vars()
	update_scene_duration_string()
