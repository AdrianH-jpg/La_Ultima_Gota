extends VideoStreamPlayer
## Nodos hijos (hijos DIRECTOS de este VideoStreamPlayer, con estos nombres exactos
## y en este orden, para que se dibujen uno encima del otro):
##
## IntroVideo (VideoStreamPlayer, este script)
## ├── AudioStreamPlayer  (audio del logo, opcional)
## ├── FondoNegro         (ColorRect, color negro, Full Rect, Mouse Filter = Ignore)
## ├── TextoPresenta      (Label, Full Rect, alineación horizontal y vertical = Center,
## │                       texto = "Outer Space Games INC presenta")
## └── SFXLluvia          (AudioStreamPlayer, stream = lluvia)

# Ruta de tu menú principal
const ACTO_1 = "res://scenes/escena_uno.tscn"

const FADE_TIME := 0.6      # duración del fundido del texto
const TEXTO_ESPERA := 1.5   # segundos que el texto queda visible


@onready var fondo_negro: ColorRect = get_node_or_null("FondoNegro")
@onready var texto_presenta: Label = get_node_or_null("TextoPresenta")
@onready var sfx_lluvia: AudioStreamPlayer = get_node_or_null("SFXLluvia")

var _saltando := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)

	if fondo_negro == null or texto_presenta == null or sfx_lluvia == null:
		push_error("Faltan nodos hijos: FondoNegro, TextoPresenta o SFXLluvia. Revisá los nombres.")

	# Estado inicial: todo invisible hasta que termine el video
	if fondo_negro:
		fondo_negro.modulate.a = 0.0
	if texto_presenta:
		texto_presenta.modulate.a = 0.0

	loop = false  # que el video no se repita, así sí se emite "finished"
	finished.connect(_on_video_finished)
	play()

	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.play()


func _on_video_finished() -> void:
	if _saltando:
		return

	
	# Tapa el video con negro y arranca la lluvia
	fondo_negro.modulate.a = 1.0
	if sfx_lluvia:
		sfx_lluvia.play()

	# Aparece el texto "Outer Space Games INC presenta"
	var t_in := create_tween()
	t_in.tween_property(texto_presenta, "modulate:a", 1.0, FADE_TIME)
	await t_in.finished
	if not is_inside_tree() or _saltando:
		return
	
	# Se mantiene 1.5 segundos
	await get_tree().create_timer(TEXTO_ESPERA).timeout
	if not is_inside_tree() or _saltando:
		return

	# Se desvanece y pasa a la siguiente escena
	var t_out := create_tween()
	t_out.tween_property(texto_presenta, "modulate:a", 0.0, FADE_TIME)
	await t_out.finished
	if not is_inside_tree() or _saltando:
		return
	
	
	# Aparece el texto "la ultima gota"
	var e_in := create_tween()
	texto_presenta.text = "LA ÚLTIMA GOTA"
	e_in.tween_property(texto_presenta, "modulate:a", 1.0, FADE_TIME)
	await e_in.finished
	if not is_inside_tree() or _saltando:
		return

	# Se mantiene 1.5 segundos
	await get_tree().create_timer(2).timeout
	if not is_inside_tree() or _saltando:
		return

	# Se desvanece y pasa a la siguiente escena
	var e_out := create_tween()
	e_out.tween_property(texto_presenta, "modulate:a", 0.0, FADE_TIME)
	await e_out.finished
	if not is_inside_tree() or _saltando:
		return

	_ir_al_juego()


func _ir_al_juego() -> void:
	var error = get_tree().change_scene_to_file(ACTO_1)
	if error != OK:
		print("Error al cambiar de escena: Comprueba que la ruta del menú sea correcta.")


# Saltar intro con Espacio / Enter
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _saltando:
		_saltando = true
		_ir_al_juego()
