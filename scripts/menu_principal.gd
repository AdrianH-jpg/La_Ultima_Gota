extends Control

@export var tiempo_inicial: float = 1.35   # segundos en negro antes del rayo
@export var retraso_trueno: float = 0.25   # el trueno suena un poco después del rayo
 
@onready var oscuridad: ColorRect = $CapaEfectos/Oscuridad
@onready var destello: ColorRect = $CapaEfectos/Destello

@onready var bus_index = AudioServer.get_bus_index("Music")
@onready var Hover_SFX = $HoverSFX
@onready var Play_SFX = $PlaySFX
@onready var music = $MenuSFX
func _ready():
	# Estado inicial: todo negro, sin destello, y sin poder clickear los botones
	oscuridad.color = Color.BLACK
	oscuridad.modulate.a = 1.0
	oscuridad.mouse_filter = Control.MOUSE_FILTER_STOP
 
	destello.color = Color.WHITE
	destello.modulate.a = 0.0
	destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
 
	await get_tree().create_timer(tiempo_inicial).timeout
	if not is_inside_tree():
		return
	_relampago()
	
	
	music.stream.loop = true   # Por si no lo pusiste en el import
	music.play()
	for boton in $MenuBox.get_children():
		# Verificamos que el elemento sea realmente un botón (por si acaso pusiste un Label ahí adentro)
		if boton is Button:
			# Conectamos la señal a nuestra nueva función general.
			# Usamos .bind(boton) para enviarle a la función exactamente QUÉ botón estamos tocando.
			boton.mouse_entered.connect(_al_hacer_hover.bind(boton))
			boton.mouse_exited.connect(_al_quitar_hover.bind(boton))
func _al_hacer_hover(boton_tocado: Button) -> void:
	Hover_SFX.play() # ¡Suena el hover!
	
	boton_tocado.pivot_offset = boton_tocado.size / 2.0
	var tween = create_tween()
	tween.tween_property(boton_tocado, "scale", Vector2(1.2, 1.2), 0.1)

func _al_quitar_hover(boton_tocado: Button) -> void:
	var tween = create_tween()
	tween.tween_property(boton_tocado, "scale", Vector2(1.0, 1.0), 0.1)



func _on_play_mouse_entered() -> void:
# 1. Guardamos el botón en una variable para no escribir la ruta larga todo el tiempo
	var boton = $MenuBox/Play
	
	# 2. ¡EL TRUCO! Calculamos el centro exacto del botón por código
	boton.pivot_offset = boton.size / 2.0
	
	# 3. Hacemos el zoom
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.2, 1.2), 0.1)


func _on_play_mouse_exited() -> void:
	var boton = $MenuBox/Play
	
	# Devolvemos el botón a su tamaño original (1.0)
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.0, 1.0), 0.1)
	
	


func _on_h_slider_value_changed(value: float) -> void:
	# Si el slider está al mínimo, silenciamos el bus por completo
	if value <= -39:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, value)
	


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")
	


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")


func _on_play_pressed() -> void:
	 # aca a la primer escena del juego
	$PlaySFX.play()
	get_tree().change_scene_to_file("res://scenes/opening_sequence.gd.tscn")


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()


func _on_video_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/video.tscn")
	
	
func _relampago() -> void:
	var t := create_tween()
 
	# 1) Primer golpe de luz, muy rápido
	t.tween_property(destello, "modulate:a", 1.0, 0.04)
 
	# 2) En el pico de luz se quita la oscuridad: aparece la imagen
	t.tween_callback(_revelar_imagen)
 
	# 3) Baja rápido y vuelve a subir: el segundo parpadeo del rayo
	t.tween_property(destello, "modulate:a", 0.15, 0.08)
	t.tween_property(destello, "modulate:a", 0.85, 0.05)
 
	# 4) Se apaga suavemente
	t.tween_property(destello, "modulate:a", 0.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 
 
func _revelar_imagen() -> void:
	oscuridad.modulate.a = 0.0
	oscuridad.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ya se pueden usar los botones
 
	
