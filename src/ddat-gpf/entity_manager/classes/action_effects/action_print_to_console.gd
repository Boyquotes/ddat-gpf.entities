extends ActionEffect

class_name ActionEffectPrintToConsole

##############################################################################
#
# An ActionEffect where it prints the provided statement when called.
#
# This is intended for developer/test environment use, and as an example
# actionEffect, not as an actual production actionEffect.
#
##############################################################################

# the string to be printed
export(String) var print_string := ""

##############################################################################

# shadows the parent method
func _action_function():
	print(print_string)

