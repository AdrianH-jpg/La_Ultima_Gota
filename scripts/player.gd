## Representa la nave controlada por el jugador (teclado y pantalla táctil).
## Encapsula su estado vital, invulnerabilidad temporal y disparo.
class_name Jugador
extends CharacterBody2D

@export var velocidad: float = 400.0
@export var margen_pantalla: float = 20.0
@export var escena_bala: PackedScene
@export var escena_explosion: PackedScene = preload("res://scenes/explosion.tscn")

@onready var _sonido_disparo: AudioStreamPlayer2D = $SonidoDisparo
@onready var _colision: CollisionShape2D = $CollisionShape2D
@onready var _sprite: CanvasItem = $Sprite2D

# Atributos encapsulados (privados por convención con _)
var _dedo_movimiento: int = -1
var _distancia_dedo: float = 0.0
var _es_invulnerable: bool = false
var _posicion_inicial: Vector2
var _vivo: bool = true

func _ready() -> void:
	add_to_group("Jugador")
	_posicion_inicial = global_position

func _physics_process(_delta: float) -> void:
	if not _vivo:
		return
		
	_mover_nave()
	_limitar_a_pantalla()
	
	if Input.is_action_just_pressed("disparar"):
		disparar()

## Permite consultar de forma segura si la nave está activa.
func esta_vivo() -> bool:
	return _vivo

## Interfaz polimórfica común para recibir daño desde proyectiles o enemigos.
func recibir_dano(_cantidad: int = 1) -> void:
	morir()

## Dispara un proyectil si no existe otro del jugador activo en pantalla.
func disparar() -> void:
	if get_tree().get_node_count_in_group("balas_jugador") == 0 and escena_bala != null:
		var nueva_bala: Node2D = escena_bala.instantiate()
		Eventos.instanciar_en_nivel(self, nueva_bala)
		nueva_bala.global_position = global_position
		_sonido_disparo.play()

## Gestiona la destrucción temporal de la nave y notifica al sistema de eventos.
func morir() -> void:
	if _es_invulnerable or not _vivo:
		return
		
	_vivo = false
	_instanciar_explosion_grave()
	
	hide()
	_colision.set_deferred("disabled", true)
	
	var camara: Camera2D = get_viewport().get_camera_2d()
	if camara != null and camara.has_method("aplicar_shake"):
		camara.aplicar_shake(15.0)
	
	Eventos.jugador_destruido.emit()

## Restaura la nave en su posición inicial con inmunidad temporal.
func reaparecer() -> void:
	global_position = _posicion_inicial
	show()
	_colision.set_deferred("disabled", false)
	_vivo = true
	iniciar_invulnerabilidad(2.0)

## Activa un efecto de parpadeo e invulnerabilidad durante los segundos indicados.
func iniciar_invulnerabilidad(duracion: float = 2.0) -> void:
	_es_invulnerable = true
	var tiempo_transcurrido: float = 0.0
	
	while tiempo_transcurrido < duracion:
		if is_instance_valid(_sprite):
			_sprite.visible = not _sprite.visible
		await get_tree().create_timer(0.1).timeout
		tiempo_transcurrido += 0.1
		
	if is_instance_valid(_sprite):
		_sprite.visible = true
	_es_invulnerable = false

# --- MÉTODOS PRIVADOS ---

func _mover_nave() -> void:
	var direccion: float = Input.get_axis("mover_izquierda", "mover_derecha")
	velocity.x = direccion * velocidad
	velocity.y = 0.0
	move_and_slide()

func _limitar_a_pantalla() -> void:
	var ancho_pantalla: float = get_viewport_rect().size.x
	global_position.x = clampf(global_position.x, margen_pantalla, ancho_pantalla - margen_pantalla)

func _instanciar_explosion_grave() -> void:
	if escena_explosion == null:
		return
		
	var boom: Node2D = escena_explosion.instantiate()
	var pos_muerte: Vector2 = global_position
	
	var audio: Node = boom.get_node_or_null("AudioStreamPlayer2D")
	if audio == null:
		audio = boom.get_node_or_null("AudioStreamPlayer")
	if audio != null:
		audio.pitch_scale = 0.2
		
	Eventos.instanciar_en_nivel(self, boom)
	boom.global_position = pos_muerte

func _input(event: InputEvent) -> void:
	if not _vivo:
		return
		
	var mitad_pantalla: float = get_viewport_rect().size.x / 2.0

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > mitad_pantalla:
				Input.action_press("disparar")
				Input.action_release("disparar")
			else:
				if _dedo_movimiento == -1:
					_dedo_movimiento = event.index
					_distancia_dedo = position.x - event.position.x
		else:
			if event.index == _dedo_movimiento:
				_dedo_movimiento = -1

	elif event is InputEventScreenDrag:
		if event.index == _dedo_movimiento:
			position.x = event.position.x + _distancia_dedo
			_limitar_a_pantalla()
