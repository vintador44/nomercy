extends CharacterBody2D

# Physics constants
const GRAVITY = 1000
const MOVE_SPEED = 30
const KNOCKBACK_POWER = 1000
const KNOCKBACK_DURATION = 0.2

# Attack constants
const ATTACK_RANGE = 100
const ATTACK_SPEED = 300
const ATTACK_DELAY = 0.7
const ATTACK_COOLDOWN = 3.2
const ATTACK_HIT_RANGE_BUFFER = 10

# Damage constants
const ATTACK_DAMAGE = 1
const MAX_HEALTH = 200
const KNOCKBACK_FORCE_X = 0.3
const KNOCKBACK_FORCE_Y = -0.3

# Node references
var player: CharacterBody2D
var animation: AnimatedSprite2D
var knockback_timer: Timer
var attack_timer: Timer
var marker: Sprite2D

# State variables
var player_vector: Vector2
var is_marker = false
var is_attacking = false
var attack_cooldown = false
var is_knockback_active = false
var attack_direction = 0
var health = MAX_HEALTH

func _ready() -> void:
	# Initialize timers
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = ATTACK_DELAY
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	knockback_timer = Timer.new()
	add_child(knockback_timer)
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)
	knockback_timer.one_shot = true
	
	# Get nodes
	marker = $marker
	animation = $AnimatedSprite2D
	
	# Initial state
	animation.play("walk")
	add_to_group("enemy")

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance_to_player = position.distance_to(player.position)
	
	# Marker visibility
	marker.visible = is_marker
	
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Attack movement
	if is_attacking:
		velocity.x = attack_direction * ATTACK_SPEED
		move_and_slide()
		return
	
	# Check for attack
	if distance_to_player <= ATTACK_RANGE and not is_attacking and not attack_cooldown:
		start_attack()
		return
	
	# Normal movement
	if not is_attacking and not is_knockback_active:
		animation.play("walk")
		
		if not is_knockback_active:
			player_vector = (player.position - position).normalized()
			
			# Flip sprite based on direction
			animation.flip_h = player_vector.x < 0
			
			if is_on_floor():
				velocity.x = player_vector.x * MOVE_SPEED

	move_and_slide()

func start_attack():
	is_attacking = true
	attack_cooldown = true
	animation.play("attack")
	
	# Determine attack direction
	attack_direction = sign(player.global_position.x - global_position.x)
	if attack_direction == 0:
		attack_direction = 1  # Default to right if directly above/below
	
	attack_timer.start()

func _on_attack_timer_timeout():
	if not player:
		end_attack()
		return
	
	# Check hit
	if position.distance_to(player.position) <= ATTACK_RANGE + ATTACK_HIT_RANGE_BUFFER:
		if player.has_method("get_damage"):
			var knockback_direction = sign(position.x - player.position.x)
			
			var attack_data = {
				"damage": ATTACK_DAMAGE,
				"source": self,
				"knockback": Vector2(KNOCKBACK_FORCE_X * -knockback_direction, KNOCKBACK_FORCE_Y)
			}
			
			player.get_damage(attack_data)
	
	end_attack()

func end_attack():
	is_attacking = false
	velocity.x = 0
	
	# Cooldown before next attack
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	attack_cooldown = false
	animation.play("walk")

func take_damage(info):
	health -= info.damage
	
	# Apply knockback
	velocity.y = info.knockback.y * KNOCKBACK_POWER
	velocity.x = info.knockback.x * KNOCKBACK_POWER 
	is_knockback_active = true
	knockback_timer.start(KNOCKBACK_DURATION)
	
	if health <= 0:
		queue_free()

func _on_knockback_timer_timeout():
	is_knockback_active = false
