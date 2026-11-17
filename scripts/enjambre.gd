class_name Enjambre
extends Node2D

@export_group("Configuración de Grilla")
@export var tipos_de_enemigos: Array[PackedScene]
@export var filas: int = 4
@export var columnas: int = 8
@export var separacion: Vector2 = Vector2(60, 50)
@export var escena_bala_enemiga: PackedScene

@export_group("Movimiento")
@export var velocidad: float = 35.0
@export var bajada: float = 20.0
@export var margen_borde: float = 24.0

@onready var _audio_paso: AudioStreamPlayer = $AudioPaso

var _notas_paso: Array[AudioStream] = [
	preload("res://assets/audio/paso1.wav"),
	preload("res://assets/audio/paso2.wav"),
	preload("res://assets/audio/paso3.wav")
]

var _indice_nota: int = 0
var _temporizador_paso: float = 0.0
var _intervalo_paso: float = 0.8
var _direccion: int = 1
var _posicion_inicial: Vector2
var _activo: bool = true

# Guarda dónde arranca la formación, escucha cuando muere un alien y arma la grilla inicial
func _ready() -> void:
	_posicion_inicial = global_position
	Eventos.enemigo_destruido.connect(_al_morir_enemigo)
	generar_grilla()

# Crea toda la matriz de enemigos fila por fila, alternando el tipo de nave según la fila
func generar_grilla() -> void:
	if tipos_de_enemigos.is_empty():
		return
		
	for fila in range(filas):
		var indice: int = fila % tipos_de_enemigos.size()
		var escena_elegida: PackedScene = tipos_de_enemigos[indice]
		
		for col in range(columnas):
			var nuevo_enemigo: Node2D = escena_elegida.instantiate()
			nuevo_enemigo.position = Vector2(col * separacion.x, fila * separacion.y)
			add_child(nuevo_enemigo)

# Mueve todo el bloque de lado a lado, hace sonar los pasos, baja al tocar un borde y chequea si llegaron abajo
func _physics_process(delta: float) -> void:
	if not _activo:
		return
		
	position.x += velocidad * _direccion * delta
	
	_temporizador_paso += delta
	if _temporizador_paso >= _intervalo_paso:
		_temporizador_paso = 0.0
		_reproducir_paso()
	
	var ancho_pantalla: float = get_viewport_rect().size.x
	var toco_borde: bool = false
	
	for nodo in get_children():
		if nodo is Enemigo and not nodo.is_queued_for_deletion():
			var paso_izquierda: bool = nodo.global_position.x <= margen_borde and _direccion == -1
			var paso_derecha: bool = nodo.global_position.x >= (ancho_pantalla - margen_borde) and _direccion == 1
			if paso_izquierda or paso_derecha:
				toco_borde = true
				break
			
	if toco_borde:
		_direccion *= -1
		position.y += bajada
		
	var altura_pantalla: float = get_viewport_rect().size.y
	if global_position.y > altura_pantalla - 100.0:
		get_tree().change_scene_to_file("res://scenes/Game Over.tscn")

# Cada vez que salta el Timer, elige un alien vivo al azar y dispara hacia abajo
func _on_timer_timeout() -> void:
	if not _activo:
		return
		
	var aliens_vivos: Array[Enemigo] = []
	for hijo in get_children():
		if hijo is Enemigo and not hijo.is_queued_for_deletion():
			aliens_vivos.append(hijo)
			
	if not aliens_vivos.is_empty() and escena_bala_enemiga != null:
		var tirador: Enemigo = aliens_vivos.pick_random()
		var nueva_bala: Node2D = escena_bala_enemiga.instantiate()
		nueva_bala.global_position = tirador.global_position
		get_tree().current_scene.add_child(nueva_bala)

# Espera al final del frame cuando muere un enemigo para contar cunatos nemiogos quedan
func _al_morir_enemigo(_puntos: int) -> void:
	call_deferred("_verificar_nivel_completado")

# Revisa si ya limpiamos toda la oleada; si quedan vivos, acelera el ritmo del sonido de marcha
func _verificar_nivel_completado() -> void:
	var total_vivos: int = 0
	for nodo in get_children():
		if nodo is Enemigo and not nodo.is_queued_for_deletion():
			total_vivos += 1
			
	if total_vivos == 0:
		_pasar_de_nivel()
	else:
		_intervalo_paso = clampf(float(total_vivos) * 0.025, 0.15, 0.8)

# Sube la dificultad, espera 2 segundos y vuelve a armar la formación y le suma velocidad
func _pasar_de_nivel() -> void:
	_activo = false
	velocidad += 30.0
	Eventos.nivel_superado.emit()
	
	await get_tree().create_timer(2.0).timeout
	
	global_position = _posicion_inicial
	_direccion = 1
	generar_grilla()
	_intervalo_paso = 0.8
	_temporizador_paso = 0.0
	_activo = true

# trata de acelerar el audio para parecer al original
func _reproducir_paso() -> void:
	if _notas_paso.is_empty() or _audio_paso == null:
		return
	_audio_paso.stream = _notas_paso[_indice_nota]
	_audio_paso.play()
	_indice_nota = (_indice_nota + 1) % _notas_paso.size()
