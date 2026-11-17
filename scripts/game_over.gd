## Pantalla de fin de partida 
class_name PantallaGameOver
extends Control

@onready var _sonido_game_over: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var _ingreso_nombre: LineEdit = $IngresoNombre
@onready var _btn_guardar: Button = $BtnGuardarRecord
@onready var _btn_jugar: Button = $VBoxContainer/BtnJugar
@onready var _btn_menu: Button = $VBoxContainer/BtnMenu

# Pone la música de derrota y decide si mostrar el cuadro de récord o los botones normales
func _ready() -> void:
	if _sonido_game_over.stream != null:
		_sonido_game_over.play()

	if Eventos.califica_en_top_10(Eventos.puntaje_actual):
		_ingreso_nombre.visible = true
		_btn_guardar.visible = true
		_btn_jugar.visible = false
		_btn_menu.visible = false
	else:
		_ingreso_nombre.visible = false
		_btn_guardar.visible = false
		_btn_jugar.visible = true
		_btn_menu.visible = true

# Guarda las iniciales en el Top 10 (pone "AAA" si quedó vacío), resetea puntos y vuelve al menú
func _on_btn_guardar_record_pressed() -> void:
	_btn_guardar.disabled = true
	
	var nombre: String = _ingreso_nombre.text.strip_edges().to_upper()
	if nombre.is_empty():
		nombre = "AAA"
		
	Eventos.guardar_record_local(Eventos.puntaje_actual, nombre)
	Eventos.puntaje_actual = 0
	Eventos.cambiar_escena_minijuego(self, "res://scenes/main_menu.tscn")

# Reinicia el puntaje y arranca una nueva partida
func _on_btn_jugar_pressed() -> void:
	Eventos.puntaje_actual = 0
	Eventos.cambiar_escena_minijuego(self, "res://scenes/main.tscn")

# Reinicia el puntaje y vuelve a la pantalla principal
func _on_btn_menu_pressed() -> void:
	Eventos.puntaje_actual = 0
	Eventos.cambiar_escena_minijuego(self, "res://scenes/main_menu.tscn")

# Fuerza mayúsculas mientras el jugador escribe sus iniciales 
func _on_ingreso_nombre_text_changed(new_text: String) -> void:
	_ingreso_nombre.text = new_text.to_upper()
	_ingreso_nombre.caret_column = _ingreso_nombre.text.length()
