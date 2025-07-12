extends Area2D


var speed = 700  # Скорость пули
var direction = Vector2.RIGHT  # Направление (можно менять)

func _physics_process(delta):
	position += direction * speed * delta  # Движение пули

# Если пуля выходит за экран, удаляем её
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# Если пуля во что-то врезается
func _on_body_entered(body):
	
	if body.has_method("take_damage"): 
		var attack_data = {
			"damage": 1, 
			"source": self,  
			"knockback":  Vector2(0.3, -0.2)
		}
		body.take_damage(attack_data)
	queue_free()  # Удаляем пулю
