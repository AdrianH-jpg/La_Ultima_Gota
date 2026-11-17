
extends Container

# VACAPONG

@export var fuente_arcade: Font

const PUNTOS_PARA_GANAR: int = 5
const FONDO: Color = Color("#000000")
const BLANCO: Color = Color("#FFFFFF")
const LINEAS: Color = Color("#888888")

# Estado de la pelotita
var pelota: Vector2 = Vector2.ZERO
var velocidad: Vector2 = Vector2.ZERO

# Estado de la partida
var puntos_jugador: int = 0
var puntos_cpu: int = 0
var jugando: bool = false
var ganador: String = ""
var mensaje: String = "ESPACIO PARA JUGAR"
var saque_hacia: int = 1
var fuente: Font


var _paleta_jugador: PaletaJugador
var _paleta_cpu: PaletaCPU

# Ambas paletas se tratan mediante su clase base para que se mantengan iguales
var _paletas: Array[PaletaBase] = []


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	fuente = fuente_arcade if fuente_arcade != null else ThemeDB.fallback_font

	# Crear las instancias de las clasess
	_paleta_jugador = PaletaJugador.new()
	_paleta_cpu = PaletaCPU.new()

	# con esot guarda los objetos como tiupo PaletaBase
	_paletas.append(_paleta_jugador)
	_paletas.append(_paleta_cpu)

	resized.connect(_al_cambiar_tamano)
	_al_cambiar_tamano()


# INICIALIZACION Y REINICIO

func _al_cambiar_tamano() -> void:
	# velocidades orishinales
	_paleta_jugador.inicializar(size.y, 1.5)
	_paleta_cpu.inicializar(size.y, 0.78)

	_reiniciar_pelota()
	jugando = false
	queue_redraw()


func _reiniciar_pelota() -> void:
	pelota = size * 0.5

	var inclinacion: float = randf_range(-0.48, 0.48)

	velocidad = Vector2(
		float(saque_hacia),
		inclinacion
	).normalized() * size.x * 0.58


# CONTROLES DE LA PARTIDA

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


# ACTUALIZACION DEL JUEGO

func _physics_process(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# 
	# 
	for paleta in _paletas:
		paleta.actualizar_movimiento(
			delta,
			size.y,
			pelota.y,
			jugando,
			velocidad.x
		)

	# La pelota se mueve cuando la partida esta en marcha
	if jugando:
		_mover_pelota(delta)

	queue_redraw()


# MOVIMIENTO Y COLISIONES DE LA PELOTA

func _mover_pelota(delta: float) -> void:
	var radio: float = size.y * 0.021
	var margen: float = size.x * 0.045
	var ancho: float = size.x * 0.017
	var mitad_alto: float = size.y * 0.12

	# Obtener las posiciones mediante metodos
	var jugador_y: float = _paleta_jugador.obtener_posicion_y()
	var cpu_y: float = _paleta_cpu.obtener_posicion_y()

	pelota += velocidad * delta

	# Rebote contra techo y piso
	if pelota.y - radio <= 0.0:
		pelota.y = radio
		velocidad.y = absf(velocidad.y)

	elif pelota.y + radio >= size.y:
		pelota.y = size.y - radio
		velocidad.y = -absf(velocidad.y)

	# Rebote contra la paleta del jugador
	if velocidad.x < 0.0:
		if pelota.x - radio <= margen + ancho and pelota.x + radio >= margen:
			if absf(pelota.y - jugador_y) <= mitad_alto + radio:
				pelota.x = margen + ancho + radio
				_rebotar(1.0, jugador_y, mitad_alto)

	# Rebote contra la paleta de la CPU
	elif velocidad.x > 0.0:
		var cara_cpu: float = size.x - margen - ancho

		if pelota.x + radio >= cara_cpu and pelota.x - radio <= size.x - margen:
			if absf(pelota.y - cpu_y) <= mitad_alto + radio:
				pelota.x = cara_cpu - radio
				_rebotar(-1.0, cpu_y, mitad_alto)

	# Detecta los puntos
	
	if pelota.x + radio < 0.0:
		_anotar(false)

	elif pelota.x - radio > size.x:
		_anotar(true)


func _rebotar(
	sentido: float,
	centro_paleta: float,
	mitad_alto: float
) -> void:
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


# SISTEMA DE PUNTUACION

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


# todo esto es para hacer los dibujitos del juego en pantalla

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var margen: float = size.x * 0.045
	var ancho: float = size.x * 0.017
	var alto: float = size.y * 0.24
	var radio: float = size.y * 0.021

	# Consultar la posicion de cada paletita
	var jugador_y: float = _paleta_jugador.obtener_posicion_y()
	var cpu_y: float = _paleta_cpu.obtener_posicion_y()

	# Fondo negro
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)

	# Linea central
	var largo_segmento: float = size.y * 0.046
	var paso_segmento: float = size.y * 0.082
	var y: float = size.y * 0.11

	while y < size.y * 0.94:
		draw_rect(
			Rect2(
				size.x * 0.5 - 2.0,
				y,
				4.0,
				largo_segmento
			),
			LINEAS
		)

		y += paso_segmento

	# Paleta del jugador
	draw_rect(
		Rect2(
			margen,
			jugador_y - alto * 0.5,
			ancho,
			alto
		),
		BLANCO
	)

	# Paleta de la CPU
	draw_rect(
		Rect2(
			size.x - margen - ancho,
			cpu_y - alto * 0.5,
			ancho,
			alto
		),
		BLANCO
	)

	# Pelota cuadrada
	draw_rect(
		Rect2(
			pelota - Vector2(radio, radio),
			Vector2(radio * 2.0, radio * 2.0)
		),
		BLANCO
	)

	# Tipografia y marcador
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


# esto es para los textos en el centro

func _texto_centrado(
	contenido: String,
	centro_x: float,
	y: float,
	tam: int,
	color: Color
) -> void:
	if fuente == null:
		return

	# Reducir el tamano si el texto no entra
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
