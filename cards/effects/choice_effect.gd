class_name ChoiceEffect extends Effect

@export var choices : Array[Effect]
@export var choice_texts : Array[String]

var callback_source
var callback_target
var callback_combat

func apply(_source, _target, _combat):
	callback_source = _source
	callback_target = _target
	callback_combat = _combat
	
	UIManager.show_card_choice(self)


func resolve_choice(index: int):
	if index < 0 or index >= choices.size():
		return

	var chosen = choices[index]
	
	print("Chosen type: ", chosen.get_class())

	if "target_type" in chosen:
		print("Target type: ", chosen.target_type)

	# If the choice has an 'effects' property, treat as CardData
	if "effects" in chosen:
		if chosen.effects.size() > 0:
			var effect = chosen.effects[0]
			
			var targets = callback_combat._get_effect_targets(effect, callback_source)
			for target in targets:
				if callback_combat._is_valid_target(target):
					print("Computed targets:", targets)
					print("Source:", callback_source)
					print("Player ref:", callback_combat.player)
					print("Opponent ref:", callback_combat.opponent)
					effect.apply(callback_source, callback_target, callback_combat)
		else:
			print("Chosen card has no effects!")
	# If the choice has an 'apply' method, treat as Effect
	elif chosen is Effect:
		var targets = callback_combat._get_effect_targets(chosen, callback_source)
		for target in targets:
			if callback_combat._is_valid_target(target):
				print("Computed targets: ", targets)
				print("Source: ", callback_source)
				print("Player ref: ", callback_combat.player)
				print("Opponent ref: ", callback_combat.opponent)
				print("Passing target: ", target)
				var effect_instance = chosen.duplicate(true)
				effect_instance.apply(callback_source, callback_target, callback_combat)
	else:
		print("Chosen object is neither CardData nor Effect!")
