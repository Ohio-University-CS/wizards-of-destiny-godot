class_name BlockEffect extends Effect

@export var amount : int = 0
@export var times : int = 1

func apply(_source, target, _combat):
	for i in range(times):
		target.add_block(amount)
