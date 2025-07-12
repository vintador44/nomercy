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
var attack_area : Area2D
var nearest_enemy : CharacterBody2D
var characters_array = []
var min_character :CharacterBody2D


func _ready():
	# Создаем таймер для атаки
	attack_timer = $Timer
	attack_hold_timer = $attack_hold_timer
	attack_timer.one_shot = true
	attack_area = $AttackArea
	add_to_group("player")

func get_min_enemy():
	min_character = characters_array[0]
	for character_buffer in characters_array:
		if character_buffer != null:
			character_buffer.is_marker = false
			if vector_length(character_buffer.position - position) < vector_length(min_character.position-position):
				min_character = character_buffer
		

func vector_length(vector:Vector2):
	return pow(pow(vector.x,2) + pow(vector.y,2),0.5)

func get_input():
	velocity.x = 0
	
	# Находим ближайшего врага
	characters_array = get_tree().get_nodes_in_group("enemy")
	if characters_array.size() > 0:
		get_min_enemy()
		if min_character:
			min_character.is_marker = true
	
	# Получаем состояние ввода
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_just_pressed('ui_select')
	var fire = Input.is_action_just_pressed("fire")
	var attack = Input.is_action_just_pressed("Attack")
	
	# Если уже атакуем, ограничиваем управление
	if is_attacking:
		if right:
			velocity.x += run_speed * 0.5
		elif left:
			velocity.x -= run_speed * 0.5
		return
	
	# Обработка стрельбы - приоритетнее движения
	if fire and not attack_cooldown:
		shoot()
		return  # Прерываем дальнейшую обработку ввода при стрельбе
	
	# Движение и прыжки
	if is_on_floor() and jump:
		$AnimatedSprite2D.play("jump_up")
		velocity.y = jump_speed
	
	if is_on_floor():
		if right:
			velocity.x += run_speed
		elif left:
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
	
	# Обновляем направление взгляда только если не стреляем и не атакуем
	if not is_attacking:
		if right:
			$AnimatedSprite2D.flip_h = false
			attack_area.scale = Vector2(-1, 1)
		elif left:
			$AnimatedSprite2D.flip_h = true
			attack_area.scale = Vector2(1, 1)
	
	# Обработка атаки
	if attack and not attack_cooldown:
		is_holding_attack = false
		attack_hold_timer.start(0.3)
	
	if Input.is_action_just_released("Attack") and attack_hold_timer.time_left > 0:
		if not is_holding_attack and not attack_cooldown:
			start_quick_attack()
			attack_hold_timer.stop()

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
	
	if is_attacking:
		$AttackArea/CollisionShape2D.disabled = false
	else:
		$AttackArea/CollisionShape2D.disabled = true
	
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

func shoot():
	if is_attacking:  # Запрещаем новую атаку, если уже атакуем
		return
	
	is_attacking = true
	attack_cooldown = true
	$AnimatedSprite2D.play("revshoot")
	
	# Рассчитываем длительность анимации
	var anim_speed = $AnimatedSprite2D.sprite_frames.get_animation_speed("revshoot")
	var anim_frame_count = $AnimatedSprite2D.sprite_frames.get_frame_count("revshoot")
	var anim_duration = anim_frame_count / anim_speed
	attack_timer.start(anim_duration)
	
	var bullet = preload("res://bullet.tscn").instantiate()
	
	# Определяем направление стрельбы
	var shoot_direction: Vector2
	if min_character:
		var direction = sign(min_character.position.x - global_position.x)
		$AnimatedSprite2D.flip_h = direction < 0
		attack_area.scale = Vector2(1 if direction < 0 else -1, 1)
		shoot_direction = (min_character.position - Vector2(global_position.x, global_position.y+30)).normalized()
	else:
		# Если нет врагов, используем текущее направление
		shoot_direction = Vector2(-1 if $AnimatedSprite2D.flip_h else 1, 0)
	
	bullet.direction = shoot_direction
	
	# Позиция пули - исправленная версия
	var spawn_offset = 30  # Базовое смещение от персонажа
	var velocity_factor = 0.2  # Коэффициент влияния скорости
	
	if $AnimatedSprite2D.flip_h:  # Стрельба влево
		bullet.position.x = global_position.x - spawn_offset + (velocity.x * velocity_factor)
	else:  # Стрельба вправо
		bullet.position.x = global_position.x + spawn_offset + (velocity.x * velocity_factor)
	
	bullet.position.y = global_position.y + 30
	
	# Добавляем пулю с небольшой задержкой
	await get_tree().create_timer(anim_duration * 0.3).timeout  # Уменьшил задержку
	get_tree().current_scene.add_child(bullet)
	
func _on_attack_area_body_entered(body: Node2D) -> void:
	
	if body.has_method("take_damage") and not $AttackArea/CollisionShape2D.disabled: 
		
		var attack_data = {
			"damage": 1, 
			"source": self,  
			"knockback": Vector2(0, -0.7) if is_holding_attack else Vector2(0.5, -0.3)
		}
		body.take_damage(attack_data)
