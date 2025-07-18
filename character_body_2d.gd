extends CharacterBody2D

# Movement constants
const RUN_SPEED = 350
const JUMP_SPEED = -700
const GRAVITY = 1000
const RUN_ATTACK_MODIFIER = 0.5

# Attack constants
const ATTACK_VELOCITY_JUMP = -700
const ATTACK_HOLD_DURATION = 0.3
const STRONG_ATTACK_DURATION = 0.75
const QUICK_ATTACK_KNOCKBACK_X = 0.5
const QUICK_ATTACK_KNOCKBACK_Y = -0.3
const HOLD_ATTACK_KNOCKBACK = Vector2(0, -0.7)

# Health constants
const MAX_HEALTH = 5

const KNOCKBACK_POWER = 1200
const KNOCKBACK_DURATION = 0.5

# Shooting constants
const BULLET_SPAWN_OFFSET = 30
const BULLET_Y_OFFSET = 30
const BULLET_VELOCITY_FACTOR = 0.2
const SHOOT_DELAY_FACTOR = 0.3

# State variables
var is_attacking = false
var attack_cooldown = false
var is_holding = false
var is_holding_attack = false
var is_knockbacked = false
var current_health = 5

# References
var attack_timer: Timer
var attack_hold_timer: Timer
var attack_area: Area2D
var knockback_timer: Timer

# Enemy tracking
var nearest_enemy: CharacterBody2D
var characters_array = []
var min_character: CharacterBody2D

func _ready():
	# Initialize timers
	attack_timer = $Timer
	attack_hold_timer = $attack_hold_timer
	attack_timer.one_shot = true
	attack_area = $AttackArea
	knockback_timer = $KnockbackTimer
	
	add_to_group("player")

func get_min_enemy():
	if characters_array.size() == 0:
		return
	
	min_character = characters_array[0]
	for character_buffer in characters_array:
		if character_buffer != null:
			character_buffer.is_marker = false
			if vector_length(character_buffer.position - position) < vector_length(min_character.position - position):
				min_character = character_buffer

func vector_length(vector: Vector2):
	return pow(pow(vector.x, 2) + pow(vector.y, 2), 0.5)

func get_input():
	if is_knockbacked:
		return
	
	velocity.x = 0
	
	# Find nearest enemy
	characters_array = get_tree().get_nodes_in_group("enemy")
	if characters_array.size() > 0:
		get_min_enemy()
		if min_character:
			min_character.is_marker = true
	
	# Get input state
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_just_pressed('ui_select')
	var fire = Input.is_action_just_pressed("fire")
	var attack = Input.is_action_just_pressed("Attack")
	
	# If already attacking, limit control
	if is_attacking:
		if right:
			velocity.x += RUN_SPEED * RUN_ATTACK_MODIFIER
		elif left:
			velocity.x -= RUN_SPEED * RUN_ATTACK_MODIFIER
		return
	
	# Shooting has priority over movement
	if fire and not attack_cooldown:
		shoot()
		return
	
	# Movement and jumping
	if is_on_floor() and jump:
		$AnimatedSprite2D.play("jump_up")
		velocity.y = JUMP_SPEED
	
	if is_on_floor():
		if right:
			velocity.x += RUN_SPEED
		elif left:
			velocity.x -= RUN_SPEED
	
	if !is_on_floor():
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump_up")
		else:
			$AnimatedSprite2D.play("jump_down")
		if right:
			velocity.x += RUN_SPEED
		elif left:
			velocity.x -= RUN_SPEED
	elif velocity.x == 0:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("run")
	
	# Update facing direction only if not shooting/attacking
	if not is_attacking:
		if right:
			$AnimatedSprite2D.flip_h = false
			attack_area.scale = Vector2(-1, 1)
		elif left:
			$AnimatedSprite2D.flip_h = true
			attack_area.scale = Vector2(1, 1)
	
	# Handle attack input
	if attack and not attack_cooldown:
		is_holding_attack = false
		attack_hold_timer.start(ATTACK_HOLD_DURATION)
	
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
	# Apply gravity
	velocity.y += GRAVITY * delta
	
	# Handle input
	get_input()
	
	# Toggle attack collision
	if is_attacking:
		$AttackArea/CollisionShape2D.disabled = false
	else:
		$AttackArea/CollisionShape2D.disabled = true
	
	move_and_slide()

