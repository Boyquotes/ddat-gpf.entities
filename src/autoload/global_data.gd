extends GameGlobal

#class_name GlobalData

##############################################################################
#
# DDAT Data Manager provides robust and simplified interpretations of the core
# Godot data management methods, and a structure for future DDAT packages.
#
# DEPENDENCIES
# Set as an autoload *AFTER* DDAT_Core.GlobalDebug

#//TODO
#// add (reintroduce) save/load method pair for json-dict
#// add a save/load method pair for config ini file
#// add a save/load method pair for store_var/any node

#// add file backups optional arg (push_backup on save, try_backup on load);
#		file backups are '-backup1.tres', '-backup2.tres', etc.
#		backups are tried sequentially if error on loading resource
#		add customisable variable for how many backups to keep

#// add error logging for failed move_to_trash on save_resource
#// update error logging for save resource temp_file writing

#// add optional arg for making write_directory recursive (currently default)

#// add a minor logging method for get_file_paths (globalDebug update)

#// update save resource method or resourceLoad to handle .backup not .tres
#// add recursive param to load_resources_in_directory

#// update load_resource to try and load resource on fail state

##############################################################################

#05. signals
#06. enums

# for use with const DATA_PATHS and calling the 'build_path' method
enum DATA_PATH_PREFIXES {USER, LOCAL, GAME_SAVE}

#07. constants
# for passing to error logging
const SCRIPT_NAME := "GlobalData"
#// superceded by 'verbose_logging' property of parent class
# for developer use, enable if making changes
#const VERBOSE_LOGGING := true

# the suffix (before file extension) for backups
const BACKUP_SUFFIX := "_backup"

# the path for saved resources
const RESOURCE_FILE_EXTENSION := ".tres"

# fixed record of data paths
# developers can extend this to their needs
const DATA_PATHS := {
	# default path to start save_resource paths with
	DATA_PATH_PREFIXES.USER : "user://",
	# path to use if getting from the local project
	DATA_PATH_PREFIXES.LOCAL : "res://",
	# path for the runtime framework
	DATA_PATH_PREFIXES.GAME_SAVE : "user://saves/",
}


##############################################################################

# virtual methods


# enable verbose logging here if required
#func _ready():
#	verbose_logging = true


##############################################################################

# public methods


# method allows building paths from the DATA_PATHS (dict) database; a record
# which can be extended by the developer to add their own specific nested
# directory paths. This allows for consistent directory referencing.
# this method can be passed a file name argument or directory path to extend
# the fixed data path stored in DATA_PATHS
# [method params as follows]
##1, data_path_key, is a key from DATA_PATH_PREFIXES for DATA_PATHS
##2, file_name, is an extension for the data path, applied last
##3, directory_path, is an extension for the data path, applied first
func build_path(
		data_path_key,
		file_name: String="",
		directory_path: String=""
		) -> String:
	# get the initial data path from the directory
	var full_data_path: String = ""
	var get_fixed_data_path: String
	if data_path_key in DATA_PATHS.keys():
		if typeof(DATA_PATHS[data_path_key]) == TYPE_STRING:
			get_fixed_data_path = DATA_PATHS[data_path_key]# as String
			# build the path
			full_data_path = full_data_path + get_fixed_data_path
	else:
		# returns empty on invalid data_path_key
		GlobalDebug.log_error(SCRIPT_NAME, "build_path",
				"data_path_key {k} not found".format({"k": data_path_key}))
		return ""
	
	# if dirpath not empty, append to the data path
	if directory_path != "":
		# build the path
		full_data_path = full_data_path + directory_path
	
	# if file name not empty, append to the data path
	if file_name != "":
		# build the path
		full_data_path = full_data_path + file_name
	
	# return the path
	return full_data_path


