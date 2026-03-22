extends Control

@onready var title : Label = $Title
@onready var total_label : Label = $Total
@onready var breakdown_container : VBoxContainer = $Breakdown
@onready var continue_button : Button = $ContinueButton

var result : Dictionary


func _ready():
	result = RunManager.last_combat_result
	
	title.text = "Floor " + str(RunManager.level_floor) + " Stage " + str(RunManager.stage) + " Cleared!"
	
	_display_rewards()
	
	continue_button.pressed.connect(_on_continue_pressed)


# helper
func add_line(text : String):
	var label = Label.new()
	label.text = text
	breakdown_container.add_child(label)


func _display_rewards():
	# clear old entries
	for child in breakdown_container.get_children():
		child.queue_free()
	
	if result.is_empty():
		total_label.text = "No Rewards"
		return
	
	# Base
	var base : int = result.get("coins", 0)
	add_line("+%d Coins" % base)
	
	# Perfect
	if result.get("perfect", false):
		add_line("+5 Perfect Bonus")
	
	# Speed
	var turns = result.get("turns", 999)
	if turns <= 3:
		add_line("+5 Fast Clear")
	elif turns <= 6:
		add_line("+2 Quick Clear")
	
	var total : int = result.get("total_coins", base)
	total_label.text = "Total: " + str(total)
	


func _on_continue_pressed():
	FlowManager.go_to_shop()
