## Proyectil disparado por las naves enemigas hacia la parte inferior.
class_name BalaEnemiga
extends Area2D

@export var velocidad: float = 400.0
@export var dano: int = 1

func _physics_process(delta: float) -> void:
	position.y += velocidad * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador") and body.has_method("recibir_dano"):
		body.recibir_dano(dano)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Polimorfismo: tanto Jugador como Bunker responden a recibir_dano()
	if (area.is_in_group("Jugador") or area.is_in_group("bunkers")) and area.has_method("recibir_dano"):
		area.recibir_dano(dano)
		call_deferred("queue_free")