# method to create a directory, required to save resources to directories
# that have yet to be referenced. If the path to the directory consists of
# multiple directories that have yet to be created, this method will create
# every directory specified in the path.
# Does nothing if the path already exists.
# [method params as follows]
##1, absolute_path, is the full path to the directory
##2, write_recursively, specifies whether to write missing directories in
# the file path on the way to the target directory. Defaults to true but
# if specified 
func create_directory(
		absolute_path: String,
		write_recursively: bool = true
		) -> int:
	# object to get directory class methods
	var dir_accessor = Directory.new()
	var return_code = OK
	# do nothing if path exists
	if validate_directory(absolute_path) == false:
		# directories all the way down
		if not write_recursively:
			return_code = dir_accessor.make_dir(absolute_path)
		else:
			return_code = dir_accessor.make_dir_recursive(absolute_path)
	else:
		return_code = ERR_CANT_CREATE
	# if ok, return, else log and return error
	if return_code != OK:
		GlobalDebug.log_error(SCRIPT_NAME, "create_directory",
				"failed to create directory at {p}".format({
					"p": absolute_path
				}))
	return return_code


# this method returns the string value of the DATA_PATHS (dict) database,
# the path to the local directory (res://)
# this is shorter and less prone to user error than the dev writing;
#	GlobalData.DATA_PATHS[GlobalData.DATA_PATH_PREFIXES.LOCAL]
# developers are encouraged to create their own variants of this method if
# they add their own prefixes to the DATA_PATH dict/db.
func get_dirpath_local() -> String:
	return DATA_PATHS[DATA_PATH_PREFIXES.LOCAL]


# this method returns the string value of the DATA_PATHS (dict) database,
# the path to the user directory (user://)
# this is shorter and less prone to user error than the dev writing;
#	GlobalData.DATA_PATHS[GlobalData.DATA_PATH_PREFIXES.USER]
# developers are encouraged to create their own variants of this method if
# they add their own prefixes to the DATA_PATH dict/db.
func get_dirpath_user() -> String:
	return DATA_PATHS[DATA_PATH_PREFIXES.USER]


# This method gets the file path for every file in a directory and returns
# those file paths within an array. Caller can then use those file paths
# to query file types or load files.
# Optional arguments can allow the caller to exclude specific files
# [method params as follows]
##1, directory_path, is the path to the directory you wish to read files from
#	(always pass directories with a trailing forward slash /)
##2, req_file_prefix, file must begin with this string
##3, req_file_suffix, file must end with this string (including extension)
##4, excl_substrings, array of strings which the file name is checked against
#	and the file name must **not** include
##5, incl_substrings, array of strings which the file name is checked against
#	and the file name must include
#	(leave params as default (i.e. empty strings or "") to ignore behaviour)
func get_file_paths(
		directory_path: String,
		req_file_prefix: String = "",
		req_file_suffix: String = "",
		excl_substrings: PoolStringArray = [],
		incl_substrings: PoolStringArray = []) -> PoolStringArray:
	# validate path
	var dir_access := Directory.new()
	var file_name := ""
	var return_file_paths: PoolStringArray = []
	
	# find the directory, loop through the directory
	if dir_access.open(directory_path) == OK:
		# skip if directory couldn't be opened
		if dir_access.list_dir_begin() != OK:
			return return_file_paths
		# find first file in directory, prep validation bool, and start
		file_name = dir_access.get_next()
		var add_found_file = true
		while file_name != "":
			# check isn't a directory (i.e. is a file)
			if not dir_access.current_is_dir():
				# set validation default value
				add_found_file = true
				# validate the file name
				# validation block 1
				if req_file_prefix != "":
					if not file_name.begins_with(req_file_prefix):
						add_found_file = false
						# successful validation to exempt a file
						#// need a minor logging method added
						GlobalDebug.log_success(verbose_logging, SCRIPT_NAME,
								"get_file_paths",
								"prefix {p} not in file name {f}".format({
									"p": req_file_prefix,
									"f": file_name
								}))
				# validation block 2
				if req_file_suffix != "":
					if not file_name.ends_with(req_file_suffix):
						add_found_file = false
						# successful validation to exempt a file
						#// need a minor logging method added
						GlobalDebug.log_success(verbose_logging, SCRIPT_NAME,
								"get_file_paths",
								"suffix {s} not in file name {f}".format({
									"s": req_file_suffix,
									"f": file_name
								}))
				# validation block 3
				if not excl_substrings.empty():
					for force_exclude in excl_substrings:
						if typeof(force_exclude) == TYPE_STRING:
							if force_exclude in file_name:
								add_found_file = false
								# successful validation to exempt a file
								#// need a minor logging method added
								GlobalDebug.log_success(verbose_logging,
										SCRIPT_NAME,
										"get_file_paths",
										"bad str {s} in file name {f}".format({
											"s": force_exclude,
											"f": file_name
										}))
				# validation block 4
				if not incl_substrings.empty():
					for force_include in incl_substrings:
						if typeof(force_include) == TYPE_STRING:
							if not force_include in file_name:
								add_found_file = false
								# successful validation to exempt a file
								#// need a minor logging method added
								GlobalDebug.log_success(verbose_logging,
										SCRIPT_NAME,
										"get_file_paths",
										"no str {s} in file name {f}".format({
											"s": force_include,
											"f": file_name
										}))
				# validation checks passed successfully
				if add_found_file:
					return_file_paths.append(directory_path+file_name)
				# if they didn't, nothing is appended
			# end of loop
			# get next file
			file_name = dir_access.get_next()
		dir_access.list_dir_end()
	return return_file_paths


