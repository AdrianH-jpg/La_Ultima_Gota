extends Node
## Autoload "Climate": clima emocional del juego (Godot 4).
## Se usa desde Dialogue Manager con:  do Climate.add(15)

signal changed(value: float, delta: float)   ## valor lógico (0-100), al cambiar
signal smooth_changed(normalized: float)     ## valor suavizado 0..1, durante la transición

const MIN_VALUE := 0.0
const MAX_VALUE := 100.0

var start_value := 50.0
var smooth_speed := 2.5   ## más alto = transición más rápida

var value: float = 50.0       ## valor real (0-100)
var display: float = 0.5      ## valor suavizado normalizado (0-1)

var _target: float = 0.5


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


func get_normalized() -> float:
	return value / MAX_VALUE


## Útil para condiciones en los diálogos: if Climate.mood() == "sombrio"
func mood() -> String:
	if value < 20.0:
		return "sombrio"
	elif value < 40.0:
		return "apagado"
	elif value < 60.0:
		return "neutral"
	elif value < 80.0:
		return "vivo"
	return "eufórico"


# --- Guardado ---
func get_save_data() -> Dictionary:
	return {"climate": value}


func load_save_data(data: Dictionary) -> void:
	set_value(data.get("climate", start_value))
	display = _target
	smooth_changed.emit(display)
