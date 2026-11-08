extends Node2D
## ESCENA 2 - 2A (hospital 1968) -> 2B (pesadilla) -> 2C (hospital, despierta)
##
## Árbol de nodos esperado:
## Escena2 (Node2D, este script)
## ├── FondoHospital       (Sprite2D: habitación con tormenta, ventana + cama con Patricia y Eva)
## ├── FondoPesadilla      (Sprite2D: calle inundada, mujer de ojos blancos con cuchillo)
## ├── FondoHospitalCalma  (Sprite2D: habitación sin tormenta)
## ├── Camera2D
## ├── SFXTormenta         (AudioStreamPlayer, loop)
## ├── SFXLlantoBebe       (AudioStreamPlayer)
## ├── BGMCuna             (AudioStreamPlayer, canción de cuna)
## ├── SFXTormentaElectrica(AudioStreamPlayer, loop)
## ├── SFXGrito            (AudioStreamPlayer)
## ├── SFXGritoMujer       (AudioStreamPlayer)
## └── CanvasLayer
##     ├── FlashRect       (ColorRect blanco, Full Rect, Mouse Filter = Ignore, Modulate alpha = 0)
##     └── FadeRect        (ColorRect negro, Full Rect, Mouse Filter = Ignore, Modulate alpha = 1)
## (FlashRect va ANTES que FadeRect en el árbol, para que el negro quede encima.)

@export var dialogue_resource: DialogueResource = preload("res://dialogue/scenes_0/escena_02a_hospital.dialogue")
@export_file("*.tscn") var next_scene_path: String = "res://scenes/escena_3.tscn"

## Cámara de 2A: arranca acercada a la ventana y termina en la cama.
@export var pos_ventana := Vector2(900, 200)    # ajustá a la posición de la ventana
@export var zoom_ventana := Vector2(2.5, 2.5)
@export var pos_cama := Vector2(576, 324)       # posición final (centro de pantalla)

@onready var fondo_hospital: Sprite2D = $FondoHospital
@onready var fondo_pesadilla: Sprite2D = $FondoPesadilla
@onready var fondo_calma: Sprite2D = $FondoHospitalCalma
@onready var camera: Camera2D = $Camera2D
@onready var sfx_tormenta: AudioStreamPlayer = $SFXTormenta
@onready var sfx_llanto: AudioStreamPlayer = $SFXLlantoBebe
@onready var bgm_cuna: AudioStreamPlayer = $BGMCuna
@onready var sfx_tormenta_electrica: AudioStreamPlayer = $SFXTormentaElectrica
@onready var sfx_grito: AudioStreamPlayer = $SFXGrito
@onready var sfx_grito_mujer: AudioStreamPlayer = $SFXGritoMujer
@onready var flash_rect: ColorRect = $CanvasLayer/FlashRect
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect


func _ready() -> void:
	fade_rect.visible = true
	flash_rect.visible = true
	fade_rect.modulate.a = 1.0
	flash_rect.modulate.a = 0.0
	await _parte_2a()
	await _parte_2b()
	await _parte_2c()
	get_tree().change_scene_to_file(next_scene_path)


# ---------------------------------------------------------------- 2A
func _parte_2a() -> void:
	_mostrar_fondo(fondo_hospital)
	camera.position = pos_ventana
	camera.zoom = zoom_ventana

	# (SFX: tormenta) (SFX: llanto de bebé) -- primero oscuridad
	sfx_tormenta.play()
	sfx_llanto.play()
	await _esperar(1.5)

	# La ventana se ilumina por la caída de un rayo
	await _rayo()

	# (VFX: zoom out de la ventana) hasta el plano general de la habitación
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "zoom", Vector2.ONE, 4.0)
	t.tween_property(camera, "position", pos_cama, 4.0)
	await t.finished

	# PATRICIA: Arrorró...
	DialogueManager.show_dialogue_balloon(dialogue_resource, "cuna")
	await DialogueManager.dialogue_ended

	# (BGM: tarareo de canción de cuna) (VFX: parpadeo de imagen) (Patricia se duerme)
	bgm_cuna.play()
	await _parpadeo(3)
	await _fade_to(1.0, 1.5)
	sfx_llanto.stop()
	sfx_tormenta.stop()


# ---------------------------------------------------------------- 2B
func _parte_2b() -> void:
	bgm_cuna.stop()
	_mostrar_fondo(fondo_pesadilla)
	camera.position = pos_cama
	camera.zoom = Vector2.ONE

	# (SFX: tormenta eléctrica)
	sfx_tormenta_electrica.play()
	await _esperar(0.7)   # un instante en negro
	await _rayo()         # el rayo revela a la mujer del cuchillo

	# (SFX: grito) -> pensamiento y grito de Patricia
	sfx_grito.play()
	DialogueManager.show_dialogue_balloon(dialogue_resource, "pesadilla")
	await DialogueManager.dialogue_ended

	# (SFX: grito de mujer) (1 segundo de espera) (desvanecimiento 2 s)
	sfx_grito_mujer.play()
	await _esperar(1.0)
	await _fade_to(1.0, 2.0)
	sfx_tormenta_electrica.stop()


# ---------------------------------------------------------------- 2C
func _parte_2c() -> void:
	_mostrar_fondo(fondo_calma)
	await _fade_to(0.0, 1.0)
	await _esperar(1.0)

	DialogueManager.show_dialogue_balloon(dialogue_resource, "despierta")
	await DialogueManager.dialogue_ended

	await _fade_to(1.0, 1.5)   # fade to black -> escena 3A


# ---------------------------------------------------------------- helpers
func _mostrar_fondo(fondo: Sprite2D) -> void:
	fondo_hospital.visible = (fondo == fondo_hospital)
	fondo_pesadilla.visible = (fondo == fondo_pesadilla)
	fondo_calma.visible = (fondo == fondo_calma)


func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", alpha, time)
	await t.finished


func _esperar(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Destello de rayo: revela la imagen (saca el negro) y el blanco se apaga rápido.
func _rayo() -> void:
	fade_rect.modulate.a = 0.0
	flash_rect.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(flash_rect, "modulate:a", 0.0, 0.6)
	await t.finished


## Parpadeo de imagen: negro rápido, varias veces.
func _parpadeo(veces: int) -> void:
	for i in veces:
		fade_rect.modulate.a = 1.0
		await _esperar(1)
		fade_rect.modulate.a = 0.0
		await _esperar(0.5)