# this method loads and returns (if valid) a resource from disk
# returns either a loaded resource, or a null value if it is invalid
# [method params as follows]
##1, file_path, is the path to the resource to be loaded.
##2, type_cast, should be comparison type or object of a class to be compared
# to the resource once it is loaded. If the comparison returns untrue, the
# loaded resource will not be returned. The default argument for this parameter
# is null, which will result in this comparison behvaiour being ignored.
# Developers can use this to ensure the resource they're loading will return
# a resource of the class they desire.
# [warning!] Devs, if using a var referencing an object as a comparison class
# class, be careful not to use an object that shares a common parent but isn't
# the same end point class (example would be HBoxContainer and VBoxContainer
# both sharing many of the same parents), as this may return false postiives.
func load_resource(
		file_path: String,
		type_cast = null
		):
	# add type hint to load?
#	var type_hint = ""
#	if type_cast is Resource\
#	and "get_class" in type_cast:
#			type_hint = str(type_cast.get_class())
		
	# check path is valid before loading resource
	var is_path_valid = validate_file(file_path)
	if not is_path_valid:
		GlobalDebug.log_error(SCRIPT_NAME, "load_resource",
				"attempted to load non-existent resource at {p}".format({
					"p": file_path
				}))
		return null
	
		# attempt to load resource
	var new_resource: Resource = ResourceLoader.load(file_path)
	
	# then validate it was loaded and is corrected type
	
	# if resource wasn't succesfully loaded (check before type validation)
	if new_resource == null:
		GlobalDebug.log_error(SCRIPT_NAME, "load_resource",
				"resource not loaded successfully, is null")
		return null
	
	# ignore type_casting behaviour if set to null
	# otherwise loaded resource must be the same type
	if not (type_cast == null):
		if not (new_resource is type_cast):
			# discard value to ensure reference count update
			new_resource = null
			GlobalDebug.log_error(SCRIPT_NAME, "load_resource",
					"resource not loaded succesfully, invalid type")
			return null
	
	# if everything is okay, return the loaded resource
	GlobalDebug.log_success(verbose_logging, SCRIPT_NAME, "load_resource",
			"resource {res} validated and returned".format({
				"res": new_resource
			}))
	return new_resource


