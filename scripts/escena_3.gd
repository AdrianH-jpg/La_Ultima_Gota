extends Node2D
## ESCENA 3 - guion 7 y 8: fecha sobre negro -> cocina (madrugada)
## AQUÍ APARECE POR PRIMERA VEZ LA BARRA DE CLIMA: Eva arranca en desesperanza (15).
##
## Árbol de nodos esperado:
## Escena3 (Node2D, este script)
## ├── FondoCocina   (Sprite2D: Eva con mate, pava, botella de whisky, reloj 5:30)
## ├── SFXReloj      (AudioStreamPlayer, agujas del reloj, loop)
## └── CanvasLayer   (Layer = 50, para quedar POR ENCIMA del efecto del clima)
##     ├── FadeRect       (ColorRect negro, Full Rect, Mouse Filter = Ignore, Modulate alpha = 1)
##     └── Sobreimpreso   (Label, Full Rect, centrado, Modulate alpha = 0)
## (Sobreimpreso va DESPUÉS de FadeRect en el árbol. SFXGallo ya no se usa: podés borrarlo.)

@export var dialogue_resource: DialogueResource = preload("res://dialogue/scenes_0/escena_03a_titulo.dialogue")
@export_file("*.tscn") var next_scene_path: String = "res://scenes/escena_4.tscn"

@export var clima_inicial := 15.0   # desesperanza: casi blanco y negro, frío

@onready var sfx_reloj: AudioStreamPlayer = $SFXReloj
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var sobreimpreso: Label = $CanvasLayer/Sobreimpreso


func _ready() -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	sobreimpreso.modulate.a = 0.0
	await _parte_3a()
	await _parte_3b()
	get_tree().change_scene_to_file(next_scene_path)   # CORTE a escena 9 (sin fade)


# ---------------------------------------------------------------- guion 7: fecha
func _parte_3a() -> void:
	# Se prende la barra y el efecto mientras la pantalla está en negro,
	# así cuando corta a la cocina ya se ve con el clima aplicado.
	Climate.snap(clima_inicial)
	Climate.set_visuals(true)

	await _esperar(1.0)
	await _mostrar_texto("Miércoles - 6 de Noviembre de 1985", 1.0, 2.0)


# ---------------------------------------------------------------- guion 8: cocina
func _parte_3b() -> void:
	fade_rect.modulate.a = 0.0   # CORTE a escena 8 (sin fade)
	sfx_reloj.play()
	await _esperar(1.5)

	DialogueManager.show_dialogue_balloon(dialogue_resource, "cocina")
	await DialogueManager.dialogue_ended


# ---------------------------------------------------------------- helpers
func _esperar(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _mostrar_texto(texto: String, fade_time: float, hold: float) -> void:
	sobreimpreso.text = texto
	var t := create_tween()
	t.tween_property(sobreimpreso, "modulate:a", 1.0, fade_time)
	t.tween_interval(hold)
	t.tween_property(sobreimpreso, "modulate:a", 0.0, fade_time)
	await t.finished
