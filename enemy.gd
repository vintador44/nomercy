extends CharacterBody2D

var gravity = 1000
var speed = 30
var player: CharacterBody2D
var player_vector
var animation: Sprite2D
var health = 200
var knockback_power = 1000
var knockback_timer: Timer
var is_knockback_active = false
var marker :Sprite2D
var is_marker = false

func _ready() -> void:
	animation = $Sprite2D
	
	knockback_timer = Timer.new()
	add_child(knockback_timer)
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)
	knockback_timer.one_shot = true
	marker = $marker
	add_to_group("enemy")
	

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	
	if is_marker:
		marker.visible = true
	else:
		marker.visible = false
	# Применяем 
	velocity.y += gravity * delta
	
	# Только если нет нокбэка, преследуем игрока
	if not is_knockback_active:
		player_vector = (player.position - position).normalized()
		
		if player_vector.x > 0:
			animation.flip_h = false
		else:
			animation.flip_h = true
			
		if is_on_floor():
			velocity.x = player_vector.x * speed
	
	move_and_slide()

func take_damage(info):
	health -= info.damage
	
	# Применяем нокбэк
	velocity.y = info.knockback.y * knockback_power
	velocity.x = info.knockback.x * knockback_power 
	is_knockback_active = true
	knockback_timer.start(0.2) # 0.2 секунды нокбэка
	
	if health <= 0:
		queue_free()

func _on_knockback_timer_timeout():
	is_knockback_active = false