# this method extends the load resource method to get **every** resource
# within a given directory. It pulls files using the get_file_paths method.
# this method can be passed any argument from get_file_paths or load_resource
# [method params as follows]
##1, directory_path, is the path to the directory containing resources that
# you wish the method to return
##2, req_file_prefix, see the method 'get_file_paths'
##3, req_file_suffix, see the method 'get_file_paths'
##4, excl_substrings, see the method 'get_file_paths'
##5, incl_substrings, see the method 'get_file_paths'
##6, type_cast, see the method 'load_resource'
func load_resources_in_directory(
		directory_path: String,
		req_file_prefix: String = "",
		req_file_suffix: String = "",
		excl_substrings: PoolStringArray = [],
		incl_substrings: PoolStringArray = [],
		type_cast = null) -> Array:
	var returned_resources := []
	var paths_to_resources: PoolStringArray = []
	# get paths for files in directory
	paths_to_resources = get_file_paths(
		directory_path,
		req_file_prefix,
		req_file_suffix,
		excl_substrings,
		incl_substrings
	)
	# if no paths found, return nothing
	if paths_to_resources.empty():
		return returned_resources
	# for each path check if resource then add it to the return group if it is
	for file_path in paths_to_resources:
		var get_resource
		get_resource = load_resource(file_path, type_cast)
		if get_resource != null:
			if get_resource is Resource:
				returned_resources.append(get_resource)
	return returned_resources


# method to save any resource or resource-extended custom class to disk.
# call this method with 'if save_resource(*args) == OK' to validate
#
# [method params as follows]
##1, directory_path, is the path to the file location sans the file_name
#	e.g. 'user://saves/player1.tres' should be passed as 'user://saves/'
# (Always leave a trailing slash on the end of directory paths.)
#
##2, file_name, is the name of the file
#	e.g. 'user://saves/player1.tres' should be passed as 'player1.tres'
#	(note: resource extensions should always be .tres for a resource)
# the first two arguments are combined to get the full file path; they exist
# as separate arguments so directories can be validated independent of files.
#
##3, saveable_res, is the resource object to save
#
##4, force_write_file, specifies whether to allow overwriting an existing
# file; if it is set false then the resource will not be saved if it finds a
# file (whether the file is a valid resource or not) at the file path argument.
# You can use this to save default versions of user-customisable files like
# data containers for game saves, player progression, or scores.
#
##5, force_write_directory, specifies whether to allow creating directories
# during the save operation; if set false will require save operations to take
# place in an existing directory, returning with an error argument if the
# directory doesn't exist. if arg5 is set true it will create directories when
# the save operation is called.
#	(calling with a force_write arg will override 'path not found' error
#	logging for the file or directory validation methods respectively,
#	see 'is_write_operation_directory_valid' & '_is_write_operation_path_vaild')
##6, increment_backup, stores the previous file as a separate file with the
# const 'BACKUP_SUFFIX' applied before the file extension. This is performed by
# stripping the expected string constant of RESOURCE_FILE_EXTENSION from the
# file path, applying the backup suffix, then reapplying the file extension.
#	(Backups can be set to be loaded as part of a failed load)
func save_resource(
		directory_path: String,
		file_name: String,
		saveable_res: Resource,
		force_write_file: bool = true,
		force_write_directory: bool = true,
		increment_backup : bool = false
		) -> int:
	# combine paths
	var full_data_path: String = directory_path+file_name
	# error code (or OK) for returning
	var return_code: int
	
	# next up are methods to validate the write operation. For each;
	# if OK (0), continue function. If an error code (1+), return the error.
	# We're using error codes rather than bool for more informative debugging.
	
	# validate directory path
	return_code = _is_write_operation_directory_valid(
			directory_path,
			force_write_directory
			)
	if return_code != OK:
		return return_code
	
	# validate file path
	return_code = _is_write_operation_path_valid(
			full_data_path,
			force_write_file
			)
	if return_code != OK:
		return return_code
	
	# validate write extension is valid
	if not _is_resource_extension_valid(full_data_path):
		# _is_resource_extension_valid already includes logging, redundant
