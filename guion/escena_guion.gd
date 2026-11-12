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

@onready var fade_rect: ColorRect = get_node_or_null("CanvasLayer/FadeRect")


func _ready() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam and camara_zoom_inicial > 0.0:
		cam.position = camara_pos_inicial
		cam.zoom = Vector2.ONE * camara_zoom_inicial
	if fade_rect == null: push_warning("escena_guion: falta CanvasLayer/FadeRect")
	if usar_fade and fade_rect:
		fade_rect.modulate.a = 1.0
		await _fade(0.0)
	var res := load("res://dialogue/%s.dialogue" % archivo)
	for t in titulos:
		DialogueManager.show_dialogue_balloon(res, t, [self])
		await DialogueManager.dialogue_ended
		if get_tree().current_scene != self: return   # una opción ya cambió de escena
	Guion.limpiar()
	if usar_fade and fade_rect: await _fade(1.0)
	if siguiente_escena != "": get_tree().change_scene_to_file(siguiente_escena)


func _fade(a: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", a, 1.0)
	await t.finished


# ---- Efectos para usar desde la planilla (tipo "comando") ----
# Nodos opcionales: CanvasLayer/FlashRect (ColorRect blanco, Full Rect, Mouse Filter Ignore, alpha 0)
@onready var flash_rect: ColorRect = get_node_or_null("CanvasLayer/FlashRect")

## Ejemplo de fila: comando = rayo()
func rayo() -> void:
	if flash_rect == null:
		push_warning("escena_guion: falta CanvasLayer/FlashRect"); return
	for a in [1.0, 0.0, 0.8, 0.0]:
		var t := create_tween()
		t.tween_property(flash_rect, "modulate:a", a, 0.06 if a > 0.0 else 0.12)
		await t.finished


## Ejemplo: comando = parpadeo(3)   (usa FadeRect: negro-claro-negro)
func parpadeo(veces: int = 3) -> void:
	if fade_rect == null: return
	for i in veces:
		var t := create_tween()
		t.tween_property(fade_rect, "modulate:a", 0.0, 0.15)
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
		t.tween_property(fade_rect, "modulate:a", 0.0, 0.3)
		await t.finished


## Ejemplo: comando = fade_negro()  /  fade_claro()
func fade_negro() -> void:
	if fade_rect: await _fade(1.0)

func fade_claro() -> void:
	if fade_rect: await _fade(0.0)


## Muestra un solo fondo entre los hijos Sprite2D que le pases. Ejemplo: comando = fondo("FondoPesadilla")
func fondo(nombre: String) -> void:
	var hallado := false
	for c in get_children():
		if c is Sprite2D and c.name.begins_with("Fondo"):
			c.visible = (c.name == nombre)
			hallado = hallado or c.name == nombre
	if not hallado: push_warning("escena_guion: no hay un Sprite2D hijo directo llamado " + nombre)


## Ejemplo: comando = camara(0, 0, 1, 4)  -> mueve la cámara a (0,0) con zoom 1 en 4 segundos y espera.
func camara(x: float, y: float, zoom: float, seg: float) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		push_warning("escena_guion: falta el nodo Camera2D"); return
	var t := create_tween().set_parallel(true)
	t.tween_property(cam, "position", Vector2(x, y), seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(cam, "zoom", Vector2.ONE * zoom, seg).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
