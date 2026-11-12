@tool
class_name GuionImporter
extends RefCounted
## Lee guion.xlsx y genera res://dialogue/<archivo>.dialogue + res://guion/personajes.json

const COLS := ["escena","archivo","titulo","tipo","personaje","animacion","modo","texto","comando","clima","destino"]


static func importar(xlsx_path: String = "res://guion/guion.xlsx", out_dialogue_dir: String = "res://dialogue", out_json: String = "res://guion/personajes.json") -> Array:
	var errores: Array = []
	var zip := ZIPReader.new()
	if zip.open(xlsx_path) != OK:
		return ["No se pudo abrir " + xlsx_path]
	var shared := _shared_strings(zip.read_file("xl/sharedStrings.xml") if zip.file_exists("xl/sharedStrings.xml") else PackedByteArray())
	var hojas := _hojas(zip)
	var guion := _leer_hoja(zip, hojas.get("Guion", ""), shared)
	var pers := _leer_hoja(zip, hojas.get("Personajes", ""), shared)
	var anims := _leer_hoja(zip, hojas.get("Animaciones", ""), shared)
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

	# ---- .dialogue por archivo ----
	var por_archivo := {}      # archivo -> Array[String] líneas
	var titulo_actual := {}    # archivo -> título abierto
	var cierra_pendiente := {} # archivo -> bool (el bloque abierto necesita => END)
	for i in range(1, guion.size()):
		var r: Array = guion[i]
		var d := {}
		for c in COLS.size(): d[COLS[c]] = str(r[c]) if c < r.size() else ""
		var arch: String = d["archivo"]
		var tipo: String = d["tipo"]
		if arch == "" or tipo in ["", "nota", "encabezado"]: continue
		if not por_archivo.has(arch):
			por_archivo[arch] = []
			titulo_actual[arch] = ""
			cierra_pendiente[arch] = false
		var L: Array = por_archivo[arch]
		if d["titulo"] != titulo_actual[arch]:
			if cierra_pendiente[arch]: L.append("=> END")
			if L.size() > 0: L.append("")
			L.append("~ " + d["titulo"])
			titulo_actual[arch] = d["titulo"]
			cierra_pendiente[arch] = true
		match tipo:
			"dialogo":
				if d["personaje"] == "":
					errores.append("Fila %d: dialogo sin personaje" % (i + 1)); continue
				if d["animacion"] != "" or d["personaje"] != "Narrador":
					L.append('do Guion.mostrar("%s", "%s")' % [_esc(d["personaje"]), _esc(d["animacion"])])
				L.append("%s: %s" % [d["personaje"], _fmt(d["texto"], d["modo"])])
				if d["clima"] != "": L.append("do Climate.add(%s)" % d["clima"])
				cierra_pendiente[arch] = true
			"pantalla":
				L.append('do Guion.pantalla("%s", %s)' % [_esc(_fmt(d["texto"], d["modo"])), "true" if d["modo"] == "cursiva" else "false"])
			"comando":
				if d["comando"] == "": errores.append("Fila %d: comando vacío" % (i + 1)); continue
				L.append("do " + d["comando"])
				if d["comando"].begins_with("Guion.ir_a"):
					L.append("=> END"); cierra_pendiente[arch] = false
			"opcion":
				L.append("- " + d["texto"])
				if d["clima"] != "": L.append("\tdo Climate.add(%s)" % d["clima"])
				L.append("\t=> " + (d["destino"] if d["destino"] != "" else "END"))
				cierra_pendiente[arch] = false
			_:
				errores.append("Fila %d: tipo desconocido '%s'" % [i + 1, tipo])
	DirAccess.make_dir_recursive_absolute(out_dialogue_dir)
	for arch in por_archivo:
		var L: Array = por_archivo[arch]
		if cierra_pendiente[arch]: L.append("=> END")
		var f := FileAccess.open("%s/%s.dialogue" % [out_dialogue_dir, arch], FileAccess.WRITE)
		f.store_string("\n".join(L) + "\n")
		f.close()
	return errores


static func _fmt(texto: String, modo: String) -> String:
	return "[i]%s[/i]" % texto if modo == "cursiva" else texto


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


static func _col_idx(ref: String) -> int:
	var n := 0
	for ch in ref:
		if ch >= "A" and ch <= "Z": n = n * 26 + (ch.unicode_at(0) - 64)
		else: break
	return n - 1


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
						while fila.size() < 11: fila.append("")
						filas.append(fila)
	return filas
