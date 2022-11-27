extends KinematicBody2D

enum {IDLE, RUN, AIR, WALL_SLIDE, DASH, SLIDE}

const MAX_SPEED = 200
const ACCELERATION = 1500
const GRAVITY = 1000
const JUMP_STRENGHT = -410

var direction_x = "RIGHT"
var velocity := Vector2.ZERO
var direction := Vector2.ZERO

var state = IDLE
var ghosttime := 0.0

var can_jump := true
var can_dash := true

var ghost_scene = preload("res://Scenes/DashGhost.tscn")
var particle_scene = preload("res://Scenes/GhostParticles.tscn")

onready var animationplayer = $AnimationPlayer
onready var coyotetimer = $CoyoteTimer
onready var jumpbuffertimer = $JumpBufferTimer
onready var dashtimer = $DashTimer
onready var particlespawn = $ParticleSpawn


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
		DASH:
			_dash_state(delta)
		SLIDE:
			_slide_state(delta)

#Help functions
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

func _add_dash_ghost() -> void:
	var ghost = ghost_scene.instance()
	ghost.global_position = global_position
	ghost.frame = $Sprite.frame
	ghost.flip_h = $Sprite.flip_h
	get_tree().get_root().add_child(ghost)
	
	var particles = particle_scene.instance()
	particles.global_position = particlespawn.global_position
	particles.emitting = true
	get_tree().get_root().add_child(particles)

func _air_movement(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	velocity = move_and_slide(velocity, Vector2.UP)

func _wall_movement(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta * 0.6 if velocity.y < 90 else 90 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		
	if Input.is_action_pressed("ui_up"):
		velocity.y = move_toward(velocity.y, -80, ACCELERATION*delta)
		animationplayer.play("Climb")
	else:
		animationplayer.play("Wall_slide")
	
	velocity = move_and_slide(velocity, Vector2.UP)

#STATES:
func _idle_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	if Input.is_action_just_pressed("jump") and can_jump:
		_enter_air_state(true)
		return
	
	if Input.is_action_just_pressed("dash") and can_dash:
		_enter_dash_state()
		return
		
	_apply_basic_movement(delta)
	
	if not is_on_floor():
		_enter_air_state(false)
		return
	if velocity.x != 0:
		_enter_run_state()
		return
		
func _run_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	if Input.is_action_just_pressed("jump") and can_jump:
		_enter_air_state(true)
		return
	
	elif Input.is_action_just_pressed("dash") and can_dash:
		_enter_dash_state()
		return
	
	_apply_basic_movement(delta)
	
	if not is_on_floor():
		_enter_air_state(false)
		return
	elif velocity.length() == 0 or is_on_wall():
		_enter_idle_state()
		return
	elif Input.is_action_just_pressed("slide"):
		_enter_slide_state()
		return

func _air_state(delta) -> void:
	if Input.is_action_just_pressed("dash") and can_dash:
		_enter_dash_state()
		return
	elif Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		coyotetimer.stop()
	elif Input.is_action_just_pressed("jump") and not can_jump:
		jumpbuffertimer.start()
	
	_air_movement(delta)
	if velocity.y > 0 and not animationplayer.current_animation == "Fall":
		animationplayer.play("Fall")
	
	if is_on_floor():
		if jumpbuffertimer.time_left != 0:
			velocity.y = JUMP_STRENGHT
			animationplayer.play("Frontflip")
		else:
			_enter_idle_state()
			return
		
	elif is_on_wall() and velocity.y > 0:
		_enter_wall_slide_state()
		return
	
func _wall_slide_state(delta) -> void:
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGHT * 0.9
		state = AIR
		animationplayer.play("Jump")
		can_jump = false
		return
		
	_wall_movement(delta)
	
	
	if is_on_floor():
		_enter_idle_state()
		return
	elif not is_on_wall():
		state = AIR
		can_jump = false
		$Sprite.frame = 16
		can_dash = true
		return

func _dash_state(delta):
	velocity = velocity.move_toward(direction*MAX_SPEED*3, ACCELERATION*delta*3)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	ghosttime += delta
	
	if is_on_wall() and velocity.y <= 0:
		_enter_wall_slide_state(DASH)
		$Sprite.material.set_shader_param("whiten", false)
		dashtimer.stop()
		ghosttime = 0.0
		direction.y = 0
		return
	elif ghosttime >= 0.03:
		_add_dash_ghost()
		ghosttime = 0.0
		
func _slide_state(delta) -> void:
	if Input.is_action_just_pressed("jump") and can_jump:
		_enter_air_state(true)
		return
		
	_apply_basic_movement(delta)
	
	if not is_on_floor():
		_enter_air_state(false)
	elif velocity == Vector2.ZERO:
		_enter_idle_state()

#SIGNALS
func _on_DashTimer_timeout():
	_enter_idle_state()
	$Sprite.material.set_shader_param("whiten", false)
	velocity = direction * MAX_SPEED
	ghosttime = 0.0
	direction.y = 0
	yield(get_tree().create_timer(0.5), "timeout")
	can_dash = true

func _on_CoyoteTimer_timeout():
	can_jump = false


#Enter states
func _enter_idle_state() -> void:
	state = IDLE
	animationplayer.play("Idle")
	can_jump = true

func _enter_wall_slide_state(from: int = AIR) -> void:
	state = WALL_SLIDE
	animationplayer.play("Wall_slide")
	can_jump = true
	if from == DASH:
		yield(get_tree().create_timer(0.5), "timeout")
		can_dash = true

func _enter_dash_state() -> void:
	direction = Input.get_vector("move_left", "move_right", "ui_up", "ui_down")
	if state == IDLE and direction == Vector2.DOWN:
		return
	elif direction == Vector2.ZERO:
		direction.x = 1 if direction_x == "RIGHT" else -1
	animationplayer.play("Jump")
	state = DASH
	can_dash = false
	dashtimer.start(0.25)
	$Sprite.material.set_shader_param("whiten", true)

func _enter_air_state(jump: bool) -> void:
	if jump:
		velocity.y = JUMP_STRENGHT
	if jumpbuffertimer.time_left != 0:
		animationplayer.play("Frontflip")
	else:
		animationplayer.play("Jump")
	coyotetimer.start()
	state = AIR

func _enter_run_state() -> void:
	state = RUN
	animationplayer.play("Run")

func _enter_slide_state() -> void:
	animationplayer.play("Slide")
	state = SLIDE
