extends Node2D
## ESCENA MAESTRA: reproduce TODO el juego leyendo el Excel (vía res://guion/escenas.json).
## Para qué sirve cada nodo hijo:
##   Fondo (Sprite2D)         -> imagen de fondo actual (la cambia el comando fondo("id"))
##   Camera2D                 -> zoom / movimiento (comando camara(...))
##   CanvasLayer/FadeRect     -> negro para fades y parpadeos
##   CanvasLayer/FlashRect    -> blanco para rayos
## Los comandos que podés escribir en la columna "comando" del Excel están al final.

@export var escena_inicial: String = "escena_1"
## Escena a cargar cuando termina el juego (p. ej. el menú principal). Vacío = queda en negro.
@export_file("*.tscn") var al_terminar: String = ""
@export var fade_seg: float = 1.0

const ESCENAS_JSON := "res://guion/escenas.json"
const FONDOS_JSON := "res://guion/fondos.json"
const FONDOS_DIR := "res://fondos/"

@onready var fondo_sprite: Sprite2D = $Fondo
@onready var camara_nodo: Camera2D = $Camera2D
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var flash_rect: ColorRect = $CanvasLayer/FlashRect

# se emite cuando termina (o se corta) el diálogo de un título
signal _terminado
# se emite cuando el minijuego termina (o lo cortan)
signal _mini_fin

# escena (archivo) que se está jugando ahora
var _actual := ""
# capa del minijuego que está abierto (null si no hay ninguno)
var _mini: Node = null
# true si el jugador usó Volver o Saltar
var _interrumpido := false
# datos de escenas.json: el orden y los títulos de cada escena
var _escenas := {"orden": [], "titulos": {}}
# datos de fondos.json
var _fondos := {}
# si tiene algo, la próxima escena es esta en vez de la siguiente de la lista
var _salto := ""
# true cuando hay que terminar el juego
var _fin := false


func _ready() -> void:
	# fondo negro por si algo no cubre la pantalla
	RenderingServer.set_default_clear_color(Color.BLACK)
	_escenas = _leer_json(ESCENAS_JSON, _escenas)
	_fondos = _leer_json(FONDOS_JSON, {})
	# así el autoload Guion sabe que existe la escena maestra
	Guion.juego = self
	# cuando termina el diálogo avisamos con nuestra señal
	DialogueManager.dialogue_ended.connect(func(_r): _terminado.emit())
	fade_rect.modulate.a = 1.0
	flash_rect.modulate.a = 0.0
	# arranca el juego; esto dura hasta el final
	await _jugar(escena_inicial)
	if al_terminar != "":
		get_tree().change_scene_to_file(al_terminar)


func _exit_tree() -> void:
	# al salir soltamos el enlace y escondemos los botones
	if Guion.juego == self:
		Guion.juego = null
		Guion.ocultar_ui()


func _leer_json(ruta: String, defecto) -> Variant:
	if not FileAccess.file_exists(ruta): return defecto
	var j = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return j if j != null else defecto


# ------------------------------------------------------------------ flujo
# va encadenando escenas hasta que no queda ninguna
func _jugar(archivo: String) -> void:
	while archivo != "":
		# cada escena devuelve cuál sigue
		archivo = await _correr_escena(archivo)
	await _fade(1.0)
	Guion.ocultar_ui()


# juega una escena completa y devuelve el nombre de la siguiente
func _correr_escena(archivo: String) -> String:
	_salto = ""
	_fin = false
	_interrumpido = false
	_actual = archivo
	Guion.limpiar()
	# la anota en el historial para el botón Volver
	Guion.registrar_escena(archivo, true)
	# cada escena arranca en negro y sin fondo; el comando fondo() lo pone
	fondo_sprite.texture = null
	camara_nodo.position = Vector2.ZERO
	camara_nodo.zoom = Vector2.ONE
	fade_rect.modulate.a = 1.0
	var ruta := "res://dialogue/%s.dialogue" % archivo
	if not ResourceLoader.exists(ruta):
		push_error("Juego: no existe " + ruta); return ""
	var res = load(ruta)
	# los títulos que no son ramas se juegan en orden
	for t in _escenas["titulos"].get(archivo, ["start"]):
		DialogueManager.show_dialogue_balloon(res, t, [self])
		# espera a que termine ese bloque de diálogo
		await _terminado
		# si hay que cortar, no seguimos con más títulos
		if _interrumpido or _salto != "" or _fin: break
	if not _interrumpido:
		await _fade(1.0)      # FADE OUT al terminar cada escena
	if _fin: return ""
	if _salto != "": return _salto
	# si nadie pidió otra cosa, sigue la próxima de la lista
	var orden: Array = _escenas["orden"]
	var i := orden.find(archivo)
	return orden[i + 1] if i >= 0 and i + 1 < orden.size() else ""


func saltar(archivo: String) -> void:   # lo llama Guion.ir_a()
	_salto = archivo


## Corta la escena actual ya (botones Volver / Saltar) y pasa a 'destino'.
func interrumpir(destino: String, terminar_juego: bool = false) -> void:
	# si había un minijuego abierto, lo cerramos
	if _mini:
		_mini.queue_free()
		_mini = null
		_mini_fin.emit()
	_interrumpido = true
	_salto = destino
	_fin = terminar_juego
	Guion._cerrar_globos_dialogo()
	Guion.limpiar()
	_terminado.emit()


