extends CharacterBody2D

var run_speed = 350
var jump_speed = -700
var gravity = 1000
var is_attacking = false
var attack_cooldown = false
var attack_timer : Timer
var attack_velocity_jump = -500

func _ready():
	# Создаем таймер для атаки
	attack_timer = $Timer
	attack_timer.one_shot = true




func get_input():
	velocity.x = 0
	
	if is_attacking:
		# Во время атаки только проверяем движение по X, чтобы персонаж не "зависал" в воздухе
		var right = Input.is_action_pressed('right')
		var left = Input.is_action_pressed('left')
		
		if right:
			$AnimatedSprite2D.flip_h = false
			velocity.x += run_speed * 0.5  # Медленное движение во время атаки
		elif left:
			$AnimatedSprite2D.flip_h = true
			velocity.x -= run_speed * 0.5
		return
		
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_just_pressed('ui_select')
	var attack = Input.is_action_just_pressed('Attack')
	
	if attack and not attack_cooldown:
		start_attack()
		return
		
	if is_on_floor() and jump:
		$AnimatedSprite2D.play("jump_up")
		velocity.y = jump_speed

	if is_on_floor():
		if right:
			$AnimatedSprite2D.flip_h = false
			velocity.x += run_speed
		elif left:
			$AnimatedSprite2D.flip_h = true
			velocity.x -= run_speed
	
	if !is_on_floor():
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump_up")
		else:
			$AnimatedSprite2D.play("jump_down")
		if right:
			$AnimatedSprite2D.flip_h = false
			velocity.x += run_speed
		elif left:
			$AnimatedSprite2D.flip_h = true
			velocity.x -= run_speed
	elif velocity.x == 0:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("run")

func start_attack():
	is_attacking = true
	attack_cooldown = true
	$AnimatedSprite2D.play("kick_up")
	
	var anim_speed = $AnimatedSprite2D.sprite_frames.get_animation_speed("kick_up")
	var frame_count = $AnimatedSprite2D.sprite_frames.get_frame_count("kick_up")
	var anim_length = frame_count / anim_speed
	attack_timer.start(anim_length)

func _physics_process(delta):
	# Гравитация работает всегда
	velocity.y += gravity * delta
	
	# Обработка ввода
	get_input()
	
	move_and_slide()


func _on_timer_timeout() -> void:
	velocity.x -= attack_velocity_jump
	velocity.y = attack_velocity_jump
	is_attacking = false
	attack_cooldown = false
