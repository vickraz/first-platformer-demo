extends KinematicBody2D

const MAX_SPEED = 120

onready var anim = $AnimatedSprite
onready var nav = $NavigationAgent2D
onready var ray = $RayCast2D

var player = null
var spawnpoint = null

var velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	pass


func _update_nav_path(target) -> void:
	pass

func _move(delta: float) -> void:
	pass

func _is_Player_Visible() -> bool:
	return false
