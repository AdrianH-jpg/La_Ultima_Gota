## Gestor global de señales y persistencia local de los puntajes
extends Node

signal enemigo_destruido(puntos: int)
signal jugador_destruido
signal nivel_superado
signal actualizar_nivel_hud(nuevo_nivel: int)

const RUTA_GUARDADO: String = "user://top10_local.cfg"
const MAX_REGISTROS: int = 10

var puntaje_actual: int = 0
var mejor_puntaje_local: int = 0
var nombre_record_local: String = "AAA"
var _tabla_top_10: Array[Dictionary] = []

# Apenas arranca el juego, lee los puntajes guardados en el dispositivo
func _ready() -> void:
	cargar_record_local()

# Entrega una copia de la tabla para que nadie la modifique por accidente desde afuera
func obtener_top_10() -> Array[Dictionary]:
	return _tabla_top_10.duplicate()

# Revisa si los puntos alcanzan para entrar entre los 10 mejores
func califica_en_top_10(puntos: int) -> bool:
	if puntos <= 0:
		return false
	if _tabla_top_10.size() < MAX_REGISTROS:
		return true
	return puntos > _tabla_top_10.back()["puntos"]

# Agrega el nuevo puntaje, ordena de mayor a menor, recorta al Top 10 y guarda en disco
func guardar_record_local(nuevo_puntaje: int, iniciales: String) -> void:
	_tabla_top_10.append({"nombre": iniciales, "puntos": nuevo_puntaje})
	_tabla_top_10.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["puntos"] > b["puntos"]
	)
	
	if _tabla_top_10.size() > MAX_REGISTROS:
		_tabla_top_10.resize(MAX_REGISTROS)
		
	_actualizar_primer_puesto()
	
	var config := ConfigFile.new()
	config.set_value("Ranking", "top10", _tabla_top_10)
	config.save(RUTA_GUARDADO)

# Lee el archivo .cfg local y reconstruye la lista de mejores puntajes
func cargar_record_local() -> void:
	var config := ConfigFile.new()
	if config.load(RUTA_GUARDADO) == OK:
		var datos_guardados = config.get_value("Ranking", "top10", [])
		_tabla_top_10.clear()
		for item in datos_guardados:
			if item is Dictionary:
				_tabla_top_10.append(item)
		_actualizar_primer_puesto()

# Actualiza las variables rápidas con el nombre y puntaje del número 1 actual
func _actualizar_primer_puesto() -> void:
	if not _tabla_top_10.is_empty():
		mejor_puntaje_local = _tabla_top_10[0]["puntos"]
		nombre_record_local = _tabla_top_10[0]["nombre"]

## Instancia balas, explosiones u objetos dentro del SubViewport del minijuego (y no en 1920x1080).
func instanciar_en_nivel(nodo_referencia: Node, instancia: Node, diferido: bool = false) -> void:
	var contenedor_nivel: Node = nodo_referencia.get_viewport()
	if contenedor_nivel == null:
		contenedor_nivel = nodo_referencia.get_tree().current_scene
	if diferido:
		contenedor_nivel.call_deferred("add_child", instancia)
	else:
		contenedor_nivel.add_child(instancia)

## Cambia de escena dentro del SubViewport del arcade sin destruir la máquina arcade.
func cambiar_escena_minijuego(nodo_actual: Node, ruta_escena: String) -> void:
	var escena_empaquetada := load(ruta_escena) as PackedScene
	if escena_empaquetada == null:
		push_error("No se pudo cargar la escena: " + ruta_escena)
		return
	var nueva_escena: Node = escena_empaquetada.instantiate()
	var padre: Node = nodo_actual.get_viewport()
	if padre == null:
		padre = nodo_actual.get_tree().root
	padre.add_child(nueva_escena)
	
	# Elimina la escena raíz actual del minijuego (la hija directa del SubViewport)
	var raiz_minijuego: Node = nodo_actual
	while raiz_minijuego.get_parent() != null and raiz_minijuego.get_parent() != padre:
		raiz_minijuego = raiz_minijuego.get_parent()
	raiz_minijuego.queue_free()
