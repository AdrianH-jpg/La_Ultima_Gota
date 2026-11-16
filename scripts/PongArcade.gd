extends Container

# Pong para una pantalla de arcade hecha con un nodo Container.
# Jugador: W/S, flechas o mouse. Espacio o clic: iniciar/sacar.

const PUNTOS_PARA_GANAR: int = 5
const FONDO: Color = Color("#101b17")
const BLANCO: Color = Color("#d8f5df")
const LINEAS: Color = Color("#678e78")

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
	mouse_filter = Control.MOUSE_FILTER_STOP
	fuente = ThemeDB.fallback_font
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

	# La paleta izquierda también responde al teclado.
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
	var impacto: float = clampf((pelota.y - centro_paleta) / mitad_alto, -1.0, 1.0)
	var rapidez: float = minf(velocidad.length() * 1.07, size.x * 1.25)
	velocidad = Vector2(sentido, impacto * 0.85).normalized() * rapidez


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
		mensaje = "ESPACIO O CLIC PARA SACAR"
	_reiniciar_pelota()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var margen: float = size.x * 0.045
	var ancho: float = size.x * 0.017
	var alto: float = size.y * 0.24
	var radio: float = size.y * 0.021

	# Fondo, marco interior y línea central punteada.
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), LINEAS, false, 2.0)
	var y: float = size.y * 0.035
	while y < size.y * 0.97:
		draw_line(Vector2(size.x * 0.5, y), Vector2(size.x * 0.5, y + size.y * 0.04), LINEAS, 3.0)
		y += size.y * 0.085

	# Paletas y pelota.
	draw_rect(Rect2(margen, jugador_y - alto * 0.5, ancho, alto), BLANCO)
	draw_rect(Rect2(size.x - margen - ancho, cpu_y - alto * 0.5, ancho, alto), BLANCO)
	draw_circle(pelota, radio, BLANCO)

	# Marcador.
	var tam_puntos: int = maxi(20, int(size.y * 0.12))
	_texto_centrado(str(puntos_jugador), size.x * 0.35, size.y * 0.18, tam_puntos, BLANCO)
	_texto_centrado(str(puntos_cpu), size.x * 0.65, size.y * 0.18, tam_puntos, BLANCO)

	if not jugando:
		var tam_mensaje: int = maxi(13, int(size.y * 0.036))
		_texto_centrado(mensaje, size.x * 0.5, size.y * 0.73, tam_mensaje, BLANCO)


func _texto_centrado(contenido: String, centro_x: float, y: float, tam: int, color: Color) -> void:
	var ancho_texto: float = fuente.get_string_size(contenido, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(fuente, Vector2(centro_x - ancho_texto * 0.5, y), contenido, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
