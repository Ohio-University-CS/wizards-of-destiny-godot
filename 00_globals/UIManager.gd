# UI Manager
extends Node

var ui_controller = null

func register_ui_controller(controller):
	ui_controller = controller


func show_card_choice(effect):
	if ui_controller:
		ui_controller.show_card_choice(effect)
