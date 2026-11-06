extends Node
## Escena principal: lanza el diálogo con el balloon de Dialogue Manager.

@export var dialogue_path := "res://dialogue/escena_teo_dialogo.dialogue"
@export var start_title := "start"


func _ready() -> void:
	var resource := load(dialogue_path)
	DialogueManager.show_dialogue_balloon(resource, start_title)


## Atajos de prueba (quitar en la versión final): F1 baja el clima, F2 lo sube.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			Climate.add(-10)
		elif event.keycode == KEY_F2:
			Climate.add(10)
