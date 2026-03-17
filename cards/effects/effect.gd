class_name Effect extends Resource

enum TargetType {
	SELF,
	ENEMY#,
	#ALL,
	#RANDOM
}

@export var target_type : TargetType = TargetType.ENEMY
@export var chance : float = 1.0
@export var tags : Array[String] = []

func apply(_source, _target, _combat):
	pass
