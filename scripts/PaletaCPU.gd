
class_name PaletaCPU
extends PaletaBase

# PALETA CONTROLADA POR LA CPU FEA TU ENEMIGA MORTAL
# Hereda posición, velocidad y límites de PaletaBase como la paleta del jugador


# movimiento automático
func actualizar_movimiento(
	delta: float,
	alto_pantalla: float,
	pelota_y: float,
	jugando: bool,
	velocidad_pelota_x: float
) -> void:

	# vuelve sola siempre al centro por defecto
	var objetivo_y: float = alto_pantalla * 0.5

	# con esto persigue la pelota solo cuando viene hacia el lado de la cpu
	if jugando and velocidad_pelota_x > 0.0:
		objetivo_y = pelota_y

	# con esto se DESPLAZA al objeto, en lugar de teletransportarse (re cheat sino)
	_acercarse(
		objetivo_y,
		alto_pantalla * _factor_velocidad * delta,
		alto_pantalla
	)
