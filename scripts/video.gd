extends Control
@onready var ojo = $Ojo 
@onready var Hover_SFX = $HoverSFX
@onready var entorno = $WorldEnvironment
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ojo.pivot_offset = ojo.size / 2.0 
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# con el metodo get_local_mouse_position tomamos las coordenadas del mouse
	var posicion_mouse = get_local_mouse_position()
	
	# Calculamos el centro del ojo de la vaca
	var centro_ojo = ojo.position + ojo.pivot_offset
	
	# 3. destino menos el origen, como una flhecita imaginaria ( vector=) asi el ojo sigue al mouse
	var direccion = posicion_mouse - centro_ojo
	
	# le da el angulo al vector o la direccion 
	ojo.rotation = direccion.angle()


func _on_check_fullscreen_toggled(toggled_on: bool) -> void:
	# toggled_on es 'true' si el interruptor está activado, 'false' si está desactivado
	if toggled_on:
		# Pone el juego en pantalla completa
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Devuelve el juego a modo ventana normal
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_BrightSlider_value_changed(value: float) -> void:
	# Aplica el número del slider directamente al brillo del juego
	entorno.environment.adjustment_brightness = value

func _on_ContrastSlider_value_changed(value: float) -> void:
	# Aplica el número del slider directamente al contraste del juego
	entorno.environment.adjustment_contrast = value
	


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")
