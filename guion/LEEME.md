# Guía rápida

1. Copiá guion.xlsx a res://guion/ y los .gd a res://guion/.
2. Autoloads (en orden): DialogueManager, Climate, Guion (guion.gd).
3. Por cada personaje creá res://personajes/<id>.tscn (Node2D con un AnimatedSprite2D; los nombres de animación = columna animacion_sprite de la hoja Animaciones).
4. Abrí importar_guion.gd en el editor de scripts y ejecutá Archivo > Ejecutar. Se generan res://dialogue/*.dialogue y personajes.json. Repetilo cada vez que edites el Excel.
5. En cada escena, poné escena_guion.gd en el nodo raíz y completá archivo / titulos / siguiente_escena.

## Valores de Inspector por escena
- escena_1: titulos = ['intro', 'matadero']
- escena_2: titulos = ['titulo_fecha', 'cuna', 'pesadilla_1', 'pesadilla_2', 'despierta']
- escena_3: titulos = ['fecha', 'cocina']
- escena_4: titulos = ['corral']
- escena_5: titulos = ['tranquera']
- escena_6: titulos = ['pizarron', 'opcion_a', 'opcion_b']
- escena_12: titulos = ['start']
- escena_13: titulos = ['start']
- escena_14: titulos = ['start']
- escena_15: titulos = ['start', 'aceptar', 'negarse']
- escena_16a: titulos = ['start']
- escena_16b: titulos = ['start']
- escena_17: titulos = ['start']
- escena_18: titulos = ['start']
- escena_19: titulos = ['start']
- escena_20: titulos = ['start']
- escena_21: titulos = ['start']
- escena_22: titulos = ['start']
- escena_23: titulos = ['start']
- escena_24: titulos = ['start']
- escena_25: titulos = ['start']
- escena_26: titulos = ['start']
- escena_27: titulos = ['start', 'desobedecer', 'obedecer']
- escena_28a: titulos = ['start']
- escena_28b: titulos = ['start']
- escena_29: titulos = ['start']
- escena_30: titulos = ['start']
- escena_31: titulos = ['start']
- escena_32: titulos = ['start']
- escena_33: titulos = ['start']
- escena_34: titulos = ['start', 'buscar', 'pueblo']
- escena_35a: titulos = ['start']
- escena_36a: titulos = ['start']
- escena_35b: titulos = ['start']
