## Clase base que define la estructura y el comportamiento común de cualquier
## entidad destructible dentro del juego (enemigos, búnkers, ovni y futuros boses).
class_name EntidadEspacial
extends Area2D

@export var escena_explosion: PackedScene

var _vidas: int = 1:
	set(valor):
		_vidas = max(0, valor)
	get:
		return _vidas

# Define con cuánta vida arranca esta entidad
func configurar_vidas(cantidad: int) -> void:
	_vidas = cantidad

# Devuelve cuántas vidas le quedan actualmente
func obtener_vidas() -> int:
	return _vidas

# Resta vida al recibir un impacto y dispara la destrucción si llega a cero
func recibir_dano(cantidad: int = 1) -> void:
	_vidas -= cantidad
	if _vidas <= 0:
		destruir()

# Hace explotar la entidad y la elimina de la escena de forma segura
func destruir() -> void:
	_instanciar_explosion()
	call_deferred("queue_free")

# Crea el efecto de explosión justo donde murió la entidad
func _instanciar_explosion() -> void:
	if escena_explosion != null:
		var posicion_muerte: Vector2 = global_position
		var nueva_explosion: Node2D = escena_explosion.instantiate()
		nueva_explosion.global_position = posicion_muerte
		Eventos.instanciar_en_nivel(self, nueva_explosion, true)
