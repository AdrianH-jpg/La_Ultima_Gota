@tool
extends EditorScript
## Archivo > Ejecutar (Ctrl+Shift+X) con este script abierto en el editor de scripts.

func _run() -> void:
	var errores := GuionImporter.importar()
	for e in errores: push_warning(e)
	EditorInterface.get_resource_filesystem().scan()
	print("Guion importado. Avisos: ", errores.size())
