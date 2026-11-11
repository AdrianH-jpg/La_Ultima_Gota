extends Node2D
## ESCENA 6 - guion 11, 11A y 11B: salón de clases (día), decisión del pizarrón
##
## Árbol de nodos esperado:
## Escena6 (Node2D, este script)
## ├── FondoSalon    (Sprite2D: pizarrón verde con el insulto y los 3 nombres subrayados, Eva en plano medio)
## ├── FondoPilarA   (Sprite2D: plano medio de Pilar; pizarrón con un borrón y los nombres con líneas debajo)
## ├── FondoPilarB   (Sprite2D: plano medio de Pilar; borrón y un par de líneas borrosas bajo su nombre)
## ├── SFXRisas      (AudioStreamPlayer)
## └── CanvasLayer   (Layer = 50)
##     └── FadeRect  (ColorRect negro, Full Rect, Mouse Filter = Ignore, Modulate alpha = 1)
##
## Las opciones del diálogo cortan al plano de Pilar con mostrar_pilar_a() / mostrar_pilar_b().
## Las tres ramas terminan con FADE OUT hacia la escena 12 (balneario).


@export var dialogue_resource: DialogueResource = preload("res://dialogue/scenes_0/escena_06a_salon.dialogue")
## Escena 12 (balneario): todavía no existe. Cuando la crees, elegila acá en el Inspector.
@export_file("*.tscn") var next_scene_path: String = ""

@onready var fondo_salon: Sprite2D = $FondoSalon
@onready var fondo_pilar_a: Sprite2D = $FondoPilarA
@onready var fondo_pilar_b: Sprite2D = $FondoPilarB
@onready var sfx_risas: AudioStreamPlayer = $SFXRisas
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect


func _ready() -> void:
	_mostrar_fondo(fondo_salon)
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	await _fade_to(0.0, 1.0)

	# El [self] permite usar desde el diálogo: do mostrar_pilar_a(), do sonido_risas(), etc.
	DialogueManager.show_dialogue_balloon(dialogue_resource, "pizarron", [self])
	await DialogueManager.dialogue_ended

	await _fade_to(1.0, 1.0)   # FADE OUT -> escena 12
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)


# ---- Comandos para el diálogo ----
func mostrar_pilar_a() -> void:
	_mostrar_fondo(fondo_pilar_a)


func mostrar_pilar_b() -> void:
	_mostrar_fondo(fondo_pilar_b)


## do sonido_risas()      -> risas
## do sonido_risas(true)  -> las risas se escuchan más fuerte
func sonido_risas(fuerte: bool = false) -> void:
	sfx_risas.volume_db = 0.0 if fuerte else -8.0
	sfx_risas.play()


# ---- Helpers ----
func _mostrar_fondo(fondo: Sprite2D) -> void:
	fondo_salon.visible = (fondo == fondo_salon)
	fondo_pilar_a.visible = (fondo == fondo_pilar_a)
	fondo_pilar_b.visible = (fondo == fondo_pilar_b)


func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", alpha, time)
	await t.finished