#		GlobalDebug.log_error(SCRIPT_NAME, "save_resource",
#				"resource extension invalid")
		return ERR_FILE_CANT_WRITE
	
	# move on to the write operation
	# if file is new, just attempt a write
	if not validate_file(full_data_path):
		return_code = ResourceSaver.save(full_data_path, saveable_res)
	# if file already existed, need to safely write to prevent corruption
	# i.e. write to a temporary file, remove the older, make temp the new file
	else:
		# attempt the write operation
		var temp_data_path = directory_path+"temp_"+file_name
		return_code = ResourceSaver.save(temp_data_path, saveable_res)
		# if we wrote the file successfully, time to remove the old file
		# i.e. move previous file to recycle bin/trash
		var path_manager = Directory.new()
		if return_code == OK:
			# re: issue 67137, OS.move_to_trash will cause a project crash
			# but on this branch the full_data_path should be validated
			assert(validate_file(full_data_path, true))
			# move to trash behaviour should only proceed if not backing up
			if not increment_backup:
				# Note: If the user has disabled trash on their system,
				# the file will be permanently deleted instead.
				var get_global_path =\
						ProjectSettings.globalize_path(full_data_path)
				return_code = OS.move_to_trash(get_global_path)
				# if file was moved to trash, the path should now be invalid
			# if backing up, the previous file should be moved to backup
			else:
				var backup_path = full_data_path
				# path to file is already validated to have .tres extensino
				backup_path = full_data_path.rstrip(".tres")
				# concatenate string as backup
				backup_path += BACKUP_SUFFIX
				backup_path += RESOURCE_FILE_EXTENSION
				return_code = path_manager.rename(full_data_path, backup_path)
			
			if return_code == OK:
				assert(not validate_file(full_data_path))
				# rename the temp file to be the new file
				return_code = path_manager.rename(\
						temp_data_path, full_data_path)
		# if the temporary file wasn't written successfully
		else:
			return return_code
	
	
	# if all is well and the function didn't exit prior to this point
	# successful exit points will be
	# 1) path didn't exist and file was written, or
	# 2) path exists, temp file written, first file trashed, temp file renamed
	# return code should be 'OK' (int 0)
	return return_code


# as the method validate_path, but specifically checking for files existing
# useful for one liner conditionals and built-in error logging
# (saves creating a file/directory object manually)
# [method params as follows]
##1, path, is the file path to validate
##2, assert_path, forces an assert in debug builds and error logging in both
# debug and release builds. Set this param to true when you require a path
# to be valid before you continue with an operation.
func validate_file(given_path: String, assert_path: bool = false) -> bool:
	# call the private validation method as a file
	return _validate(given_path, assert_path, true)


# as the method validate_path, but specifically checking for directories
# useful for one liner conditionals and built-in error logging
# (saves creating a file/directory object manually)
# [method params as follows]
##1, path, is the directory path to validate
##2, assert_path, forces an assert in debug builds and error logging in both
# debug and release builds. Set this param to true when you require a path
# to be valid before you continue with an operation.
func validate_directory(given_path: String, assert_path: bool = false) -> bool:
	# call the private validation method as a directory
	return _validate(given_path, assert_path, false)



##############################################################################

# private methods


# validation method for public 'save' methods
func _is_write_operation_directory_valid(
		directory_path: String,
		force_write_directory: bool
		) -> int:
	# resources can only be saved to paths within the user data folder.
	# user data path is "user://"
	if directory_path.substr(0, 7) != DATA_PATHS[DATA_PATH_PREFIXES.USER]:
		GlobalDebug.log_error(SCRIPT_NAME, "save_resource",
				"{p} is not user_data path".format({"p": directory_path}))
		return ERR_FILE_BAD_PATH
	
	# check if the directory already exists
	if not validate_directory(directory_path):
		# if not force writing, and directory doesn't exist, return invalid
		if not force_write_directory:
			GlobalDebug.log_error(SCRIPT_NAME, "save_resource",
					"directory at {p} does not exist".format({
						"p": directory_path}))
			return ERR_FILE_BAD_PATH
		# if force writing and directory doesn't exist, create it
		elif force_write_directory:
			var attempt_write_dir = create_directory(directory_path)
			if attempt_write_dir != OK:
				GlobalDebug.log_error(SCRIPT_NAME, "save_resource",
						"failed attempt to write directory at {p}".format({
							"p": directory_path
						}))
				return attempt_write_dir
	# if all was successful,
	# and no directory needed to be created
	return OK


