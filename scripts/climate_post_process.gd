extends CanvasLayer
## CanvasLayer (layer 10) con un ColorRect hijo que tiene el shader del clima.

@onready var rect: ColorRect = $ColorRect

var _mix_tween: Tween


func _ready() -> void:
	layer = 10  # por encima del mundo (fondos/personajes), por debajo de la UI y los diálogos
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Climate.smooth_changed.connect(_on_climate_changed)
	Climate.visuals_toggled.connect(_on_visuals_toggled)
	_on_climate_changed(Climate.display)
	_set_mix(1.0 if Climate.visuals_on else 0.0)


func _on_climate_changed(normalized: float) -> void:
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("climate", normalized)


func _on_visuals_toggled(on: bool) -> void:
	if _mix_tween:
		_mix_tween.kill()
	var mat := rect.material as ShaderMaterial
	var from: float = 0.0
	if mat and mat.get_shader_parameter("effect_mix") != null:
		from = mat.get_shader_parameter("effect_mix")
	_mix_tween = create_tween()
	_mix_tween.tween_method(_set_mix, from, 1.0 if on else 0.0, 1.0)


func _set_mix(v: float) -> void:
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("effect_mix", v)
