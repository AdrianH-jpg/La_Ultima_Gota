extends Area2D

@export var dialogue_resource: DialogueResource
var dialogo_activo: bool = false

func _ready() -> void:
	input_event.connect(_on_input_event)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogo_activo:
			return
		DialogueManager.show_dialogue_balloon(dialogue_resource, "examinar_telegrama")

func _on_dialogue_started(_resource: DialogueResource) -> void:
	dialogo_activo = true

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	dialogo_activo = false
