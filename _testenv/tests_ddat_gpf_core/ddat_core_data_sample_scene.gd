extends Node2D

##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	# caution: running unit tests will push a lot of (intentional) errors
	_run_unit_tests(true)
	
	# run manual tests
	var run_manual_tests = false
	if run_manual_tests:
		_manualtest_datamgr_resource()
		_manualtest_datamgr_game_data_container()

##############################################################################


func test_save(player_save, datacon_dir: String, datacon_file: String):
#	var player_save := GameDataContainer.new()
	var _return_arg =\
			GlobalData.save_resource(datacon_dir, datacon_file, player_save)


func test_load(datacon_dir: String, datacon_file: String, type_cast = null):
	var save_file = GlobalData.load_resource(
			datacon_dir+datacon_file,
			type_cast
	)
	return save_file


##############################################################################


# custom manual testing part 1
func _manualtest_datamgr_resource():
	var get_test_path = GlobalData.get_dirpath_user()
#	var get_test_path = GlobalData.DATA_PATHS[GlobalData.DATA_PATH_PREFIXES.USER]
	get_test_path += "test/test2/test3/test4/"
	var file_name = "res.tres"
	var return_arg = GlobalData.save_resource(get_test_path, file_name, Resource.new())
	if return_arg != OK:
		print("error ", return_arg)
	else:
		print("write operation successful")
#		var sample_path = get_test_path+file_name
#		var sample_path = GlobalData.get_dirpath_user()+"res.tres"
		var sample_path = GlobalData.get_dirpath_user()+"resource_new.tres"
#		var sample_path = GlobalData.get_dirpath_user()+"score.save"
		var _new_res
		if GlobalData.validate_file(sample_path) == false:
			_new_res = GlobalData.save_resource(
				GlobalData.get_dirpath_user(),
				"resource_new.tres",
				Resource.new()
			)
		else:
			_new_res = GlobalData.load_resource(sample_path)


# custom manual testing part 2
# save file 'gameDataContainer' testing
func _manualtest_datamgr_game_data_container():
	var datacon_dir: String = GlobalData.get_dirpath_user()+"saves/"
	var datacon_file := "save1.tres"
	if not GlobalData.validate_file(datacon_dir+datacon_file):
		test_save(GameDataContainer.new(), datacon_dir, datacon_file)
	var get_save_res = test_load(datacon_dir, datacon_file, GameDataContainer)
	if get_save_res != null:
		if "get_class" in get_save_res:
			get_save_res.get_class()
		print("is save a datacon? ", (get_save_res is GameDataContainer))
		print(get_save_res)
		if "example_float_data" in get_save_res:
			var get_float_data = get_save_res.example_float_data
			print(get_float_data)
			var increase: float = 2.70
			print("incrementing float by {inc}, ({old}+{inc}={new})".format({
				"old": get_float_data,
				"inc": increase,
				"new": (get_float_data+increase),
			}))
			# now save it to file
			get_save_res.example_float_data = get_float_data+increase
			test_save(get_save_res, datacon_dir, datacon_file)


#// can extend this into a unit test by
# - validating or creating testing directory and files at start
# - turning below logic into a loop
#func _manualtest_datamgr_get_paths():
#	var path = GlobalData.DATA_PATHS[GlobalData.DATA_PATH_PREFIXES.GAME_SAVE]
#
#	var get_files = GlobalData.get_file_paths(path)
#	print("test1", " expected return", get_files)
#	print("#\n")
#
#	get_files = GlobalData.get_file_paths(path, "egg")
#	print("test2", " expected fail", get_files)
#	print("#\n")
#
#	get_files = GlobalData.get_file_paths(path, "sav")
#	print("test3", " expected return", get_files)
#	print("#\n")
#
#	get_files = GlobalData.get_file_paths(path, "", ".res")
#	print("test4", " expected fail", get_files)
#	print("#\n")
#
#	get_files = GlobalData.get_file_paths(path, "", ".tres")
#	print("test5", " expected return", get_files)
#	print("#\n")
#
#	get_files = GlobalData.get_file_paths(path, "", "", "save")
#	print("test6", " expected fail", get_files)
#	print("#\n")
#
#	get_files = GlobalData.get_file_paths(path, "", "", "buttermilk")
#	print("test7", " expected return", get_files)
#	print("#")



##############################################################################


