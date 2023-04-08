extends GameGlobal

#class_name GlobalFunc

##############################################################################

# GlobalFunctions

#//TODO
# need to move to ddat-gpf.core

##############################################################################


# return argument depends on passed 'is_added' argument
# returns true on (is_added==true) if connection was added or already existed
# returns true on (is_added==false) if connection was removed or didn't exist
func confirm_signal(
		is_added: bool,
		sender: Node,
		recipient: Node,
		signal_string: String,
		method_string: String,
		binds: Array = []
		) -> bool:
	#
	var signal_return_state := false
	var signal_modify_state := OK
	#
	if is_added:
		# on (is_added == true)
		# if signal connection already exists or was successfully added,
		# return true
		if not sender.is_connected(signal_string, recipient, method_string):
			signal_modify_state =\
					sender.connect(signal_string, recipient, method_string, binds)
			# signal didn't exist so must be connected for return state to be valid
			signal_return_state = (signal_modify_state == OK)
		# if already connected under (is_added == true), is valid
		else:
			signal_return_state = true
	#
	elif not is_added:
		# on (is_added == false)
		# if signal connection does not already exist or was successfully
		# removed, return true
		if sender.is_connected(signal_string, recipient, method_string):
			sender.disconnect(signal_string, recipient, method_string)
			# no err code return on disconnect, so assume successful
			signal_return_state = true
		# if not already connected under (is_added == false), is valid
		else:
			signal_return_state = true
		
	return signal_return_state

# DOES NOT WORK AS INTENDED - you cannot pass a reference to a freed node
# in order to create a weak reference from
# you would have to create a weak reference to pass to the autoload, at which
# point you're not saving any time or readability when you could just
# directly call the .get_ref() method on that weakref then and there
#
# ORIGINAL
## returns whether or not an object has been previously freed
## this is a failsafe if it is impossible to be sure whether an object has
## been deleted or not
## (utilising object pooling behaviour is preferred practice within ddat-gpf)
#func object_is_valid(arg_object: Object) -> bool:
#	return weakref(arg_object).get_ref()

