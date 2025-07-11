extends CharacterBody2D

var run_speed = 350
var jump_speed = -700
var gravity = 1000
var is_attacking = false
var attack_cooldown = false
var attack_timer : Timer
var attack_hold_timer :Timer
var attack_velocity_jump = -700
var is_holding = false
var is_holding_attack = false


func _ready():
	# Создаем таймер для атаки
	attack_timer = $Timer
	attack_hold_timer = $attack_hold_timer
	attack_timer.one_shot = true
	



func get_input():
	velocity.x = 0
	
	# Если уже атакуем, ограничиваем управление
	if is_attacking:
		var right = Input.is_action_pressed('right')
		var left = Input.is_action_pressed('left')
		
		if right:
			$AnimatedSprite2D.flip_h = false
			velocity.x += run_speed * 0.5
		elif left:
			$AnimatedSprite2D.flip_h = true
			velocity.x -= run_speed * 0.5
		return  # Выходим, чтобы не мешать анимации атаки
	
	# Движение и прыжки (оставляем без изменений)
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_just_pressed('ui_select')
	
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
			velocity.x += run_speed
		elif left:
			velocity.x -= run_speed
	elif velocity.x == 0:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("run")

	# 🔥 НОВАЯ ЛОГИКА АТАКИ (исправленная)
	if Input.is_action_just_pressed("Attack") and not attack_cooldown:
		# Запускаем таймер удержания (0.3 сек)
		is_holding_attack = false
		attack_hold_timer.start(0.3)
	
	# Если игрок отпустил кнопку ДО истечения таймера → быстрая атака
	if Input.is_action_just_released("Attack") and attack_hold_timer.time_left > 0:
		if not is_holding_attack and not attack_cooldown:
			start_quick_attack()
			attack_hold_timer.stop()  # Отменяем таймер удержания

func start_quick_attack():
	is_attacking = true
	attack_cooldown = true
	$AnimatedSprite2D.play("kick_ground")
	
	var anim_speed = $AnimatedSprite2D.sprite_frames.get_animation_speed("kick_ground")
	var frame_count = $AnimatedSprite2D.sprite_frames.get_frame_count("kick_ground")
	var anim_length = frame_count / anim_speed
	attack_timer.start(anim_length)

func _physics_process(delta):
	# Гравитация работает всегда
	velocity.y += gravity * delta
	
	# Обработка ввода
	get_input()
	
	move_and_slide()


func _on_timer_timeout() -> void:
	
	is_attacking = false
	attack_cooldown = false


func _on_attack_hold_timer_timeout():
	if Input.is_action_pressed("Attack"):  # Проверяем, что кнопка всё ещё зажата
		is_holding_attack = true
		# Запускаем сильную атаку
		velocity.x = -attack_velocity_jump if $AnimatedSprite2D.flip_h else attack_velocity_jump
		velocity.y = attack_velocity_jump
		is_attacking = true
		attack_cooldown = true
		$AnimatedSprite2D.play("kick_up")  
		attack_timer.start(0.75)
