extends Node2D
## ESCENA 2 - guion 3 a 6: título y fecha (negro) -> hospital -> pesadilla -> hospital (despierta)
##
## Árbol de nodos esperado:
## Escena2 (Node2D, este script)
## ├── FondoHospital        (Sprite2D: habitación con tormenta, ventana + cama con Patricia y Eva)
## ├── FondoPesadilla       (Sprite2D: Villa Epecuén inundada, mujer de ojos blancos con cuchillo)
## ├── FondoHospitalCalma   (Sprite2D: habitación sin tormenta)
## ├── Camera2D
## ├── SFXTormenta          (AudioStreamPlayer, loop)
## ├── SFXLlantoBebe        (AudioStreamPlayer)
## ├── BGMCuna              (AudioStreamPlayer, canción de cuna)
## ├── SFXTormentaElectrica (AudioStreamPlayer, lluvia y truenos, loop)
## └── CanvasLayer          (Layer = 50)
##     ├── FlashRect        (ColorRect blanco, Full Rect, Mouse Filter = Ignore, Modulate alpha = 0)
##     ├── FadeRect         (ColorRect negro, Full Rect, Mouse Filter = Ignore, Modulate alpha = 1)
##     └── Sobreimpreso     (Label, Full Rect, centrado, Modulate alpha = 0)
## (Orden en el árbol: FlashRect, FadeRect, Sobreimpreso. SFXGrito y SFXGritoMujer ya no se usan: podés borrarlos.)

@export var dialogue_resource: DialogueResource = preload("res://dialogue/scenes_0/escena_02a_hospital.dialogue")
@export_file("*.tscn") var next_scene_path: String = "res://scenes/escena_3.tscn"

## Cámara del hospital: arranca acercada a la ventana y termina en la cama.
@export var pos_ventana := Vector2(900, 200)
@export var zoom_ventana := Vector2(2.5, 2.5)
@export var pos_cama := Vector2(576, 324)

@onready var fondo_hospital: Sprite2D = $FondoHospital
@onready var fondo_pesadilla: Sprite2D = $FondoPesadilla
@onready var fondo_calma: Sprite2D = $FondoHospitalCalma
@onready var camera: Camera2D = $Camera2D
@onready var sfx_tormenta: AudioStreamPlayer = $SFXTormenta
@onready var sfx_llanto: AudioStreamPlayer = $SFXLlantoBebe
@onready var bgm_cuna: AudioStreamPlayer = $BGMCuna
@onready var sfx_tormenta_electrica: AudioStreamPlayer = $SFXTormentaElectrica
@onready var flash_rect: ColorRect = $CanvasLayer/FlashRect
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var sobreimpreso: Label = $CanvasLayer/Sobreimpreso


func _ready() -> void:
	fade_rect.visible = true
	flash_rect.visible = true
	fade_rect.modulate.a = 1.0
	flash_rect.modulate.a = 0.0
	sobreimpreso.modulate.a = 0.0
	await _parte_titulo()
	await _parte_2a()
	await _parte_2b()
	await _parte_2c()
	get_tree().change_scene_to_file(next_scene_path)


# ---------------------------------------------------------------- guion 3: título y fecha
func _parte_titulo() -> void:
	sfx_tormenta.play()   # (SFX: sonido de tormenta) -- sigue sonando en el hospital
	await _mostrar_texto("Domingo - 28 de abril de 1968", 1.0, 2.0)


# ---------------------------------------------------------------- guion 4: hospital
func _parte_2a() -> void:
	_mostrar_fondo(fondo_hospital)
	camera.position = pos_ventana
	camera.zoom = zoom_ventana

	sfx_llanto.play()
	await _esperar(1.5)   # primero oscuridad

	# La ventana se ilumina por la caída de un rayo
	await _rayo()

	# Zoom out hacia la cama
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "zoom", Vector2.ONE, 4.0)
	t.tween_property(camera, "position", pos_cama, 4.0)
	await t.finished

	DialogueManager.show_dialogue_balloon(dialogue_resource, "cuna")
	await DialogueManager.dialogue_ended

	# Los ojos de Patricia se cierran lentamente
	bgm_cuna.play()
	await _parpadeo(3)
	await _fade_to(1.0, 1.5)
	sfx_llanto.stop()
	sfx_tormenta.stop()


# ---------------------------------------------------------------- guion 5: pesadilla
func _parte_2b() -> void:
	bgm_cuna.stop()
	_mostrar_fondo(fondo_pesadilla)
	camera.position = pos_cama
	camera.zoom = Vector2.ONE

	# Fuerte trueno: Patricia abre los ojos y ve a la mujer
	sfx_tormenta_electrica.play()
	await _esperar(0.7)
	await _rayo()

	DialogueManager.show_dialogue_balloon(dialogue_resource, "pesadilla_1")
	await DialogueManager.dialogue_ended

	# Por apenas un segundo un fuerte relámpago ilumina el rostro de la figura
	await _rayo()
	await _fade_to(1.0, 2.0)
	sfx_tormenta_electrica.stop()


# ---------------------------------------------------------------- guion 6: despierta
func _parte_2c() -> void:
	_mostrar_fondo(fondo_calma)
	await _fade_to(0.0, 1.0)
	await _esperar(1.0)

	DialogueManager.show_dialogue_balloon(dialogue_resource, "despierta")
	await DialogueManager.dialogue_ended

	await _fade_to(1.0, 1.5)   # fade to black -> fecha del guion 7


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


func _mostrar_texto(texto: String, fade_time: float, hold: float) -> void:
	sobreimpreso.text = texto
	var t := create_tween()
	t.tween_property(sobreimpreso, "modulate:a", 1.0, fade_time)
	t.tween_interval(hold)
	t.tween_property(sobreimpreso, "modulate:a", 0.0, fade_time)
	await t.finished


## Destello de rayo: saca el negro de golpe y el blanco se apaga rápido.
func _rayo() -> void:
	fade_rect.modulate.a = 0.0
	flash_rect.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(flash_rect, "modulate:a", 0.0, 0.4)
	await t.finished


## Parpadeo de imagen: negro rápido, varias veces.
func _parpadeo(veces: int) -> void:
	for i in veces:
		fade_rect.modulate.a = 1.0
		await _esperar(0.15)
		fade_rect.modulate.a = 0.0
		await _esperar(0.3)
