extends CanvasLayer
## CanvasLayer con un ColorRect hijo que tiene el shader del clima.

@onready var rect: ColorRect = $ColorRect

# animación para prender y apagar el efecto
var _mix_tween: Tween


func _ready() -> void:
	layer = 10  # por encima del mundo fondos/personajes, por debajo de la UI y los diálogos
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# el shader acompaña al clima mientras cambia
	Climate.smooth_changed.connect(_on_climate_changed)
	Climate.visuals_toggled.connect(_on_visuals_toggled)
	_on_climate_changed(Climate.display)
	_set_mix(1.0 if Climate.visuals_on else 0.0)


# le pasa el clima de 0 a 1 al shader
func _on_climate_changed(normalized: float) -> void:
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("climate", normalized)


# prende o apaga el efecto con un fundido de 1 segundo
func _on_visuals_toggled(on: bool) -> void:
	if _mix_tween:
		_mix_tween.kill()
	var mat := rect.material as ShaderMaterial
	var from: float = 0.0
	if mat and mat.get_shader_parameter("effect_mix") != null:
		from = mat.get_shader_parameter("effect_mix")
	_mix_tween = create_tween()
	_mix_tween.tween_method(_set_mix, from, 1.0 if on else 0.0, 1.0)


# effect_mix: 0 = sin efecto, 1 = efecto completo
func _set_mix(v: float) -> void:
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("effect_mix", v)
