@tool
class_name GuionImporter
extends RefCounted
## Lee guion.xlsx y genera res://dialogue/<archivo>.dialogue + res://guion/personajes.json

const COLS := ["escena","archivo","titulo","tipo","personaje","animacion","modo","texto","comando","clima","destino"]



static func importar(xlsx_path: String = "res://guion/guion.xlsx", out_dialogue_dir: String = "res://dialogue", out_json: String = "res://guion/personajes.json", out_escenas: String = "res://guion/escenas.json", out_fondos: String = "res://guion/fondos.json") -> Array:
	var errores: Array = []
	# un .xlsx es un zip con XML adentro, lo leemos directo
	var zip := ZIPReader.new()
	if zip.open(xlsx_path) != OK:
		return ["No se pudo abrir " + xlsx_path]
	var shared := _shared_strings(zip.read_file("xl/sharedStrings.xml") if zip.file_exists("xl/sharedStrings.xml") else PackedByteArray())
	var hojas := _hojas(zip)
	# leemos cada hoja que necesitamos
	var guion := _leer_hoja(zip, hojas.get("Guion", ""), shared)
	var pers := _leer_hoja(zip, hojas.get("Personajes", ""), shared)
	var anims := _leer_hoja(zip, hojas.get("Animaciones", ""), shared)
	var fondos_h := _leer_hoja(zip, hojas.get("Fondos", ""), shared)
	zip.close()
	if guion.size() < 2:
		return ["La hoja Guion está vacía o no existe"]

	# ---- personajes.json ----
	var data := {"personajes": {}, "animaciones": {}}
	for i in range(1, pers.size()):
		var r: Array = pers[i]
		if str(r[0]) == "": continue
		data["personajes"][str(r[0])] = {
			"escena": str(r[1]), "posicion": str(r[2]) if str(r[2]) != "" else "centro",
			"escala": float(str(r[3])) if str(r[3]) != "" else 1.0}
	for i in range(1, anims.size()):
		var r: Array = anims[i]
		if str(r[0]) == "" or str(r[1]) == "": continue
		data["animaciones"][str(r[0]) + "|" + str(r[1])] = str(r[2]) if str(r[2]) != "" else str(r[1])
	DirAccess.make_dir_recursive_absolute(out_json.get_base_dir())
	var fj := FileAccess.open(out_json, FileAccess.WRITE)
	fj.store_string(JSON.stringify(data, "\t"))
	fj.close()

	# ---- fondos.json (hoja Fondos: id, imagen, cam_x, cam_y, cam_zoom, escala) ----
	var fondos := {}
	for i in range(1, fondos_h.size()):
		var r: Array = fondos_h[i]
		var id := str(r[0])
		# ignora las filas de ayuda que hay al final de la hoja
		if id == "" or not id.begins_with("Fondo"): continue
		var f := {}
		if str(r[1]) != "": f["imagen"] = str(r[1])
		for k in [[2, "cam_x"], [3, "cam_y"], [4, "cam_zoom"], [5, "escala"]]:
			if str(r[k[0]]) != "": f[k[1]] = float(str(r[k[0]]))
		fondos[id] = f
	var ff := FileAccess.open(out_fondos, FileAccess.WRITE)
	ff.store_string(JSON.stringify(fondos, "\t"))
	ff.close()

	# ---- .dialogue por archivo ----
	var por_archivo := {}      # archivo -> Array[String] líneas
	var titulo_actual := {}    # archivo -> título abierto
	var cierra_pendiente := {} # archivo -> bool (el bloque abierto necesita => END)
	var orden: Array = []      # archivos en orden de aparición
	var titulos := {}          # archivo -> títulos en orden
	var destinos := {}         # archivo -> títulos que son destino de una opción (ramas)
	for i in range(1, guion.size()):
		var r: Array = guion[i]
		var d := {}
		for c in COLS.size(): d[COLS[c]] = str(r[c]) if c < r.size() else ""
		var arch: String = d["archivo"]
		var tipo: String = d["tipo"]
		# las notas y encabezados son solo para leer, no van al juego
		if arch == "" or tipo in ["", "nota", "encabezado"]: continue
		if not por_archivo.has(arch):
			por_archivo[arch] = []
			titulo_actual[arch] = ""
			cierra_pendiente[arch] = false
			orden.append(arch); titulos[arch] = []; destinos[arch] = []
		var L: Array = por_archivo[arch]
		# cambió el título: cerramos el bloque anterior y abrimos uno nuevo
		if d["titulo"] != titulo_actual[arch]:
			if cierra_pendiente[arch]: L.append("=> END")
			if L.size() > 0: L.append("")
			L.append("~ " + d["titulo"])
			titulo_actual[arch] = d["titulo"]
			titulos[arch].append(d["titulo"])
			cierra_pendiente[arch] = true
		match tipo:
			"dialogo":
				if d["personaje"] == "":
					errores.append("Fila %d: dialogo sin personaje" % (i + 1)); continue
				# antes de cada línea hablada va el mostrar() del personaje
				if d["animacion"] != "" or d["personaje"] != "Narrador":
					L.append('do Guion.mostrar("%s", "%s")' % [_esc(d["personaje"]), _esc(d["animacion"])])
				if d["texto"] == "": continue   # fila sin texto: solo muestra al personaje, no habla
				L.append("%s: %s" % [d["personaje"], _fmt(d["texto"], d["modo"])])
				# si hay clima, mueve la barra emocional
				if d["clima"] != "": L.append("do Climate.add(%s)" % d["clima"])
				cierra_pendiente[arch] = true
			"pantalla":
				L.append('do Guion.pantalla("%s", %s)' % [_esc(d["texto"]), "true" if d["modo"] == "cursiva" else "false"])
			"comando":
				if d["comando"] == "": errores.append("Fila %d: comando vacío" % (i + 1)); continue
				# ir_titulo("final") salta a otro título del mismo archivo (no se puede escribir => en Excel porque lo toma como fórmula)
				if d["comando"].begins_with("ir_titulo("):
					var destino_t: String = d["comando"].get_slice('"', 1)
					L.append("=> " + destino_t)
					cierra_pendiente[arch] = false
					destinos[arch].append(destino_t)   # es una rama, no se juega en secuencia
					continue
				# los comandos se escriben tal cual, con 'do' adelante
				L.append("do " + d["comando"])
				# después de saltar o terminar no puede seguir más diálogo
				if d["comando"].begins_with("Guion.ir_a") or d["comando"].begins_with("Guion.fin"):
					L.append("=> END"); cierra_pendiente[arch] = false
			"opcion":
				if d["destino"] != "": destinos[arch].append(d["destino"])
				# las opciones llevan su clima y su destino
				L.append("- " + d["texto"])
				if d["clima"] != "": L.append("\tdo Climate.add(%s)" % d["clima"])
				L.append("\t=> " + (d["destino"] if d["destino"] != "" else "END"))
				cierra_pendiente[arch] = false
			_:
				errores.append("Fila %d: tipo desconocido '%s'" % [i + 1, tipo])
	# escenas.json: orden de escenas y títulos que se reproducen en secuencia (las ramas no)
	var seq := {}
	for a in orden:
		seq[a] = titulos[a].filter(func(t): return not (t in destinos[a]))
	var fe := FileAccess.open(out_escenas, FileAccess.WRITE)
	fe.store_string(JSON.stringify({"orden": orden, "titulos": seq}, "\t"))
	fe.close()
	DirAccess.make_dir_recursive_absolute(out_dialogue_dir)
	for arch in por_archivo:
		var L: Array = por_archivo[arch]
		if cierra_pendiente[arch]: L.append("=> END")
		var f := FileAccess.open("%s/%s.dialogue" % [out_dialogue_dir, arch], FileAccess.WRITE)
		f.store_string("\n".join(L) + "\n")
		f.close()
	return errores


