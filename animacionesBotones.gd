
extends Node2D

@onready var palanca: AnimatedSprite2D = $PALANCA
@onready var boton: AnimatedSprite2D = $BOTON

var direccion_actual: StringName = &""
var boton_presionado: bool = false

#esto es para la PALANCA

func _ready() -> void:
	# detiene las anim. automaticas
	palanca.stop()
	boton.stop()

	palanca.animation = &"atras"
	palanca.frame = 0

	boton.animation = &"default"
	boton.frame = 0


func _process(_delta: float) -> void:
	actualizar_palanca()
	actualizar_boton()


# con esot detecta que tecla usas para la direccion y te tira la anim. correspondiente

func obtener_direccion() -> StringName:
	if Input.is_key_pressed(KEY_A):
		return &"izquierda"

	if Input.is_key_pressed(KEY_D):
		return &"derecha"

	if Input.is_key_pressed(KEY_W):
		return &"atras"

	if Input.is_key_pressed(KEY_S):
		return &"adelante"

	return &""


func actualizar_palanca() -> void:
	var nueva_direccion := obtener_direccion()

	if nueva_direccion == direccion_actual:
		return

	direccion_actual = nueva_direccion

	if direccion_actual == &"":
		# si soltás vuelve al frame 0 q es el de reposo
		palanca.frame = 0
	else:
		# sino te muestra lo que sea q hayas apretado
		palanca.animation = direccion_actual
		palanca.frame = 1


# esto es para el BOTON

func actualizar_boton() -> void:
	var presionado := Input.is_key_pressed(KEY_SPACE)

	if presionado == boton_presionado:
		return

	boton_presionado = presionado

	if boton_presionado:
		# con esto hunde el boton
		boton.frame = 1
	else:
		# sino ps está normal
		boton.frame = 0
