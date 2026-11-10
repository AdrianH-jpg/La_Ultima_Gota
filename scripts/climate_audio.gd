extends Node
## Autoload "ClimateAudio": el sonido sigue el clima emocional.
## Desesperanza -> amortiguado (low-pass), grave, con reverb.
## Calidez      -> sonido limpio.
## Descontrol   -> más agudo, inestable, con reverb.
## Se apaga cuando Climate.visuals_on es false. Requiere un bus "Music".

@export var bus_name := "Music"

var _lowpass: AudioEffectLowPassFilter
var _pitch: AudioEffectPitchShift
var _reverb: AudioEffectReverb


func _ready() -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("ClimateAudio: no existe el bus '%s'." % bus_name)
		return

	_lowpass = AudioEffectLowPassFilter.new()
	_pitch = AudioEffectPitchShift.new()
	_reverb = AudioEffectReverb.new()
	_reverb.wet = 0.0
	_reverb.dry = 1.0
	AudioServer.add_bus_effect(idx, _lowpass)
	AudioServer.add_bus_effect(idx, _pitch)
	AudioServer.add_bus_effect(idx, _reverb)

	Climate.smooth_changed.connect(_apply)
	Climate.visuals_toggled.connect(func(_on: bool): _apply(Climate.display))
	_apply(Climate.display)


func _apply(normalized: float) -> void:
	if _lowpass == null:
		return
	if not Climate.visuals_on:
		_lowpass.cutoff_hz = 20500.0
		_pitch.pitch_scale = 1.0
		_reverb.wet = 0.0
		return

	var despair := clampf(1.0 - normalized / 0.5, 0.0, 1.0)
	var madness := clampf((normalized - 0.5) / 0.5, 0.0, 1.0)

	_lowpass.cutoff_hz = lerpf(20500.0, 1200.0, despair)
	_pitch.pitch_scale = 1.0 - despair * 0.07 + madness * 0.08
	_reverb.wet = despair * 0.25 + madness * 0.2
	_reverb.room_size = 0.4 + despair * 0.4 + madness * 0.3
