# Handles effects of potions in shop
extends Resource
class_name PotionEffect

enum PotionColor {
	BLUE,
	GREEN,
	ORANGE,
	PINK,
	PURPLE,
	RED,
	YELLOW
}

@export var potion_color : PotionColor = PotionColor.RED


func apply_potion():
	if RunManager.player:
		if potion_color == PotionColor.ORANGE:
			var heal_amt = RunManager.player.get_max_health() * 0.5
			RunManager.player.heal(heal_amt)
		if potion_color == PotionColor.RED:
			var heal_amt = RunManager.player.get_max_health()
			RunManager.player.heal(heal_amt)
		if potion_color == PotionColor.YELLOW:
			var heal_amt = RunManager.player.get_max_health() * 0.25
			RunManager.player.heal(heal_amt)
