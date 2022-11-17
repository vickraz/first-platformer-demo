extends KinematicBody2D

enum {IDLE, RUN, AIR, WALL_SLIDE}

const MAX_SPEED = 200
const ACCELERATION = 1000
const GRAVITY = 1000
const JUMP_STRENGHT = -410

var direction_x = "RIGHT"
var velocity := Vector2.ZERO
var direction := Vector2.ZERO

var state = IDLE

var can_jump = true

onready var animationplayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		RUN:
			_run_state(delta)
		AIR:
			_air_state(delta)
		WALL_SLIDE:
			_wall_slide_state(delta)


func _apply_basic_movement(delta) -> void:
	if direction.x != 0:
		velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION*delta)
	
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)

func _get_input_x_update_direction() -> float:
	var input_x = Input.get_axis("move_left", "move_right")
	if input_x > 0:
		direction_x = "RIGHT"
	elif input_x < 0:
		direction_x = "LEFT"
	$Sprite.flip_h = direction_x != "RIGHT"
	return input_x



func _idle_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		state = AIR
		animationplayer.play("Jump")
		return
		
	_apply_basic_movement(delta)
	
	if velocity.x != 0:
		state = RUN
		animationplayer.play("Run")
		return
		
func _run_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		state = AIR
		animationplayer.play("Jump")
		return
	

	_apply_basic_movement(delta)
	
	if not is_on_floor():
		state = AIR
		can_jump = false
		animationplayer.play("Jump")
	elif velocity.length() == 0 or is_on_wall():
		state = IDLE
		animationplayer.play("Idle")
		return

func _air_state(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_floor():
		state = IDLE
		animationplayer.play("Idle")
		can_jump = true
		return
	elif is_on_wall() and velocity.y > 0:
		state = WALL_SLIDE
		animationplayer.play("Wall_slide")
		can_jump = true
		return
	
func _wall_slide_state(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta * 0.2 if velocity.y <= 250 else 250 
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_STRENGHT * 0.9
		state = AIR
		animationplayer.play("Jump")
		can_jump = false
		return
		
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_floor():
		state = IDLE
		animationplayer.play("Idle")
		can_jump = true
		return
	elif not is_on_wall():
		state = AIR
		can_jump = false
		$Sprite.frame = 16
		return
	
	