# la cursiva (pensamientos) se marca con [i]
static func _fmt(texto: String, modo: String) -> String:
	return "[i]%s[/i]" % texto if modo == "cursiva" else texto


# escapa las comillas para poder meter el texto dentro de un comando
static func _esc(s: String) -> String:
	return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


# ---------------- lectura mínima de xlsx ----------------
static func _hojas(zip: ZIPReader) -> Dictionary:
	# nombre de hoja -> ruta dentro del zip
	var res := {}
	var rels := {}
	var p := XMLParser.new()
	p.open_buffer(zip.read_file("xl/_rels/workbook.xml.rels"))
	while p.read() == OK:
		if p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_node_name() == "Relationship":
			rels[p.get_named_attribute_value_safe("Id")] = p.get_named_attribute_value_safe("Target")
	p = XMLParser.new()
	p.open_buffer(zip.read_file("xl/workbook.xml"))
	while p.read() == OK:
		if p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_node_name() == "sheet":
			var rid := p.get_named_attribute_value_safe("r:id")
			var t: String = rels.get(rid, "")
			t = t.trim_prefix("/").trim_prefix("xl/")
			res[p.get_named_attribute_value_safe("name")] = "xl/" + t
	return res


# el xlsx guarda los textos aparte; acá los juntamos en una lista
static func _shared_strings(bytes: PackedByteArray) -> Array:
	var out: Array = []
	if bytes.is_empty(): return out
	var p := XMLParser.new()
	p.open_buffer(bytes)
	var actual := ""
	var en_si := false
	var en_t := false
	while p.read() == OK:
		match p.get_node_type():
			XMLParser.NODE_ELEMENT:
				match p.get_node_name():
					"si": en_si = true; actual = ""
					"t": en_t = true
			XMLParser.NODE_TEXT:
				if en_si and en_t: actual += p.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				match p.get_node_name():
					"t": en_t = false
					"si": out.append(actual); en_si = false
	return out


# convierte la letra de la columna (A, B, ...) en un número
static func _col_idx(ref: String) -> int:
	var n := 0
	for ch in ref:
		if ch >= "A" and ch <= "Z": n = n * 26 + (ch.unicode_at(0) - 64)
		else: break
	return n - 1


# devuelve la hoja como lista de filas; cada fila es una lista de celdas
static func _leer_hoja(zip: ZIPReader, path: String, shared: Array) -> Array:
	var filas: Array = []
	if path == "" or not zip.file_exists(path): return filas
	var p := XMLParser.new()
	p.open_buffer(zip.read_file(path))
	var fila: Array = []
	var tipo := ""
	var col := 0
	var en_v := false
	var en_t := false
	var val := ""
	while p.read() == OK:
		match p.get_node_type():
			XMLParser.NODE_ELEMENT:
				match p.get_node_name():
					"row": fila = []
					"c":
						tipo = p.get_named_attribute_value_safe("t")
						col = _col_idx(p.get_named_attribute_value_safe("r"))
						val = ""
					"v": en_v = true
					"t": en_t = true
			XMLParser.NODE_TEXT:
				if en_v or en_t: val += p.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				match p.get_node_name():
					"v": en_v = false
					"t": en_t = false
					"c":
						while fila.size() <= col: fila.append("")
						fila[col] = shared[int(val)] if tipo == "s" and val != "" else val
					"row":
						# rellena para que todas las filas tengan 11 columnas
						while fila.size() < 11: fila.append("")
						filas.append(fila)
	return filas
