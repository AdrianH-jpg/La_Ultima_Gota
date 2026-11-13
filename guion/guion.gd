extends Node
## Autoload "Guion" (después de DialogueManager y Climate).
## Muestra personajes (AnimatedSprite2D), textos en pantalla y botones globales de Volver / Saltar.

const PERSONAJES_JSON := "res://guion/personajes.json"
const ESCENAS_DIR := "res://scenes/"
const POS_X := {"izquierda": 0.2, "centro": 0.5, "derecha": 0.8}

var _cfg := {"personajes": {}, "animaciones": {}}
var _capa: CanvasLayer          # personajes (layer 5)
var _capa_txt: CanvasLayer      # textos en pantalla (layer 50)
var _capa_ui: CanvasLayer       # botones UI (layer 110)
var _label: Label
var _btn_volver: Button
var _btn_skip: Button
var _btn_ff: Button
var _activos := {}              # nombre -> Node2D
var _tween_txt: Tween

var _historial: Array[String] = []
var _escena_actual: String = ""
var _volviendo: bool = false


func _ready() -> void:
	if FileAccess.file_exists(PERSONAJES_JSON):
		var j = JSON.parse_string(FileAccess.get_file_as_string(PERSONAJES_JSON))
		if j is Dictionary:
			_cfg = j

	_capa = CanvasLayer.new()
	_capa.layer = 5
	add_child(_capa)

	_capa_txt = CanvasLayer.new()
	_capa_txt.layer = 50
	add_child(_capa_txt)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 36)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_txt.add_child(_label)

	_capa_ui = CanvasLayer.new()
	_capa_ui.layer = 110
	add_child(_capa_ui)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(24, 24)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	_capa_ui.add_child(hbox)

	_btn_volver = Button.new()
	_btn_volver.text = " ← Volver "
	_btn_volver.focus_mode = Control.FOCUS_NONE
	_btn_volver.add_theme_font_size_override("font_size", 18)
	_btn_volver.visible = false
	_btn_volver.pressed.connect(volver)
	hbox.add_child(_btn_volver)

	_btn_skip = Button.new()
	_btn_skip.text = " Saltar Escena ⏭ "
	_btn_skip.focus_mode = Control.FOCUS_NONE
	_btn_skip.add_theme_font_size_override("font_size", 18)
	_btn_skip.visible = false
	_btn_skip.pressed.connect(saltar_escena)
	hbox.add_child(_btn_skip)

	_btn_ff = Button.new()
	_btn_ff.text = " ⏩ x1 "
	_btn_ff.toggle_mode = true
	_btn_ff.focus_mode = Control.FOCUS_NONE
	_btn_ff.add_theme_font_size_override("font_size", 18)
	_btn_ff.visible = false
	_btn_ff.toggled.connect(_on_ff_toggled)
	hbox.add_child(_btn_ff)


func mostrar(nombre: String, anim: String = "") -> void:
	var quienes := nombre.split(" y ") if nombre.contains(" y ") else PackedStringArray([nombre])
	for n in quienes:
		_mostrar_uno(n.strip_edges(), anim)
	
	for k in _activos:
		var target_color := Color.WHITE if k in quienes else Color(0.65, 0.65, 0.65)
		var t := create_tween()
		t.tween_property(_activos[k], "modulate", target_color, 0.15)


func _mostrar_uno(nombre: String, anim: String) -> void:
	var info: Dictionary = _cfg["personajes"].get(nombre, {})
	if info.is_empty() or str(info.get("escena", "")) == "":
		return
		
	if not _activos.has(nombre):
		var ruta_escena: String = info["escena"]
		var ps = load(ruta_escena) if ResourceLoader.exists(ruta_escena) else null
		if ps == null:
			push_warning("Guion: falta la escena del personaje " + ruta_escena)
			return
			
		var n: Node2D = ps.instantiate()
		var vp := get_viewport().get_visible_rect().size
		var pos_key: String = str(info.get("posicion", "centro")).to_lower()
		var factor_x: float = POS_X.get(pos_key, 0.5)
		var offset_y: float = float(info.get("offset_y", 400.0))
		
		n.position = Vector2(vp.x * factor_x, vp.y - offset_y)
		n.scale = Vector2.ONE * float(info.get("escala", 1.0))
		n.modulate.a = 0.0
		_capa.add_child(n)
		_activos[nombre] = n
		
		var t := create_tween()
		t.tween_property(n, "modulate:a", 1.0, 0.25)

	if anim == "":
		return
		
	var sprite := _buscar_sprite(_activos[nombre])
	if sprite == null:
		return
		
	var real: String = _cfg["animaciones"].get(nombre + "|" + anim, anim)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(real):
		sprite.play(real)
	else:
		push_warning("Guion: %s no tiene la animación '%s'" % [nombre, real])


