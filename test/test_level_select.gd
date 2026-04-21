extends GutTest

const TEST_SCENE = "res://scenes/Level Select/level_2.tscn"

var scene_instance

func before_each():
	scene_instance = load(TEST_SCENE).instantiate()
	add_child_autofree(scene_instance)

# Test 1 that tests the forward button
func test_forward_button_exists_cases():
	# Regular Case (checks that the forward button varibale was created correctly)
	assert_true(scene_instance.forward_button != null, "Forward button should exist.")

	# Edge case (checks that the node exists where its supposed to be)
	var node = scene_instance.get_node_or_null("Buttons/Forward Arrow")
	assert_true(node != null, "Node path Buttons/Forward Arrow should exist.")

	# Error case (checks that if it is in the wrong spot then it will return null)
	var bad_node = scene_instance.get_node_or_null("Buttons/ForwardArrow")
	assert_true(bad_node == null, "Incorrect path should return null.")

#Test 2 that tests the back button
func test_back_button_exists_cases():
	# Normal case (checks that the back button varibale was created correctly)
	assert_true(scene_instance.back_button != null, "Back button should exist.")

	# Edge case (checks that the node exists where its supposed to be)
	var node = scene_instance.get_node_or_null("Buttons/Back Arrow")
	assert_true(node != null, "Node path Buttons/Back Arrow should exist.")

	# Error case (checks that if it is in the wrong spot then it will return null)
	var bad_node = scene_instance.get_node_or_null("Buttons/BackArrow")
	assert_true(bad_node == null, "Incorrect path should return null.")

# Test 3 that tests the forward button path
func test_get_forward_scene_path_cases():
	# Regular case (makes sure it returns the right type)
	var path = scene_instance.get_forward_scene_path()
	assert_typeof(path, TYPE_STRING, "Forward path should be a string.")

	# Edge case (check that the path is not blank)
	assert_ne(path, "", "Forward path should not be empty.")

	# Error case (checks that the path goes where it should (level_3.tscn))
	assert_eq(path, "res://scenes/Level Select/level_3.tscn",
		"Forward scene path should be level_3.tscn.")

#Test 4 that tests the back button path
func test_get_back_scene_path_cases():
	# Normal case (makes sure it returns the right type)
	var path = scene_instance.get_back_scene_path()
	assert_typeof(path, TYPE_STRING, "Back path should be a string.")

	# Edge case (check that the path is not blank)
	assert_ne(path, "", "Back path should not be empty.")

	# Error case (checks that the path goes where it should (level_1.tscn))
	assert_eq(path, "res://scenes/Level Select/level_1.tscn",
		"Back scene path should be level_1.tscn.")

# Test 5 Helper validation functions work
func test_button_validation_helpers_cases():
	# Normal case (checks the helper can find the forward button)
	assert_true(scene_instance.has_valid_forward_button(),
		"Forward button helper should return true.")

	# Normal case number 2 (checks the helper can find the back button)
	assert_true(scene_instance.has_valid_back_button(),
		"Back button helper should return true.")

	# Edge as well as Error case (makes sure that if the button isnt there it will return null)
	var fake_button = scene_instance.get_node_or_null("Buttons/Fake Button")
	assert_true(fake_button == null, "Fake button should not exist.")
