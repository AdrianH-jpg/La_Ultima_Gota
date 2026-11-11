extends Node2D
## ESCENA 4 - guion 9: corral de Luna (madrugada)
##
## Árbol de nodos esperado:
## Escena4 (Node2D, este script)
## ├── FondoCorral   (Sprite2D: Eva abrazando el cuello de Luna en el corral de alambre)
## └── CanvasLayer   (Layer = 50)
##     └── FadeRect  (ColorRect negro, Full Rect, Mouse Filter = Ignore, Modulate alpha = 1)


@export var dialogue_resource: DialogueResource = preload("res://dialogue/scenes_0/escena_04_corral.dialogue")
@export_file("*.tscn") var next_scene_path: String = "res://scenes/escena_5.tscn"

@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect


func _ready() -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	await _fade_to(0.0, 1.0)

	DialogueManager.show_dialogue_balloon(dialogue_resource, "corral")
	await DialogueManager.dialogue_ended

	await _fade_to(1.0, 1.0)   # FADE OUT -> escena 10
	get_tree().change_scene_to_file(next_scene_path)


func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", alpha, time)
	await t.finished