func _buscar_sprite(n: Node) -> AnimatedSprite2D:
	if n is AnimatedSprite2D:
		return n
	for c in n.get_children():
		var r := _buscar_sprite(c)
		if r:
			return r
	return null


func ocultar(nombre: String) -> void:
	if _activos.has(nombre):
		var nodo: Node2D = _activos[nombre]
		_activos.erase(nombre)
		var t := create_tween()
		t.tween_property(nodo, "modulate:a", 0.0, 0.2)
		t.tween_callback(nodo.queue_free)


func limpiar() -> void:
	if _tween_txt and _tween_txt.is_valid():
		_tween_txt.kill()
	_label.modulate.a = 0.0
	for k in _activos:
		if is_instance_valid(_activos[k]):
			_activos[k].queue_free()
	_activos.clear()


func pantalla(texto: String, cursiva: bool = false) -> void:
	if _tween_txt and _tween_txt.is_valid():
		_tween_txt.kill()
		
	_label.text = texto
	if cursiva:
		_label.add_theme_constant_override("outline_size", 2)
	else:
		_label.remove_theme_constant_override("outline_size")
		
	_tween_txt = create_tween()
	_tween_txt.tween_property(_label, "modulate:a", 1.0, 0.8)
	_tween_txt.tween_interval(clampf(texto.length() * 0.05, 2.0, 7.0))
	_tween_txt.tween_property(_label, "modulate:a", 0.0, 0.8)
	await _tween_txt.finished


func ir_a(escena: String) -> void:
	await get_tree().process_frame
	limpiar()
	var ruta := escena if escena.begins_with("res://") else ESCENAS_DIR + escena + ".tscn"
	get_tree().change_scene_to_file.call_deferred(ruta)


# ---- Sistema de Historial, Volver y Skip ----

func registrar_escena(ruta: String, tiene_siguiente: bool = true) -> void:
	if ruta == "":
		return
	if _volviendo:
		_volviendo = false
		_escena_actual = ruta
	else:
		if _escena_actual != "" and _escena_actual != ruta:
			_historial.append(_escena_actual)
		_escena_actual = ruta
	
	_btn_volver.visible = not _historial.is_empty()
	_btn_volver.disabled = false
	
	_btn_skip.visible = true
	_btn_skip.disabled = false
	_btn_skip.text = " Saltar Escena ⏭ " if tiene_siguiente else " Saltar ⏭ "
	_btn_ff.visible = true


func volver() -> void:
	if _historial.is_empty():
		return
	_btn_volver.disabled = true
	_btn_skip.disabled = true
	_volviendo = true
	var anterior: String = _historial.pop_back()
	
	_cerrar_globos_dialogo()
	limpiar()
	get_tree().change_scene_to_file.call_deferred(anterior)


func saltar_escena() -> void:
	var escena := get_tree().current_scene
	if not is_instance_valid(escena):
		return
		
	var sig: String = str(escena.get("siguiente_escena")) if "siguiente_escena" in escena else ""
	if sig != "":
		_btn_skip.disabled = true
		_btn_volver.disabled = true
		_cerrar_globos_dialogo()
		limpiar()
		get_tree().change_scene_to_file.call_deferred(sig)
	else:
		var destino_auto := _buscar_primer_ir_a_en_escena(escena)
		if destino_auto != "":
			_btn_skip.disabled = true
			_btn_volver.disabled = true
			_cerrar_globos_dialogo()
			ir_a(destino_auto)


func _buscar_primer_ir_a_en_escena(escena: Node) -> String:
	var arch: String = str(escena.get("archivo")) if "archivo" in escena else ""
	if arch == "" and escena.scene_file_path != "":
		arch = escena.scene_file_path.get_file().get_basename()
	if arch == "":
		return ""
	var ruta_dlg := "res://dialogue/%s.dialogue" % arch
	if not FileAccess.file_exists(ruta_dlg):
		return ""
	var contenido := FileAccess.get_file_as_string(ruta_dlg)
	var regex := RegEx.new()
	regex.compile("Guion\\.ir_a\\([\"']([^\"']+)[\"']\\)")
	var m := regex.search(contenido)
	if m:
		return m.get_string(1)
	return ""


func _on_ff_toggled(activo: bool) -> void:
	Engine.time_scale = 5.0 if activo else 1.0
	_btn_ff.text = " ⏩ x5 " if activo else " ⏩ x1 "


func _cerrar_globos_dialogo() -> void:
	for c in get_tree().root.get_children():
		if c != self and c != get_tree().current_scene:
			if "Balloon" in c.name or c.is_in_group("dialogue_balloon"):
				c.queue_free()