## Botón "Saltar escena": va al primer Guion.ir_a de la escena, o a la siguiente; si es un final, termina.
func saltar_escena() -> void:
	var dest := ""
	var ruta := "res://dialogue/%s.dialogue" % _actual
	if FileAccess.file_exists(ruta):
		# busco el primer ir_a del diálogo para saber a dónde saltar
		var txt := FileAccess.get_file_as_string(ruta)
		var rx := RegEx.new()
		rx.compile("Guion\\.ir_a\\([\"']([^\"']+)[\"']\\)")
		var m := rx.search(txt)
		if m: dest = m.get_string(1)
		elif txt.contains("Guion.fin("):
			interrumpir("", true); return
	if dest == "":
		var orden: Array = _escenas["orden"]
		var i := orden.find(_actual)
		if i >= 0 and i + 1 < orden.size(): dest = orden[i + 1]
		else:
			interrumpir("", true); return
	interrumpir(dest)


func terminar() -> void:                # lo llama Guion.fin()
	_fin = true


## Si la pantalla está en negro la descubre (lo usa Guion al mostrar personajes).
func revelar() -> void:
	# solo hace algo si la pantalla está en negro
	if fade_rect.modulate.a > 0.99:
		var t := create_tween()
		t.tween_property(fade_rect, "modulate:a", 0.0, fade_seg)


# lleva el negro a esa opacidad y espera a que termine
func _fade(a: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", a, fade_seg)
	await t.finished


# ------------------------------------------------------------------ comandos para el Excel
## fondo("pileta")        -> cambia la imagen y, si la pantalla está en negro, la descubre
## fondo("pileta", false) -> cambia la imagen sin descubrir
## fondo("negro")         -> sin imagen
func fondo(id: String, mostrar: bool = true) -> void:
	# configuración del fondo en fondos.json (puede estar vacía)
	var cfg: Dictionary = _fondos.get(id, {})
	var ruta: String = cfg.get("imagen", "")
	# si el Excel no tiene ruta, busco res://fondos/<id>.png (o jpg, webp)
	if ruta == "" and id != "negro":
		for ext in ["png", "jpg", "jpeg", "webp"]:
			if ResourceLoader.exists("%s%s.%s" % [FONDOS_DIR, id, ext]):
				ruta = "%s%s.%s" % [FONDOS_DIR, id, ext]; break
	if ruta != "" and ResourceLoader.exists(ruta):
		var tex: Texture2D = load(ruta)
		fondo_sprite.texture = tex
		var vp := get_viewport_rect().size
		# si la imagen es más chica que la pantalla, la agranda para cubrirla
		var cubrir := maxf(vp.x / tex.get_width(), vp.y / tex.get_height())
		var esc := float(cfg.get("escala", 0.0))
		fondo_sprite.scale = Vector2.ONE * (esc if esc > 0.0 else maxf(1.0, cubrir))
	else:
		fondo_sprite.texture = null
		if id != "negro": push_warning("Juego: no encuentro la imagen del fondo '%s'" % id)
	# posición y zoom inicial de la cámara para este fondo
	if cfg.has("cam_zoom"):
		camara_nodo.zoom = Vector2.ONE * float(cfg["cam_zoom"])
		camara_nodo.position = Vector2(float(cfg.get("cam_x", 0)), float(cfg.get("cam_y", 0)))
	if mostrar: revelar()


## rayo()  -> destello blanco
func rayo() -> void:
	# dos destellos blancos seguidos
	for a in [1.0, 0.0, 0.8, 0.0]:
		var t := create_tween()
		t.tween_property(flash_rect, "modulate:a", a, 0.06 if a > 0.0 else 0.12)
		await t.finished


## parpadeo(3) -> la pantalla parpadea y queda en negro
func parpadeo(veces: int = 3) -> void:
	# en cada vuelta se abre un instante y vuelve a negro
	for i in veces:
		var t := create_tween()
		t.tween_property(fade_rect, "modulate:a", 0.0, 0.15)
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
		await t.finished


func fade_negro() -> void:
	await _fade(1.0)


func fade_claro() -> void:
	await _fade(0.0)


## camara(0, 0, 1, 4) -> mueve la cámara a (0,0) con zoom 1 en 4 s y espera
func camara(x: float, y: float, zoom: float, seg: float) -> void:
	# mueve la posición y el zoom al mismo tiempo
	var t := create_tween().set_parallel(true)
	t.tween_property(camara_nodo, "position", Vector2(x, y), seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camara_nodo, "zoom", Vector2.ONE * zoom, seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished


## minijuego("res://minijuegos/arcade.tscn")
## Abre esa escena encima de todo y el diálogo espera hasta que el minijuego termine.
## La escena del minijuego tiene que tener "signal terminado" y emitirlo cuando se acaba.
func minijuego(ruta: String) -> void:
	if not ResourceLoader.exists(ruta):
		push_warning("Juego: no existe el minijuego " + ruta)
		return
	# escondemos el globo de diálogo mientras se juega
	_ocultar_globos(true)
	# lo metemos en su propia capa, arriba del fade pero debajo de los botones
	var capa := CanvasLayer.new()
	capa.layer = 60
	add_child(capa)
	_mini = capa
	var nodo: Node = (load(ruta) as PackedScene).instantiate()
	capa.add_child(nodo)
	if nodo.has_signal("terminado"):
		nodo.connect("terminado", func(_a = null): _mini_fin.emit())
	else:
		push_warning("Juego: el minijuego no tiene 'signal terminado'; espero a que se cierre solo")
		nodo.tree_exited.connect(func(): _mini_fin.emit())
	await _mini_fin
	if is_instance_valid(capa):
		capa.queue_free()
	_mini = null
	_ocultar_globos(false)


# esconde o muestra el globo de diálogo (cuelga de esta escena)
func _ocultar_globos(ocultar: bool) -> void:
	for c in get_children():
		if "Balloon" in c.name or c.is_in_group("dialogue_balloon"):
			c.set("visible", not ocultar)
