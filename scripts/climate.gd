extends Node
## Autoload "Climate": clima emocional de Eva (Godot 4).
##   0   = desesperanza (frío, oscuro, casi blanco y negro)
##   ~50 = calidez (cálido y colorido)
##   100 = descontrol (sobresaturado, distorsión, locura)
## Desde Dialogue Manager:  do Climate.add(5)

signal changed(value: float, delta: float)   ## valor lógico (0-100), al cambiar
signal smooth_changed(normalized: float)     ## valor suavizado 0..1, durante la transición
signal visuals_toggled(on: bool)             ## se prende/apaga el efecto y la barra

const MIN_VALUE := 0.0
const MAX_VALUE := 100.0

var start_value := 15.0     ## Eva arranca en desesperanza
var smooth_speed := 2.5     ## más alto = transición más rápida

var value: float = 15.0
var display: float = 0.15
var visuals_on := false     ## apagado por defecto; se prende al llegar a 3B

var _target: float = 0.15


func _ready() -> void:
	value = start_value
	_target = value / MAX_VALUE
	display = _target


func _process(delta: float) -> void:
	if is_equal_approx(display, _target):
		return
	display = lerpf(display, _target, 1.0 - exp(-smooth_speed * delta))
	if absf(display - _target) < 0.0005:
		display = _target
	smooth_changed.emit(display)


func add(amount: float) -> void:
	set_value(value + amount)


func set_value(new_value: float) -> void:
	var old := value
	value = clampf(new_value, MIN_VALUE, MAX_VALUE)
	_target = value / MAX_VALUE
	changed.emit(value, value - old)


## Cambia el valor al instante, sin transición.
func snap(new_value: float) -> void:
	value = clampf(new_value, MIN_VALUE, MAX_VALUE)
	_target = value / MAX_VALUE
	display = _target
	changed.emit(value, 0.0)
	smooth_changed.emit(display)


## Muestra u oculta el efecto visual/sonoro y la barra (flashbacks, pesadillas, créditos).
func set_visuals(on: bool) -> void:
	if on == visuals_on:
		return
	visuals_on = on
	visuals_toggled.emit(on)


func get_normalized() -> float:
	return value / MAX_VALUE


## Para condiciones en diálogos: if Climate.mood() == "descontrol"
func mood() -> String:
	if value < 20.0:
		return "desesperanza"
	elif value < 40.0:
		return "apagado"
	elif value < 65.0:
		return "calido"
	elif value < 85.0:
		return "exaltado"
	return "descontrol"


# --- Guardado ---
func get_save_data() -> Dictionary:
	return {"climate": value}


func load_save_data(data: Dictionary) -> void:
	snap(data.get("climate", start_value))
