## Interfaz gráfica en partida que muestra puntaje, top, vidas y nivel.
class_name HudJuego
extends CanvasLayer

@onready var _contenedor_vidas: Control = $ContenedorVidas
@onready var _texto_high_score: Label = $HighScore
@onready var _texto_score: Label = $Score
@onready var _mensaje_central: Label = $MensajeCentral

# Conecta las señales globales del juego y carga en pantalla el puntaje inicial y el record
func _ready() -> void:
	Eventos.enemigo_destruido.connect(_sumar_puntos)
	Eventos.jugador_destruido.connect(_restar_icono_vida)
	Eventos.actualizar_nivel_hud.connect(_mostrar_cartel_nivel)
	
	_texto_score.text = "Score : " + str(Eventos.puntaje_actual)
	_texto_high_score.text = "HI-SCORE: " + str(Eventos.mejor_puntaje_local) + " (" + Eventos.nombre_record_local + ")"

# Suma los puntos del alien destruido y refresca el texto del marcador
func _sumar_puntos(valor_del_alien: int) -> void:
	Eventos.puntaje_actual += valor_del_alien
	_texto_score.text = "Score : " + str(Eventos.puntaje_actual)

# Recorre los íconos de vida de derecha a izquierda y oculta el último que siga visible
func _restar_icono_vida() -> void:
	var iconos: Array[Node] = _contenedor_vidas.get_children()
	for i in range(iconos.size() - 1, -1, -1):
		if iconos[i].visible:
			iconos[i].hide()
			break

# Muestra el aviso del nuevo nivel en el centro de la pantalla durante 2 segundos
func _mostrar_cartel_nivel(nuevo_nivel: int) -> void:
	_mensaje_central.text = "NIVEL " + str(nuevo_nivel)
	_mensaje_central.show()
	await get_tree().create_timer(2.0).timeout
	_mensaje_central.hide()
