## Nave especial que cruza la parte superior de la pantalla.
## Hereda de Enemigo y otorga una bonificación de puntos al ser destruida.
class_name Ovni
extends Enemigo

@export var velocidad: float = 150.0
@export var puntos_bonus: int = 300

func _ready() -> void:
	super._ready()
	valor_puntos = puntos_bonus
	if has_node("VisibleOnScreenEnabler2D"):
		$VisibleOnScreenEnabler2D.screen_exited.connect(_on_screen_exited)

func _physics_process(delta: float) -> void:
	position.x += velocidad * delta

func _on_screen_exited() -> void:  
	queue_free()
