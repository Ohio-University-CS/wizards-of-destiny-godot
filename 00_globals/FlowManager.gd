# FlowManager.gd
extends Node

# ----------------
# Scene Paths
# ----------------

const COMBAT_SCENE := "res://scenes/arena.tscn"
const SHOP_SCENE := "res://scenes/Shop/shop.tscn"
#const REST_SCENE := 
#const EVENT_SCENE := 
#const CHOICE_SCENE := 

# ----------------
# Basic Transitions
# ----------------

func go_to_combat():
	get_tree().change_scene_to_file(COMBAT_SCENE)


func go_to_shop():
	get_tree().change_scene_to_file(SHOP_SCENE)


#func go_to_rest():
	#get_tree().change_scene_to_file(REST_SCENE)


#func go_to_event():
	#get_tree().change_scene_to_file(EVENT_SCENE)

# ------------------
# Combat Result Handling
# ------------------

func on_combat_finished(result : Dictionary):
	# Example result:
	# { "coins": 20, "perfect": true, "turns": 3 }
	
	if result.has("coins"):
		RunManager.add_coins(result["coins"])
	
	# Advance progression
	RunManager.next_stage()
	
	# After combat, go to shop
	go_to_shop()

# ----------------
# After Shop Flow
# ----------------

func after_shop():
	var type = RunManager.get_stage_type()
	
	match type:
		#RunManager.StageType.REST:
			#go_to_rest()
		RunManager.StageType.ELITE:
			go_to_combat()
		RunManager.StageType.BOSS:
			go_to_combat()
		_:
			go_to_choice()

# ----------------
# Choice (Event vs Combat)
# ----------------

func go_to_choice():
	go_to_combat() #nothing exists
	
	#temp
	#if randf() < 0.5:
		#go_to_event()
	#else:
		#go_to_combat()

# ----------------
# After Rest / Event
# ----------------

func after_rest():
	go_to_combat()


func after_event():
	go_to_combat()
