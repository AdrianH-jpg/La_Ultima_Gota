class_name BalaJugador
extends Area2D

@export var velocidad: float = 600.0
@export var dano: int = 1

# Mete la bala en un grupo apenas nace para identificarla fácil si hace falta
func _ready() -> void:
	add_to_group("balas_jugador")

# Mueve el disparo derecho hacia arriba en cada frame de física
func _physics_process(delta: float) -> void:
	position.y -= velocidad * delta

# Limpia la bala de la escena
func autodestruirse() -> void:
	queue_free()

# Si sale de la pantalla por arriba, la borramos para no gastar memoria
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	autodestruirse()

# Cuando choca contra algo destructible (enemigo, búnker u ovni), le hace daño y desaparece
func _on_area_entered(area: Area2D) -> void:
	if area is EntidadEspacial and not area.is_in_group("Jugador"):
		area.recibir_dano(dano)
		call_deferred("queue_free")
