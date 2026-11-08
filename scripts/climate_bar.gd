extends ProgressBar
## Barra del clima emocional. Va en un CanvasLayer con layer = 20.
## Se oculta con fade cuando Climate.visuals_on es false.

var _gradient := Gradient.new()
var _tween: Tween


func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	step = 0.001
	show_percentage = false

	_gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 1.0])
	_gradient.colors = PackedColorArray([
		Color("3a4358"),  # desesperanza
		Color("8a95a3"),  # apagado
		Color("ffb347"),  # calidez
		Color("ff1f6b"),  # descontrol
	])

	Climate.smooth_changed.connect(_update_bar)
	Climate.visuals_toggled.connect(_on_toggled)
	_update_bar(Climate.display)
	modulate.a = 1.0 if Climate.visuals_on else 0.0


func _update_bar(normalized: float) -> void:
	value = normalized
	self_modulate = _gradient.sample(normalized)


func _on_toggled(on: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0 if on else 0.0, 1.0)