func _on_timer_timeout():
	is_attacking = false
	attack_cooldown = false

func _on_attack_hold_timer_timeout():
	if Input.is_action_pressed("Attack"):
		is_holding_attack = true
		# Start strong attack
		velocity.x = -ATTACK_VELOCITY_JUMP if $AnimatedSprite2D.flip_h else ATTACK_VELOCITY_JUMP
		velocity.y = ATTACK_VELOCITY_JUMP
		is_attacking = true
		attack_cooldown = true
		$AnimatedSprite2D.play("kick_up")  
		attack_timer.start(STRONG_ATTACK_DURATION)

func die():
	queue_free()

func get_damage(info):
	if is_knockbacked:
		return
	
	velocity = info.knockback * KNOCKBACK_POWER
	current_health = max(current_health - info.damage, 0)
	is_knockbacked = true
	knockback_timer.start(KNOCKBACK_DURATION)
	update_health_ui()

	if current_health <= 0:
		die()

func _on_knockback_timer_timeout():
	is_knockbacked = false

func update_health_ui():
	var ui = get_tree().get_root().get_node("Node2D/CanvasLayer/UI/HBoxContainer")
	for i in range(MAX_HEALTH):
		var health_icon = ui.get_node("health_%d" % (i + 1))
		var sprite = health_icon.get_node("Sprite2D")
		if i < current_health:
			sprite.texture = load("res://sprites/ui/health/hp1.png")
		else:
			sprite.texture = load("res://sprites/ui/health/empty.png")

func shoot():
	if is_attacking:
		return
	
	is_attacking = true
	attack_cooldown = true
	$AnimatedSprite2D.play("revshoot")
	
	# Calculate animation duration
	var anim_speed = $AnimatedSprite2D.sprite_frames.get_animation_speed("revshoot")
	var anim_frame_count = $AnimatedSprite2D.sprite_frames.get_frame_count("revshoot")
	var anim_duration = anim_frame_count / anim_speed
	attack_timer.start(anim_duration)
	
	var bullet = preload("res://bullet.tscn").instantiate()
	
	# Determine shooting direction
	var shoot_direction: Vector2
	if min_character:
		var direction = sign(min_character.position.x - global_position.x)
		$AnimatedSprite2D.flip_h = direction < 0
		attack_area.scale = Vector2(1 if direction < 0 else -1, 1)
		shoot_direction = (min_character.position - Vector2(global_position.x, global_position.y + BULLET_Y_OFFSET)).normalized()
	else:
		shoot_direction = Vector2(-1 if $AnimatedSprite2D.flip_h else 1, 0)
	
	bullet.direction = shoot_direction
	
	# Bullet spawn position
	if $AnimatedSprite2D.flip_h:
		bullet.position.x = global_position.x - BULLET_SPAWN_OFFSET + (velocity.x * BULLET_VELOCITY_FACTOR)
	else:
		bullet.position.x = global_position.x + BULLET_SPAWN_OFFSET + (velocity.x * BULLET_VELOCITY_FACTOR)
	
	bullet.position.y = global_position.y + BULLET_Y_OFFSET
	
	# Add bullet with delay
	await get_tree().create_timer(anim_duration * SHOOT_DELAY_FACTOR).timeout
	get_tree().current_scene.add_child(bullet)
	
func _on_attack_area_body_entered(body: Node2D):
	if body.has_method("take_damage") and not $AttackArea/CollisionShape2D.disabled: 
		var knockback_direction = sign(position.x - body.position.x)
		
		var attack_data = {
			"damage": 1, 
			"source": self,  
			"knockback": HOLD_ATTACK_KNOCKBACK if is_holding_attack else Vector2(QUICK_ATTACK_KNOCKBACK_X * -knockback_direction, QUICK_ATTACK_KNOCKBACK_Y)
		}
		body.take_damage(attack_data)
