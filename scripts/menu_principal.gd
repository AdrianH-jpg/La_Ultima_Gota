extends Control


@onready var bus_index = AudioServer.get_bus_index("Music")
@onready var Hover_SFX = $HoverSFX
@onready var music = $MenuSFX
func _ready():
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
 
	
