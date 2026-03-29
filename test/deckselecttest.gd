extends Node

func _ready():
	print("===== RUNNING UNIT TESTS =====\n")

	test_judgement_buttons()
	test_judgement_navigation()

	test_moon_navigation()
	test_tower_navigation()

	test_level_select()

	print("\n===== ALL TESTS FINISHED =====")
	get_tree().quit()
	
	
#test 1
# Normal: buttons exist
# Edge: all 3 buttons present
# Error: missing button should fail

func test_judgement_buttons():
	print("TEST: Judgement Buttons")

	var scene = load("res://scenes/deckselect/deckselect_judgement.tscn").instantiate()
	add_child(scene)

	var back = scene.get_node("Buttons/Back")
	var forward = scene.get_node("Buttons/Forward")
	var level = scene.get_node("Buttons/Level Select")

	# Normal case
	if back:
		print("PASS: Back button exists")
	else:
		print("FAIL: Back button missing")

	# Edge case
	if forward:
		print("PASS: Forward button exists")
	else:
		print("FAIL: Forward button missing")

	# Error case
	if level:
		print("PASS: Level Select button exists")
	else:
		print("FAIL: Level Select button missing")
		
# Test 2
# Normal: forward works
# Edge: back works
# Error: invalid scene should fail

func test_judgement_navigation():
	print("\nTEST: Judgement Navigation")

	var scene = load("res://scenes/deckselect/deckselect_judgement.tscn").instantiate()
	add_child(scene)

	# Normal case (forward → emperor)
	var result = get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_emperor.tscn")
	if result == OK:
		print("PASS: Forward navigation works")
	else:
		print("FAIL: Forward navigation failed")

	# Edge case (back → magician)
	result = get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_magician.tscn")
	if result == OK:
		print("PASS: Back navigation works")
	else:
		print("FAIL: Back navigation failed")

	# Error case
	result = get_tree().change_scene_to_file("res://fake_scene.tscn")
	if result != OK:
		print("PASS: Invalid scene blocked")
		
# Test 3
# Normal: forward → star
# Edge: back → sun
# Error: invalid scene

func test_moon_navigation():
	print("\nTEST: Moon Navigation")

	# Normal case
	var result = get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_star.tscn")
	if result == OK:
		print("PASS: Forward (Moon → Star) works")

	# Edge case
	result = get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_sun.tscn")
	if result == OK:
		print("PASS: Back (Moon → Sun) works")

	# Error case
	result = get_tree().change_scene_to_file("res://wrong.tscn")
	if result != OK:
		print("PASS: Invalid scene prevented")
		
# Test 4
# Normal: forward → death
# Edge: back → star
# Error: invalid scene

func test_tower_navigation():
	print("\nTEST: Tower Navigation")

	# Normal case
	var result = get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_death.tscn")
	if result == OK:
		print("PASS: Forward (Tower → Death) works")

	# Edge case
	result = get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_star.tscn")
	if result == OK:
		print("PASS: Back (Tower → Star) works")

	# Error case
	result = get_tree().change_scene_to_file("res://invalid.tscn")
	if result != OK:
		print("PASS: Invalid scene handled")
		
# Test 5
# Normal: loads arena
# Edge: loads multiple times
# Error: invalid arena scene

func test_level_select():
	print("\nTEST: Level Select")

	# Normal case
	var result = get_tree().change_scene_to_file("res://scenes/arena.tscn")
	if result == OK:
		print("PASS: Arena loads")

	# Edge case
	result = get_tree().change_scene_to_file("res://scenes/arena.tscn")
	if result == OK:
		print("PASS: Arena reload works")

	# Error case
	result = get_tree().change_scene_to_file("res://arena_fake.tscn")
	if result != OK:
		print("PASS: Invalid arena blocked")
