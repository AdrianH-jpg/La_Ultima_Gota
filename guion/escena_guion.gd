extends Node2D
## Script único para TODAS las escenas. Pegalo en el nodo raíz y completá el Inspector:
##   archivo  -> "escena_6"  (res://dialogue/escena_6.dialogue)
##   titulos  -> ["pizarron"]  (se reproducen en orden)
##   siguiente_escena -> escena a la que pasa al terminar (vacío si las opciones ya hacen Guion.ir_a)
## Nodo opcional: CanvasLayer/FadeRect (ColorRect negro) para el fade in/out.

@export var archivo: String = ""
@export var titulos: Array[String] = ["start"]
@export_file("*.tscn") var siguiente_escena: String = ""
@export var usar_fade: bool = true

@onready var fade_rect: ColorRect = get_node_or_null("CanvasLayer/FadeRect")


func _ready() -> void:
	if usar_fade and fade_rect:
		fade_rect.modulate.a = 1.0
		await _fade(0.0)
	var res := load("res://dialogue/%s.dialogue" % archivo)
	for t in titulos:
		DialogueManager.show_dialogue_balloon(res, t, [self])
		await DialogueManager.dialogue_ended
		if get_tree().current_scene != self: return   # una opción ya cambió de escena
	Guion.limpiar()
	if usar_fade and fade_rect: await _fade(1.0)
	if siguiente_escena != "": get_tree().change_scene_to_file(siguiente_escena)


func _fade(a: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", a, 1.0)
	await t.finished
