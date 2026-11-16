extends Control

# Menú visible dentro de la pantalla de la máquina arcade.
signal juego_elegido(nombre: String)
@export var fuente_arcade: Font

const COLOR_FONDO: Color = Color("#000000")
const COLOR_TEXTO: Color = Color("#FFFFFF")
const COLOR_APAGADO: Color = Color("#888888")

var seleccion: int = 0
var etiqueta_invaders: Label
var etiqueta_pong: Label


func _ready() -> void:
	# Fondo verde oscuro.
	var fondo := ColorRect.new()
	fondo.color = COLOR_FONDO
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Columna centrada en el área de la pantalla.
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 24)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(columna)
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	columna.add_child(_crear_etiqueta("RETROSPACEGAMES", 56, COLOR_TEXTO))
	columna.add_child(_crear_etiqueta("SELECT GAME", 24, COLOR_APAGADO))

	etiqueta_invaders = _crear_etiqueta("", 38, COLOR_TEXTO)
	etiqueta_pong = _crear_etiqueta("", 38, COLOR_TEXTO)
	columna.add_child(etiqueta_invaders)
	columna.add_child(etiqueta_pong)

	columna.add_child(_crear_etiqueta("W / S  -  MOVER     ESPACIO  -  ELEGIR", 20, COLOR_APAGADO))
	_actualizar_seleccion()



func _crear_etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Aplicar la tipografía personalizada.
	if fuente_arcade != null:
		etiqueta.add_theme_font_override("font", fuente_arcade)

	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return etiqueta



func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return

	var codigo: Key = tecla.physical_keycode
	if codigo == 0:
		codigo = tecla.keycode

	match codigo:
		KEY_W, KEY_UP:
			seleccion = 0
			_actualizar_seleccion()
			get_viewport().set_input_as_handled()
		KEY_S, KEY_DOWN:
			seleccion = 1
			_actualizar_seleccion()
			get_viewport().set_input_as_handled()
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			if seleccion == 0:
				juego_elegido.emit("invaders")
			else:
				juego_elegido.emit("pong")


func _actualizar_seleccion() -> void:
	etiqueta_invaders.text = ("▶ " if seleccion == 0 else "   ") + "Outer Space Invaders"
	etiqueta_pong.text = ("▶ " if seleccion == 1 else "   ") + "VacaPong"

	etiqueta_invaders.add_theme_color_override(
		"font_color", COLOR_TEXTO if seleccion == 0 else COLOR_APAGADO
	)
	etiqueta_pong.add_theme_color_override(
		"font_color", COLOR_TEXTO if seleccion == 1 else COLOR_APAGADO
	)
