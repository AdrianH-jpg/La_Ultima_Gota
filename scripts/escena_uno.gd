extends Node2D
## ESCENA 1 - EXT. MATADERO MUNICIPAL 2026 - DÍA
##
## Árbol de nodos esperado:
## Escena1 (Node2D, este script)
## ├── Fondo      (Sprite2D o TextureRect con las ruinas del matadero, la tela colorada en el alambrado y las nubes grises)
## ├── Camera2D   (para el movimiento de cámara / zoom hacia la tela)
## ├── SFXViento  (AudioStreamPlayer, viento suave, loop)
## ├── SFXAves    (AudioStreamPlayer, sonido de aves)
## └── FadeRect   (ColorRect negro, Full Rect, dentro de un CanvasLayer, alpha = 1 al inicio)

@export var dialogue_resource: DialogueResource = preload("res://dialogue/escena_1.dialogue")
@export_file("*.tscn") var next_scene_path: String = "res://scenes/escena_2a.tscn"

@onready var sfx_viento: AudioStreamPlayer = $SFXViento
@onready var sfx_aves: AudioStreamPlayer = $SFXAves
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	await _play_scene()
	await _fade_to(1.0, 1.0)
	get_tree().change_scene_to_file(next_scene_path)


func _play_scene() -> void:
	# (SFX: VIENTO SUAVE) (SFX: SONIDO DE AVES)
	sfx_viento.play()
	sfx_aves.play()
	await _fade_to(0.0, 1.0)

	# (1.5 SEGUNDOS DE ESPERA)
	await get_tree().create_timer(1.5).timeout

	# Opcional: la cámara "focaliza" lentamente la tela colorada
	# var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# t.tween_property(camera, "zoom", Vector2(1.6, 1.6), 6.0)

	# NARRADOR (FUERA DE ESCENA, TEXTO EN PANTALLA)
	DialogueManager.show_dialogue_balloon(dialogue_resource, "escena_1")
	await DialogueManager.dialogue_ended


func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", alpha, time)
	await t.finished
