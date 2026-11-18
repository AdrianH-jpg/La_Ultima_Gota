@tool
extends EditorScript
## Archivo > Ejecutar para generar los archivos dialogue y los json de personajes y fondos.

func _run() -> void:
	# lee el Excel y genera los .dialogue y los json
	var errores := GuionImporter.importar()
	# los problemas que encuentre en el Excel salen como advertencias
	for e in errores: push_warning(e)
	# le avisa a Godot que hay archivos nuevos
	EditorInterface.get_resource_filesystem().scan()
	print("Guion importado. Avisos: ", errores.size())
