
extends Container

@export var fuente_arcade: Font

const PUNTOS_PARA_GANAR: int = 5
const FONDO: Color = Color("#000000")
const BLANCO: Color = Color("#FFFFFF")
const LINEAS: Color = Color("#888888")

var pelota: Vector2 = Vector2.ZERO
var velocidad: Vector2 = Vector2.ZERO
var jugador_y: float = 0.0
var cpu_y: float = 0.0
var puntos_jugador: int = 0
var puntos_cpu: int = 0
var jugando: bool = false
var ganador: String = ""
var mensaje: String = "ESPACIO PARA JUGAR"
var saque_hacia: int = 1
var fuente: Font


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuente = fuente_arcade if fuente_arcade != null else ThemeDB.fallback_font
	resized.connect(_al_cambiar_tamano)
	_al_cambiar_tamano()


func _al_cambiar_tamano() -> void:
	jugador_y = size.y * 0.5
	cpu_y = size.y * 0.5
	_reiniciar_pelota()
	jugando = false
	queue_redraw()


func _reiniciar_pelota() -> void:
	pelota = size * 0.5
	var inclinacion: float = randf_range(-0.48, 0.48)
	velocidad = Vector2(float(saque_hacia), inclinacion).normalized() * size.x * 0.58


# CONTROL EXCLUSIVO POR TECLADO
# Espacio inicia, continúa o reinicia la partida.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_empezar_o_continuar()


func _empezar_o_continuar() -> void:
	if jugando:
		return

	if ganador != "":
		puntos_jugador = 0
		puntos_cpu = 0
		ganador = ""
		_reiniciar_pelota()

	jugando = true
	mensaje = ""
	queue_redraw()


