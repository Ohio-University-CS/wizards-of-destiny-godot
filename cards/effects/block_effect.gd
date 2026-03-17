class_name BlockEffect extends Effect

@export var amount : int = 0

func apply(_source, target, _combat):
	target.add_block(amount)
