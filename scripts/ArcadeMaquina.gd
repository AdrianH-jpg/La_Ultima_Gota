extends Node2D

# Controla el marco, los controles físicos y las escenas de la pantalla.
@export var escena_menu: PackedScene
@export var escena_pong: PackedScene
@export var escena_invaders: PackedScene

@onready var pantalla: Control = $Container
@onready var palanca: AnimatedSprite2D = $PALANCA
@onready var boton: AnimatedSprite2D = $BOTON

var direccion_actual: StringName = &""
var boton_presionado: bool = false
var contenido_actual: Control
var en_menu: bool = true


func _ready() -> void:
	palanca.stop()
	boton.stop()
	palanca.animation = &"atras"
	palanca.frame = 0
	boton.animation = &"default"
	boton.frame = 0

	pantalla.clip_contents = true
	mostrar_menu()


func _process(_delta: float) -> void:
	_actualizar_palanca()
	_actualizar_boton()


func _obtener_direccion() -> StringName:
	if Input.is_key_pressed(KEY_A):
		return &"izquierda"
	if Input.is_key_pressed(KEY_D):
		return &"derecha"
	if Input.is_key_pressed(KEY_W):
		return &"atras"
	if Input.is_key_pressed(KEY_S):
		return &"adelante"
	return &""


func _actualizar_palanca() -> void:
	var nueva_direccion := _obtener_direccion()
	if nueva_direccion == direccion_actual:
		return

	direccion_actual = nueva_direccion
	if direccion_actual == &"":
		palanca.frame = 0
	else:
		palanca.animation = direccion_actual
		palanca.frame = 1


func _actualizar_boton() -> void:
	var presionado := Input.is_key_pressed(KEY_SPACE)
	if presionado == boton_presionado:
		return

	boton_presionado = presionado
	boton.frame = 1 if presionado else 0


func mostrar_menu() -> void:
	en_menu = true
	_mostrar_escena(escena_menu)


func _abrir_juego(nombre: String) -> void:
	match nombre:
		"pong":
			if escena_pong == null:
				push_warning("Asigna VacaPong.tscn a escena_pong en el Inspector.")
				return
			en_menu = false
			_mostrar_escena(escena_pong)
		"invaders":
			en_menu = false
			if escena_invaders != null:
				_mostrar_escena(escena_invaders)
			else:
				_mostrar_proximamente()


func _quitar_contenido_actual() -> void:
	if is_instance_valid(contenido_actual):
		pantalla.remove_child(contenido_actual)
		contenido_actual.queue_free()
		contenido_actual = null


func _mostrar_escena(recurso: PackedScene) -> void:
	if recurso == null:
		push_error("Falta asignar una escena en el Inspector de ARCADE_MAQ.")
		return

	var nueva_instancia := recurso.instantiate()
	if not (nueva_instancia is Control):
		push_error("La escena cargada debe tener un nodo Control o Container como raíz.")
		nueva_instancia.queue_free()
		return

	_quitar_contenido_actual()
	contenido_actual = nueva_instancia as Control
	pantalla.add_child(contenido_actual)
	contenido_actual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if contenido_actual.has_signal("juego_elegido"):
		contenido_actual.connect("juego_elegido", _abrir_juego)


func _mostrar_proximamente() -> void:
	_quitar_contenido_actual()

	var fondo := ColorRect.new()
	fondo.color = Color("#101b17")
	pantalla.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenido_actual = fondo

	var aviso := Label.new()
	aviso.text = "OUTER SPACE INVADERS\n\nPRÓXIMAMENTE\n\nESC PARA VOLVER"
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 36)
	aviso.add_theme_color_override("font_color", Color("#d8f5df"))
	fondo.add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _unhandled_input(event: InputEvent) -> void:
	if en_menu or not (event is InputEventKey):
		return

	var tecla := event as InputEventKey
	if tecla.pressed and not tecla.echo and tecla.keycode == KEY_ESCAPE:
		mostrar_menu()
		get_viewport().set_input_as_handled()