# holder of unit tests in this sample scene
func _run_unit_tests(do_tests: bool = false):
	var run_unit_tests = do_tests
	print("run unit tests = ", run_unit_tests)
	if run_unit_tests:
		# temporarily removed path_to_user_data and resource_path
		# as they push too many errors
		var unit_test_record = {
#			"save_resource_path_to_user_data":
#				_unit_test_save_resource_path_to_user_data(),
#			"load_invalid_resource_path":
#				_unit_test_load_invalid_resource_path(),
			"save_and_load_resource":
				_unit_test_save_and_load_resource(),
			"_unit_test_get_paths_main":
				_unit_test_get_paths_main(),
			"_unit_test_load_resources_in_directory":
				_unit_test_load_resources_in_directory(),
			"_unit_test_save_resource_with_backup":
				_unit_test_save_resource_with_backup()
		}
		for test_id in unit_test_record:
			print("running test {x}, result = {r}".format({
				"x": test_id,
				"r": unit_test_record[test_id]
			}))


# paths must begin with user://
# test by sending invalid paths
# caution: running this unit test will push a lot of (intentional) errors
func _unit_test_save_resource_path_to_user_data() -> bool:
	var get_results = []
	get_results.append(GlobalData.save_resource("test.txt", "", Resource.new()))
	get_results.append(GlobalData.save_resource("get_user", "", Resource.new()))
	get_results.append(GlobalData.save_resource("user:/", "", Resource.new()))
	get_results.append(GlobalData.save_resource("usr://", "", Resource.new()))
	# every result should be invalid
	for result in get_results:
		if result == OK:
			return false
	# if loop through safely, all results were invalid
	return true


# load method should check paths
# test by loading a completely invalid path
func _unit_test_load_invalid_resource_path() -> bool:
	var _end_result := true
	var new_resource
	new_resource = GlobalData.load_resource("fakepath")
	if new_resource == null:
		_end_result = true
	else:
		_end_result = false
	return _end_result


#// TODO - create a resource with a custom value,
#	save it to disk, then attempt to load it
func _unit_test_save_and_load_resource():
	pass


# this test assumes save_resource is working
# unit test for different inputs to the globalData.get_path method
# this unit test will rewrite the directory/files each time
func _unit_test_get_paths_main():
	# start test by validating (and writing if messing) the test files
	var test_save_path := "user://unit_test/get_paths/"
	var test_file_1 := "file1.tres"
	var test_file_2 := "file2.tres"
	var test_file_3 := "file3.tres"
	
	# make sure this directory and these files exist
	# create directory return error and breaks if directory found, so ignore
	#//UPDATE directory creation removed as is handled by save_resource
#	var _discard = GlobalData.create_directory(test_save_path)

	# validating files is important
	if GlobalData.save_resource(
			test_save_path, test_file_1, Resource.new()) != OK:
		print("test setup error 1")
		return
	if GlobalData.save_resource(
			test_save_path, test_file_2, Resource.new()) != OK:
		print("test setup error 2")
		return
	if GlobalData.save_resource(
			test_save_path, test_file_3, Resource.new()) != OK:
		print("test setup error 3")
		return
	
	var expected_result_full: PoolStringArray = [
		(test_save_path+test_file_1),
		(test_save_path+test_file_2),
		(test_save_path+test_file_3)
	]
	var expected_result_partial1: PoolStringArray = [
		(test_save_path+test_file_1)
	]
#	var expected_result_partial2 := [
#		(test_save_path+test_file_1),
#		(test_save_path+test_file_3)
#	]
	var expected_result_empty: PoolStringArray = []
	
	
	# run unit tests,
	# compare expected result vs actual result as a bool
	# then compare the bool against result so a single false fails the tests
	var unit_result := true
	var end_result := true
	var expected_result: PoolStringArray = []
	var get_file_paths_result: PoolStringArray = []
	var test_id := 0
	print("beginning tests for _unit_test_get_paths_main")
	
	# test get_file_paths works
	get_file_paths_result = GlobalData.get_file_paths(test_save_path)
	expected_result = expected_result_full
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	#// GlobalDebug need a minor logging method
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))

	# test for whether prefix req works (files should start w/'file')
	get_file_paths_result = GlobalData.get_file_paths(test_save_path, "file")
	expected_result = expected_result_full
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))
	
	# test for whether prefix req works (files should not start w/'roar')
	get_file_paths_result = GlobalData.get_file_paths(test_save_path, "roar")
	expected_result = expected_result_empty
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))
	
	# test for whether suffix req works (files should end in .tres)
	get_file_paths_result = GlobalData.get_file_paths(test_save_path, "", ".tres")
	expected_result = expected_result_full
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))
	
	# test for whether suffix req works (files should not end in .save)
	get_file_paths_result = GlobalData.get_file_paths(test_save_path, "", ".save")
	expected_result = expected_result_empty
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))
	
	# test for whether force exclude works (files should not include '2' or '3')
	get_file_paths_result = GlobalData.get_file_paths(test_save_path, "", "", ["2", "3"])
	expected_result = expected_result_partial1
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))
	
	# test for whether force include works (files should include '1')			
	get_file_paths_result = GlobalData.get_file_paths(test_save_path, "", "", [], ["1"])
	expected_result = expected_result_partial1
	unit_result = (expected_result == get_file_paths_result)
	end_result = (end_result and unit_result)
	test_id += 1
	print("test no.{n} = {r}! \nexpected {e}, \noutcome {o}\n".format({
		"n": test_id,
		"r": unit_result,
		"e": expected_result,
		"o": get_file_paths_result
	}))
	
