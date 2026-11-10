extends Node
## Autoload "ClimateAudio": modifica el bus de música según el clima emocional.
## Sombrío  -> sonido amortiguado (low-pass), más grave y con reverb.
## Eufórico -> un poco más agudo y brillante.
## Requiere un bus llamado "Music" (Audio > Bus Layout). Los efectos se agregan solos.

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
	_apply(Climate.display)


func _apply(normalized: float) -> void:
	var c := (normalized - 0.5) * 2.0
	var high := maxf(c, 0.0)
	var low := maxf(-c, 0.0)

	_lowpass.cutoff_hz = lerpf(20500.0, 900.0, low)
	_pitch.pitch_scale = 1.0 + high * 0.05 - low * 0.08
	_reverb.wet = low * 0.35
	_reverb.room_size = 0.4 + low * 0.5
