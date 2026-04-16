# Currently used to apply temporary effects from Ritual cards

class_name AddTempRitual extends Effect

@export var rname : String

func apply(_source, _target, _combat):
	if _source and _source.has_method("_add_temp_effect"):
		_source._add_temp_effect(rname)