#	print("_unit_test_get_paths_main, final outcome = ", end_result)
	# end unit test
	return end_result


# this test assumes save_resource is working
# unit test for different inputs to the globalData.load_resources_in_directory
# this unit test will rewrite the directory/files each time
func _unit_test_load_resources_in_directory():
	# setup the args for the test files
	var test_save_path := "user://unit_test/load_resources_in_directory/"
	var path_test_file_1 := "file1.tres"
	var path_test_file_2 := "file2.tres"
	var path_test_file_3 := "file3.tres"
	var test_value_1 := 1.11
	var test_value_2 := 2.22
	var test_value_3 := 3.33
	var res_test_file_1 = GameDataContainer.new()
	res_test_file_1.example_float_data = test_value_1
	var res_test_file_2 = GameDataContainer.new()
	res_test_file_2.example_float_data = test_value_2
	var res_test_file_3 = GameDataContainer.new()
	res_test_file_3.example_float_data = test_value_3
	# force write the test files
	if GlobalData.save_resource(
			test_save_path, path_test_file_1, res_test_file_1) != OK:
		print("_unit_test_load_resources_in_directory test setup error 1")
		return
	if GlobalData.save_resource(
			test_save_path, path_test_file_2, res_test_file_2) != OK:
		print("_unit_test_load_resources_in_directory test setup error 2")
		return
	if GlobalData.save_resource(
			test_save_path, path_test_file_3, res_test_file_3) != OK:
		print("_unit_test_load_resources_in_directory test setup error 3")
	
	var test_res_load =\
			GlobalData.load_resources_in_directory(test_save_path)
	print("got file paths, ", test_res_load)
	if test_res_load.empty():
		print("no loaded object")
		return false
	for loaded_obj in test_res_load:
		if loaded_obj is GameDataContainer:
			print("object ", loaded_obj, " w/float data of ",
					loaded_obj.example_float_data)
			if not loaded_obj.example_float_data\
					in [test_value_1, test_value_2, test_value_3]:
				print("loaded object has invalid float data")
				return false
	#
	print("successful load and validate")
	return true


# this test assumes save_resource is working
# the point of this unit test is to read a backup after saving different files,
# getting the non-default file from backup instead of the more recent default
func _unit_test_save_resource_with_backup():
	print("running _unit_test_save_resource_with_backup ")
	var return_code
	# setup the args for the test files
	var test_save_path :=\
			"user://unit_test/save_resource_with_backup/"
	var path_test_file := "file1.tres"
	# get two files ready
	var save_file_1 = GameDataContainer.new()
	var save_file_2 = GameDataContainer.new()
	# gameDataContainers default to false on example_bool_data
	# so adjust the first file to be different
	save_file_1.example_bool_data = true
	
	# save the first file at the example path
	return_code = GlobalData.save_resource(\
			test_save_path, path_test_file, save_file_1)
	# file expected to save succesfully
	if return_code != OK:
		print("failed to save file 1")
		return false
	
	# save the second file at the SAME example path
	return_code = GlobalData.save_resource(\
			test_save_path, path_test_file, save_file_2, true, true, true)
	# file expected to save succesfully
	if return_code != OK:
		print("failed to save file 2")
		return false
	
	var load_backup_path = "file1_backup.tres"
	# both files should be saved
	var testing_file
	testing_file = GlobalData.load_resource(
				(test_save_path+load_backup_path)
	)
	#// replace with type_cast arg test?
	if testing_file is GameDataContainer:
		print("loading file in _unit_test_save_resource_with_backup,\n"+\
		"expected value is {e}, actual value is {a}".format({
			"e": true,
			"a": testing_file.example_bool_data
		}))
		if (testing_file.example_bool_data == true):
			return true
		else:
			return false
	else:
		print("returned file incorrect type")
		return false
	
	
 
