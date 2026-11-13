extends Node2D
## Script único para TODAS las escenas. Pegalo en el nodo raíz y completá el Inspector:
##   archivo  -> "escena_6"  (res://dialogue/escena_6.dialogue)
##   titulos  -> ["pizarron"]  (se reproducen en orden)
##   siguiente_escena -> escena a la que pasa al terminar (vacío si las opciones ya hacen Guion.ir_a)
## Nodo opcional: CanvasLayer/FadeRect (ColorRect negro) para el fade in/out.

@export var archivo: String = ""
@export var titulos: Array[String] = ["start"]
@export_file("*.tscn") var siguiente_escena: String = ""
@export var usar_fade: bool = true
## Cámara al empezar la escena (para el zoom out). Ej: pos (-200, 200), zoom 2. Dejá zoom 0 para no tocarla.
@export var camara_pos_inicial: Vector2 = Vector2.ZERO
@export var camara_zoom_inicial: float = 0.0

@onready var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer")
@onready var fade_rect: ColorRect = get_node_or_null("CanvasLayer/FadeRect")
@onready var flash_rect: ColorRect = get_node_or_null("CanvasLayer/FlashRect")


func _ready() -> void:
	if scene_file_path != "":
		Guion.registrar_escena(scene_file_path, siguiente_escena != "")

	if fade_rect:
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if flash_rect:
		flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if canvas_layer and canvas_layer.layer < 10:
		canvas_layer.layer = 20

	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam and camara_zoom_inicial > 0.0:
		cam.position = camara_pos_inicial
		cam.zoom = Vector2.ONE * camara_zoom_inicial

	if fade_rect == null:
		push_warning("escena_guion: falta CanvasLayer/FadeRect")
	elif usar_fade:
		fade_rect.modulate.a = 1.0
		await _fade(0.0)

	# Si 'archivo' quedó vacío en el Inspector, usa el nombre de la escena .tscn
	var nombre_dlg := archivo.strip_edges()
	if nombre_dlg == "" and scene_file_path != "":
		nombre_dlg = scene_file_path.get_file().get_basename()

	var ruta_dialogo := "res://dialogue/%s.dialogue" % nombre_dlg
	if nombre_dlg != "" and ResourceLoader.exists(ruta_dialogo):
		var res := load(ruta_dialogo)
		var disponibles := _obtener_titulos_archivo(ruta_dialogo)
		
		# Usa los títulos del Inspector que existan en el archivo;
		# si ninguno coincide (ej. quedó "start" por defecto), usa el primer "~ titulo" del archivo.
		var lista_titulos: Array[String] = []
		for t in titulos:
			if disponibles.is_empty() or t in disponibles:
				lista_titulos.append(t)
		if lista_titulos.is_empty() and not disponibles.is_empty():
			lista_titulos.append(disponibles[0])

		for t in lista_titulos:
			if not is_instance_valid(self) or not is_inside_tree() or get_tree().current_scene != self:
				return
			DialogueManager.show_dialogue_balloon(res, t, [self])
			await DialogueManager.dialogue_ended
			if not is_instance_valid(self) or not is_inside_tree() or get_tree().current_scene != self:
				return
	else:
		push_warning("escena_guion: no se encontró diálogo '" + ruta_dialogo + "'. Revisá 'archivo' en el Inspector.")

	Guion.limpiar()
	if usar_fade and fade_rect:
		await _fade(1.0)
	if siguiente_escena != "":
		get_tree().change_scene_to_file.call_deferred(siguiente_escena)


## Lee las líneas "~ titulo" directamente del archivo .dialogue
func _obtener_titulos_archivo(ruta: String) -> Array[String]:
	var resultado: Array[String] = []
	if not FileAccess.file_exists(ruta):
		return resultado
	var texto := FileAccess.get_file_as_string(ruta)
	for linea in texto.split("\n"):
		var limpia := linea.strip_edges()
		if limpia.begins_with("~"):
			var t := limpia.substr(1).strip_edges()
			if t != "" and not t in resultado:
				resultado.append(t)
	return resultado


func _fade(a: float, duracion: float = 1.0) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", a, duracion)
	await t.finished


# ---- Efectos para usar desde la planilla (tipo "comando") ----

func rayo() -> void:
	if flash_rect == null:
		push_warning("escena_guion: falta CanvasLayer/FlashRect")
		return
	for a in [1.0, 0.0, 0.8, 0.0]:
		var t := create_tween()
		t.tween_property(flash_rect, "modulate:a", a, 0.06 if a > 0.0 else 0.12)
		await t.finished


func parpadeo(veces: int = 3) -> void:
	if fade_rect == null:
		return
	fade_rect.modulate.a = 1.0
	for i in veces:
		var t := create_tween()
		t.tween_property(fade_rect, "modulate:a", 0.0, 0.18)
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.25)
		await t.finished
	await _fade(0.0, 0.35)


func fade_negro(seg: float = 1.0) -> void:
	if fade_rect:
		await _fade(1.0, seg)


func fade_claro(seg: float = 1.0) -> void:
	if fade_rect:
		await _fade(0.0, seg)


func fondo(nombre: String) -> void:
	var hallado := false
	for c in get_children():
		if c is Sprite2D and c.name.begins_with("Fondo"):
			var es_este := (c.name == nombre)
			c.visible = es_este
			if es_este:
				hallado = true
	if not hallado:
		push_warning("escena_guion: no hay un Sprite2D hijo directo llamado " + nombre)


func camara(x: float, y: float, zoom: float, seg: float) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		push_warning("escena_guion: falta el nodo Camera2D")
		return
	var t := create_tween().set_parallel(true)
	t.tween_property(cam, "position", Vector2(x, y), seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(cam, "zoom", Vector2.ONE * zoom, seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	
## Ejemplo: comando = sonido("SFXTrueno")        -> reproduce ese nodo
##          comando = sonido("SFXLluvia", false)  -> lo corta
func sonido(nodo: String, play: bool = true) -> void:
	var p := get_node_or_null(nodo) as AudioStreamPlayer
	if p == null:
		push_warning("escena_guion: no hay un AudioStreamPlayer llamado " + nodo); return
	if play: p.play()
	else: p.stop()
