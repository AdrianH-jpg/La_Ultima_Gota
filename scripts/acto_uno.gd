extends Node2D

@export var dialogue_resource: DialogueResource = preload("res://dialogue/actoUno.dialogue")

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, "intro_oficina")
