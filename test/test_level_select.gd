extends GutTest

const TEST_SCENE = "res://scenes/Level Select/level_2.tscn"

var scene_instance

func before_each():
	scene_instance = load(TEST_SCENE).instantiate()
	add_child_autofree(scene_instance)

# Test 1 that tests the forward button
func test_forward_button_exists_cases():
	# Regular Case
	assert_true(scene_instance.forward_button != null, "Forward button should exist.")

	# Edge case
	var node = scene_instance.get_node_or_null("Buttons/Forward Arrow")
	assert_true(node != null, "Node path Buttons/Forward Arrow should exist.")

	# Error case
	var bad_node = scene_instance.get_node_or_null("Buttons/ForwardArrow")
	assert_true(bad_node == null, "Incorrect path should return null.")

#Test 2 that tests the back button
func test_back_button_exists_cases():
	# Normal case
	assert_true(scene_instance.back_button != null, "Back button should exist.")

	# Edge case
	var node = scene_instance.get_node_or_null("Buttons/Back Arrow")
	assert_true(node != null, "Node path Buttons/Back Arrow should exist.")

	# Error case
	var bad_node = scene_instance.get_node_or_null("Buttons/BackArrow")
	assert_true(bad_node == null, "Incorrect path should return null.")

# Test 3 that tests the forward button path
func test_get_forward_scene_path_cases():
	# Regular case
	var path = scene_instance.get_forward_scene_path()
	assert_typeof(path, TYPE_STRING, "Forward path should be a string.")

	# Edge case
	assert_ne(path, "", "Forward path should not be empty.")

	# Error case
	assert_eq(path, "res://scenes/Level Select/level_3.tscn",
		"Forward scene path should be level_3.tscn.")

#Test 4 that tests the back button path
func test_get_back_scene_path_cases():
	# Normal case
	var path = scene_instance.get_back_scene_path()
	assert_typeof(path, TYPE_STRING, "Back path should be a string.")

	# Edge case
	assert_ne(path, "", "Back path should not be empty.")

	# Error case
	assert_eq(path, "res://scenes/Level Select/level_1.tscn",
		"Back scene path should be level_1.tscn.")

# Test 5 Helper validation functions work
func test_button_validation_helpers_cases():
	# Normal case 
	assert_true(scene_instance.has_valid_forward_button(),
		"Forward button helper should return true.")

	# Normal case number 2
	assert_true(scene_instance.has_valid_back_button(),
		"Back button helper should return true.")

	# Edge as well as Error case
	var fake_button = scene_instance.get_node_or_null("Buttons/Fake Button")
	assert_true(fake_button == null, "Fake button should not exist.")
