## Pantalla de menú principal con visualización de Top 10 local y código secreto.
class_name MenuPrincipal
extends Control

const COMBINACION_SECRETA: Array[String] = ["arriba", "arriba", "abajo", "disparar"]

var _historial_teclas: Array[String] = []

@onready var _boton_start: BaseButton = $MenuButton
@onready var _sonido_start: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var _texto_high_score: Label = $HiScore
@onready var _tabla_posiciones: Label = $TablaPosiciones

func _ready() -> void:
	actualizar_textos_pantalla(Eventos.obtener_top_10())

## Formatea y muestra el Top 10 de puntajes locales en pantalla.
func actualizar_textos_pantalla(tabla: Array) -> void:
	if tabla.is_empty():
		_texto_high_score.text = "HI-SCORE: 0000"
		_tabla_posiciones.text = "--- TOP 10 ---\n\nSIN REGISTROS"
		return

	_texto_high_score.text = "HI-SCORE: " + str(tabla[0]["puntos"]).pad_zeros(4)
	var texto_tabla: String = "--- TOP 10 ---\n\n"

	for i in range(tabla.size()):
		var registro: Dictionary = tabla[i]
		var puesto: String = str(i + 1).pad_zeros(2)
		var puntos_alineados: String = str(registro["puntos"]).pad_zeros(4)
		texto_tabla += puesto + ". " + str(registro["nombre"]) + "  -  " + puntos_alineados + "\n"

	_tabla_posiciones.text = texto_tabla

func _on_menu_button_pressed() -> void:
	Eventos.puntaje_actual = 0
	if _sonido_start != null and _sonido_start.stream != null:
		_sonido_start.play()
	Eventos.cambiar_escena_minijuego(self, "res://scenes/main.tscn")

func _on_timer_timeout() -> void:
	_boton_start.visible = not _boton_start.visible

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		for accion in COMBINACION_SECRETA:
			if event.is_action_pressed(accion):
				_historial_teclas.append(accion)
				_verificar_combinacion()
				break

func _verificar_combinacion() -> void:
	if _historial_teclas.size() > COMBINACION_SECRETA.size():
		_historial_teclas.pop_front()

	if _historial_teclas == COMBINACION_SECRETA:
		_activar_nivel_secreto()

func _activar_nivel_secreto() -> void:
	Eventos.cambiar_escena_minijuego(self, "res://scenes/Game Over.tscn")

func _on_timer_2_timeout() -> void:
	_tabla_posiciones.visible = not _tabla_posiciones.visible
