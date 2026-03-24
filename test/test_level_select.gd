extends GutTest

# Change this path to wherever your actual level select scene is saved.
const TEST_SCENE = "res://scenes/Level Select/level_2.tscn"

var scene_instance

func before_each():
	scene_instance = load(TEST_SCENE).instantiate()
	add_child_autofree(scene_instance)

# -------------------------------------------------
# Test 1: Forward button exists
# -------------------------------------------------
func test_forward_button_exists_cases():
	# Normal case: forward button should exist
	assert_true(scene_instance.forward_button != null, "Forward button should exist.")

	# Edge case: node path should match the expected button node
	var node = scene_instance.get_node_or_null("Buttons/Forward Arrow")
	assert_true(node != null, "Node path Buttons/Forward Arrow should exist.")

	# Error case: wrong node path should not exist
	var bad_node = scene_instance.get_node_or_null("Buttons/ForwardArrow")
	assert_true(bad_node == null, "Incorrect path should return null.")

# -------------------------------------------------
# Test 2: Back button exists
# -------------------------------------------------
func test_back_button_exists_cases():
	# Normal case: back button should exist
	assert_true(scene_instance.back_button != null, "Back button should exist.")

	# Edge case: node path should match expected button node
	var node = scene_instance.get_node_or_null("Buttons/Back Arrow")
	assert_true(node != null, "Node path Buttons/Back Arrow should exist.")

	# Error case: wrong path should fail
	var bad_node = scene_instance.get_node_or_null("Buttons/BackArrow")
	assert_true(bad_node == null, "Incorrect path should return null.")

# -------------------------------------------------
# Test 3: Forward scene path is correct
# -------------------------------------------------
func test_get_forward_scene_path_cases():
	# Normal case: should return a string
	var path = scene_instance.get_forward_scene_path()
	assert_typeof(path, TYPE_STRING, "Forward path should be a string.")

	# Edge case: path should not be empty
	assert_ne(path, "", "Forward path should not be empty.")

	# Error case: path should exactly match expected scene
	assert_eq(path, "res://scenes/Level Select/level_3.tscn",
		"Forward scene path should be level_3.tscn.")

# -------------------------------------------------
# Test 4: Back scene path is correct
# -------------------------------------------------
func test_get_back_scene_path_cases():
	# Normal case: should return a string
	var path = scene_instance.get_back_scene_path()
	assert_typeof(path, TYPE_STRING, "Back path should be a string.")

	# Edge case: path should not be empty
	assert_ne(path, "", "Back path should not be empty.")

	# Error case: path should exactly match expected scene
	assert_eq(path, "res://scenes/Level Select/level_1.tscn",
		"Back scene path should be level_1.tscn.")

# -------------------------------------------------
# Test 5: Helper validation functions work
# -------------------------------------------------
func test_button_validation_helpers_cases():
	# Normal case: valid forward button helper should return true
	assert_true(scene_instance.has_valid_forward_button(),
		"Forward button helper should return true.")

	# Normal case: valid back button helper should return true
	assert_true(scene_instance.has_valid_back_button(),
		"Back button helper should return true.")

	# Edge/Error case: a nonexistent node should still be null
	var fake_button = scene_instance.get_node_or_null("Buttons/Fake Button")
	assert_true(fake_button == null, "Fake button should not exist.")
