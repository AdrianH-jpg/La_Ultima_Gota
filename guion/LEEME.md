# Guía rápida

1. Todo lo que edites en guion.xlsx necesita ser reimportado.
2. Los siguientes archivos tienen que estar en Autoloads: DialogueManager, Climate, Guion (guion.gd).
3. Por cada personaje creá res://personajes/<id>.tscn (Node2D con un AnimatedSprite2D; los nombres de animación = columna animacion_sprite de la hoja Animaciones).
4. Abrí importar_guion.gd en el editor de scripts y ejecutá Archivo > Ejecutar. Se generan res://dialogue/*.dialogue y personajes.json. Repetilo cada vez que edites el Excel.
5. Todo se visualiza desde la escena juego.tscn y usando el script juego.gd
