class_name Enemigo
extends EntidadEspacial

@export var valor_puntos: int = 10

# Lo mete en el grupo de enemigos y le da 1 sola vida
func _ready() -> void:
	add_to_group("Enemigos")
	configurar_vidas(1)

# Antes de borrarse, avisa cuántos puntos vale para sumarlos al marcador
func destruir() -> void:
	hide()
	Eventos.enemigo_destruido.emit(valor_puntos)
	super.destruir()

# Si llega a tocar la nave del jugador, lo mata al contacto
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador") and body.has_method("morir"):
		body.morir()
