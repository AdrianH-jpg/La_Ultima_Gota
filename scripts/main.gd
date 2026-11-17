## Controlador principal de la partida: gestiona vidas, niveles y el ovni
class_name ControladorPartida
extends Node2D

@export var escena_ovni: PackedScene
@export var vidas_iniciales: int = 3

var _vidas_actuales: int = 3
var _nivel_actual: int = 1

@onready var _player: Node2D = $Player
@onready var _timer_ovni: Timer = $TimerOvni

# Configura las vidas iniciales, escucha las señales de derrota o nivel completado y arranca el timer del OVNI
func _ready() -> void:
	_vidas_actuales = vidas_iniciales
	Eventos.jugador_destruido.connect(_on_jugador_destruido)
	Eventos.nivel_superado.connect(_on_nivel_superado)
	
	_timer_ovni.wait_time = randf_range(2.0, 4.0)
	_timer_ovni.timeout.connect(_on_timer_ovni_timeout)
	_timer_ovni.start()

# Hace aparecer un OVNI en la parte superior y programa el siguiente con un tiempo aleatorio más largo
func _on_timer_ovni_timeout() -> void:
	if escena_ovni != null:
		var nuevo_ovni: Node2D = escena_ovni.instantiate()
		nuevo_ovni.global_position = Vector2(0, 40)
		add_child(nuevo_ovni)
	
	_timer_ovni.wait_time = randf_range(15.0, 30.0)
	_timer_ovni.start()

# Sube el contador de nivel y avisa al HUD para que muestre el cartel en pantalla
func _on_nivel_superado() -> void:
	_nivel_actual += 1
	Eventos.actualizar_nivel_hud.emit(_nivel_actual)

# al morir descuenta una vida, espera 1.5 segundos y revive al jugador, si no manda al Game Over
func _on_jugador_destruido() -> void:
	_vidas_actuales -= 1
	if _vidas_actuales > 0:
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(_player) and _player.has_method("reaparecer"):
			_player.reaparecer()
	else:
		# Eventos.puntaje_actual ya contiene el puntaje actualizado
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game_over.tscn")
