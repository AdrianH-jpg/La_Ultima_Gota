extends ProgressBar
## Barra visual del clima emocional. Ponela en un CanvasLayer con layer = 20
## (encima del post-proceso para que no se deforme).

var _gradient := Gradient.new()


func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	step = 0.001
	show_percentage = false

	_gradient.offsets = PackedFloat32Array([0.0, 0.4, 0.7, 1.0])
	_gradient.colors = PackedColorArray([
		Color("3b4a6b"),  # sombrío
		Color("9aa0a6"),  # neutral
		Color("ffb347"),  # vivo
		Color("ff3d81"),  # eufórico
	])

	Climate.smooth_changed.connect(_update_bar)
	_update_bar(Climate.display)


func _update_bar(normalized: float) -> void:
	value = normalized
	modulate = _gradient.sample(normalized)