func _physics_process(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# La paleta izquierda responde solamente a W/S y flechas.
	var movimiento: float = 0.0

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movimiento -= 1.0

	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movimiento += 1.0

	jugador_y += movimiento * size.y * 1.5 * delta

	# La CPU persigue la pelota, pero tiene velocidad limitada.
	var objetivo_cpu: float = size.y * 0.5

	if jugando and velocidad.x > 0.0:
		objetivo_cpu = pelota.y

	cpu_y = move_toward(cpu_y, objetivo_cpu, size.y * 0.78 * delta)

	_limitar_paletas()

	if jugando:
		_mover_pelota(delta)

	queue_redraw()


func _limitar_paletas() -> void:
	var mitad: float = size.y * 0.24 * 0.5

	jugador_y = clampf(jugador_y, mitad, size.y - mitad)
	cpu_y = clampf(cpu_y, mitad, size.y - mitad)


func _mover_pelota(delta: float) -> void:
	var radio: float = size.y * 0.021
	var margen: float = size.x * 0.045
	var ancho: float = size.x * 0.017
	var mitad_alto: float = size.y * 0.12

	pelota += velocidad * delta

	# Rebotes contra techo y piso.
	if pelota.y - radio <= 0.0:
		pelota.y = radio
		velocidad.y = absf(velocidad.y)

	elif pelota.y + radio >= size.y:
		pelota.y = size.y - radio
		velocidad.y = -absf(velocidad.y)

	# Rebote en la paleta del jugador.
	if velocidad.x < 0.0:
		if pelota.x - radio <= margen + ancho and pelota.x + radio >= margen:
			if absf(pelota.y - jugador_y) <= mitad_alto + radio:
				pelota.x = margen + ancho + radio
				_rebotar(1.0, jugador_y, mitad_alto)

	# Rebote en la paleta de la CPU.
	elif velocidad.x > 0.0:
		var cara_cpu: float = size.x - margen - ancho

		if pelota.x + radio >= cara_cpu and pelota.x - radio <= size.x - margen:
			if absf(pelota.y - cpu_y) <= mitad_alto + radio:
				pelota.x = cara_cpu - radio
				_rebotar(-1.0, cpu_y, mitad_alto)

	# Puntos cuando la pelota sale de la pantalla.
	if pelota.x + radio < 0.0:
		_anotar(false)

	elif pelota.x - radio > size.x:
		_anotar(true)


func _rebotar(sentido: float, centro_paleta: float, mitad_alto: float) -> void:
	var impacto: float = clampf(
		(pelota.y - centro_paleta) / mitad_alto,
		-1.0,
		1.0
	)

	var rapidez: float = minf(
		velocidad.length() * 1.07,
		size.x * 1.25
	)

	velocidad = Vector2(
		sentido,
		impacto * 0.85
	).normalized() * rapidez


func _anotar(punto_del_jugador: bool) -> void:
	jugando = false

	if punto_del_jugador:
		puntos_jugador += 1
		saque_hacia = 1
	else:
		puntos_cpu += 1
		saque_hacia = -1

	if puntos_jugador >= PUNTOS_PARA_GANAR:
		ganador = "GANASTE"
		mensaje = "GANASTE - ESPACIO PARA REINICIAR"

	elif puntos_cpu >= PUNTOS_PARA_GANAR:
		ganador = "PERDISTE"
		mensaje = "PERDISTE - ESPACIO PARA REINICIAR"

	else:
		mensaje = "ESPACIO PARA SACAR"

	_reiniciar_pelota()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var margen: float = size.x * 0.045
	var ancho: float = size.x * 0.017
	var alto: float = size.y * 0.24
	var radio: float = size.y * 0.021

	# Fondo negro, igual que el menú principal.
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)

	# Línea central gris, formada por segmentos rectangulares.
	var largo_segmento: float = size.y * 0.046
	var paso_segmento: float = size.y * 0.082
	var y: float = size.y * 0.11

	while y < size.y * 0.94:
		draw_rect(
			Rect2(size.x * 0.5 - 2.0, y, 4.0, largo_segmento),
			LINEAS
		)
		y += paso_segmento

	# Paletas y pelota blancas.
	draw_rect(
		Rect2(margen, jugador_y - alto * 0.5, ancho, alto),
		BLANCO
	)

	draw_rect(
		Rect2(size.x - margen - ancho, cpu_y - alto * 0.5, ancho, alto),
		BLANCO
	)

	draw_rect(
		Rect2(
			pelota - Vector2(radio, radio),
			Vector2(radio * 2.0, radio * 2.0)
		),
		BLANCO
	)

	# Marcador y título con estética arcade.
	var tam_titulo: int = maxi(12, int(size.y * 0.031))
	var tam_puntos: int = maxi(24, int(size.y * 0.105))

	_texto_centrado(
		"VACAPONG",
		size.x * 0.5,
		size.y * 0.075,
		tam_titulo,
		LINEAS
	)

	_texto_centrado(
		str(puntos_jugador),
		size.x * 0.35,
		size.y * 0.23,
		tam_puntos,
		BLANCO
	)

	_texto_centrado(
		str(puntos_cpu),
		size.x * 0.65,
		size.y * 0.23,
		tam_puntos,
		BLANCO
	)

	if not jugando:
		var tam_mensaje: int = maxi(12, int(size.y * 0.03))

		_texto_centrado(
			mensaje,
			size.x * 0.5,
			size.y * 0.76,
			tam_mensaje,
			BLANCO
		)


func _texto_centrado(
	contenido: String,
	centro_x: float,
	y: float,
	tam: int,
	color: Color
) -> void:
	if fuente == null:
		return

	# Reducir tamaño si el texto no entra en pantalla.
	var tam_ajustado: int = tam

	var ancho_texto: float = fuente.get_string_size(
		contenido,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		tam_ajustado
	).x

	while ancho_texto > size.x * 0.90 and tam_ajustado > 9:
		tam_ajustado -= 1

		ancho_texto = fuente.get_string_size(
			contenido,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			tam_ajustado
		).x

	draw_string(
		fuente,
		Vector2(centro_x - ancho_texto * 0.5, y),
		contenido,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		tam_ajustado,
		color
	)
