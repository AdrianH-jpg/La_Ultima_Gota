extends Node
## Autoload "Guion" (después de DialogueManager y Climate).
## Muestra personajes (AnimatedSprite2D) y textos en pantalla según lo que diga el diálogo.

const PERSONAJES_JSON := "res://guion/personajes.json"
const ESCENAS_DIR := "res://scenes/"
const POS_X := {"izquierda": 0.2, "centro": 0.5, "derecha": 0.8}

var _cfg := {"personajes": {}, "animaciones": {}}
var _capa: CanvasLayer          # personajes (layer 5)
var _capa_txt: CanvasLayer      # textos en pantalla (layer 50)
var _label: Label
var _activos := {}              # nombre -> Node2D


func _ready() -> void:
	if FileAccess.file_exists(PERSONAJES_JSON):
		var j = JSON.parse_string(FileAccess.get_file_as_string(PERSONAJES_JSON))
		if j is Dictionary: _cfg = j
	_capa = CanvasLayer.new(); _capa.layer = 5; add_child(_capa)
	_capa_txt = CanvasLayer.new(); _capa_txt.layer = 50; add_child(_capa_txt)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 36)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_txt.add_child(_label)


## do Guion.mostrar("Eva", "triste")  -> aparece (si no estaba) y reproduce la animación.
func mostrar(nombre: String, anim: String = "") -> void:
	var quienes := nombre.split(" y ") if nombre.contains(" y ") else PackedStringArray([nombre])
	for n in quienes:
		_mostrar_uno(n, anim)
	for k in _activos:   # resalta a quien habla
		_activos[k].modulate = Color.WHITE if k in quienes else Color(0.65, 0.65, 0.65)


func _mostrar_uno(nombre: String, anim: String) -> void:
	var info: Dictionary = _cfg["personajes"].get(nombre, {})
	if info.is_empty() or str(info.get("escena", "")) == "": return   # Narrador u otro sin sprite
	if not _activos.has(nombre):
		var ps = load(info["escena"]) if ResourceLoader.exists(info["escena"]) else null
		if ps == null:
			push_warning("Guion: falta la escena del personaje " + info["escena"]); return
		var n: Node2D = ps.instantiate()
		var vp := get_viewport().get_visible_rect().size 
		n.position = Vector2(vp.x * POS_X.get(info.get("posicion", "centro"), 2), (vp.y - 400))
		n.scale = Vector2.ONE * float(info.get("escala", 1.0))
		_capa.add_child(n)
		_activos[nombre] = n
	if anim == "": return
	var sprite := _buscar_sprite(_activos[nombre])
	if sprite == null: return
	var real: String = _cfg["animaciones"].get(nombre + "|" + anim, anim)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(real):
		sprite.play(real)
	else:
		push_warning("Guion: %s no tiene la animación '%s'" % [nombre, real])


func _buscar_sprite(n: Node) -> AnimatedSprite2D:
	if n is AnimatedSprite2D: return n
	for c in n.get_children():
		var r := _buscar_sprite(c)
		if r: return r
	return null


func ocultar(nombre: String) -> void:
	if _activos.has(nombre):
		_activos[nombre].queue_free()
		_activos.erase(nombre)


func limpiar() -> void:
	for k in _activos: _activos[k].queue_free()
	_activos.clear()


## do Guion.pantalla("Domingo - 28 de abril de 1968")
func pantalla(texto: String, cursiva: bool = false) -> void:
	_label.text = texto
	var t := create_tween()
	t.tween_property(_label, "modulate:a", 1.0, 0.8)
	t.tween_interval(clampf(texto.length() * 0.05, 2.0, 7.0))
	t.tween_property(_label, "modulate:a", 0.0, 0.8)
	await t.finished


## do Guion.ir_a("escena_16a") -> fade y cambia a res://scenes/escena_16a.tscn
func ir_a(escena: String) -> void:
	await get_tree().process_frame
	limpiar()
	var ruta := escena if escena.begins_with("res://") else ESCENAS_DIR + escena + ".tscn"
	get_tree().change_scene_to_file.call_deferred(ruta)
