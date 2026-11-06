extends CanvasLayer
## Escena sugerida:
##   ClimatePostProcess (CanvasLayer, este script, layer = 10)
##     └─ ColorRect (Full Rect, Mouse Filter = Ignore,
##                   Material = ShaderMaterial con climate_post_process.gdshader)

@onready var rect: ColorRect = $ColorRect


func _ready() -> void:
	layer = 10  # por debajo de la UI (la barra y las cajas de diálogo usan layer > 10)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Climate.smooth_changed.connect(_on_climate_changed)
	_on_climate_changed(Climate.display)


func _on_climate_changed(normalized: float) -> void:
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("climate", normalized)