# validation method for public 'save' methods
# this method assumes the directory already exists, call create_directory()
# beforehand on the directory if you are unsure
func _is_write_operation_path_valid(
		file_path: String,
		force_write_file: bool
		) -> int:
	# check the full path is valid
	var _is_path_valid := false
	# don't log error not finding path if called with force_write
	_is_path_valid = validate_file(file_path)
	
	# if file exists and we don't have permission to overwrite
	if (not force_write_file and _is_path_valid):
		GlobalDebug.log_error(SCRIPT_NAME, "save_resource",
				"file at {p} already exists".format({
					"p": file_path}))
		return ERR_FILE_NO_PERMISSION
	# if all was successful,
	return OK


# used to validate that file paths are for valid resource extensions
# pass the file path as an argument
func _is_resource_extension_valid(resource_file_path: String) -> bool:
	# returns the last x characters from the file path string, where
	# x is the length of the RESOURCE_FILE_EXTENSION constant
	# uses length() as a starting point, subtracts to get starting position
	# of substring then -1 arg returns remaining chars (the constant length)
	var extension =\
			resource_file_path.substr(
			resource_file_path.length()-RESOURCE_FILE_EXTENSION.length(),
			-1
			)
	# comparison bool value
	var is_valid_extension = (extension == RESOURCE_FILE_EXTENSION)
	if not is_valid_extension:
		GlobalDebug.log_error(SCRIPT_NAME, "_is_resource_extension_valid",
				"invalid extension, expected {c} but got {e}".format({
					"c": RESOURCE_FILE_EXTENSION,
					"e": extension
				}))
	return is_valid_extension


# both the public methods validate_path and validate_directory call this
# private method to actually do things; the methods are similar in execution
# but are different checks, so they are essentially args for this method
func _validate(given_path: String, assert_path: bool, is_file: bool) -> bool:
	var _path_check = Directory.new()
	var _is_valid = false
	
	# validate_file call
	if is_file:
		_is_valid = _path_check.file_exists(given_path)
	# validate_directory call
	elif not is_file:
		_is_valid = _path_check.dir_exists(given_path)
	
	var log_string = "file" if is_file else "directory"
	
	if assert_path\
	and not _is_valid:
		GlobalDebug.log_error(SCRIPT_NAME,
				"_validate"+" (from validate_{m})".format({"m": log_string}),
				"path: [{p}] is not a valid {m}.".format({
					"p": given_path,
					"m": log_string
				}))
	# this method (and validate_path/validate_directory) will stop project
	# execution if the assert_path parameter is passed a true arg
	if assert_path:
		assert(_is_valid)
	
	# will be true if path existed and was the correct type
	# will be false otherwise
	return _is_valid


##############################################################################

#// ATTENTION DEV
# Further documentation and advice on saving to/loading from disk,
# managing loading etc, can be found at:
#	
#	https://docs.godotengine.org/en/latest/classes/class_configfile.html
#	https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html
#	https://docs.godotengine.org/en/stable/classes/class_resourceloader.html
#	https://docs.godotengine.org/en/stable/classes/class_directory.html
#	https://docs.godotengine.org/en/stable/classes/class_file.html
#	https://github.com/khairul169/gdsqlite
#	https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
#	http://kidscancode.org/godot_recipes/4.x/basics/file_io/
#	https://godotengine.org/qa/21370/what-are-various-ways-that-i-can-store-data

# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html
# [on self-contained mode]
# Self-contained mode is not supported in exported projects yet. To read and
# write files relative to the executable path, use OS.get_executable_path().
# Note that writing files in the executable path only works if the executable
# is placed in a writable location (i.e. not Program Files or another directory
# that is read-only for regular users).


##############################################################################

