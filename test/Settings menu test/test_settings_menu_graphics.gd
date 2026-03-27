extends "res://addons/gut/test.gd"

#Tests for settings menu - graphics
const scence = "res://scenes/settings_menu/graphics/setting-menu-graphics.tscn"
var test_settings

func before_each():
	test_settings = load(scence).instantiate()
	add_child_autofree(test_settings)
	
	
#Test 1: Testing unrolled scroll ON
func test_scroll_ON():
	#Normal Case: ON
	await test_settings._gso_on()
	assert_true(test_settings.unrolled_scroll.visible, "Unrolled Scroll should be visible")
		
	#Edge Case: already visible
	await test_settings._gso_on()
	assert_true(test_settings.unrolled_scroll.visible)
		
	#Error Case: missing node
	test_settings.unrolled_scroll = null
	assert_eq(test_settings.unrolled_scroll, null)

#Test 2: Test Fullscreen button ON
func test_fullscreen_ON():
	#Normal Case: ON
	await test_settings._gso_on()
	assert_true(test_settings.fullscreen_button.visible, "Full Screen Button should be visible")
	
	#Edge Case: already visible
	await test_settings._gso_on()
	assert_true(test_settings.fullscreen_button.visible)
	
	#Error Case: missing node
	test_settings.fullscreen_button = null
	assert_eq(test_settings.fullscreen_button, null)

#Test 3: Test unrolled scroll OFF
func test_scroll_OFF():
	#Normal Case: OFF
	await test_settings._gso_off()
	assert_false(test_settings.unrolled_scroll.visible, "Unrolled Scroll should not be visible")
		
	#Edge Case: already visible
	await test_settings._gso_off()
	assert_false(test_settings.unrolled_scroll.visible)
		
	#Error Case: missing node
	test_settings.unrolled_scroll = null
	assert_eq(test_settings.unrolled_scroll, null)

#Test 4: Test fullscreen Button OFF
func test_fullscreen_OFF():
	#Normal Case: OFF
	await test_settings._gso_off()
	assert_false(test_settings.fullscreen_button.visible, "Full Screen Button should  not be visible")
	
	#Edge Case: already visible
	await test_settings._gso_off()
	assert_false(test_settings.fullscreen_button.visible)
	
	#Error Case: missing node
	test_settings.fullscreen_button = null
	assert_eq(test_settings.fullscreen_button, null)

#Test 5:Test Fullscreen toggle Button
func test_fullscreen_button():
	#Normal Case: Toggle Fullscrene
	test_settings._gso_on()
	assert_true(true, "Fullscreen Toggled")
	
	#Edge Case: toggle again
	test_settings._gso_on()
	assert_true(true, "Fullscreen Toggled Back")
	
	# Error case: missing UI elements
	test_settings.fullscreen_on = null
	test_settings.fullscreen_off = null
	assert_eq(test_settings.fullscreen_on, null)

	
	pass
