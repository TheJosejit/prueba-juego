extends Node
## Autoload "Sfx": efectos de sonido y música generados por código (estilo chiptune, sin archivos de audio).
## Uso: Sfx.play("jump"), Sfx.play_music(), Sfx.stop_music(). La tecla M silencia el juego.

const VOICES := 8
const BEAT := 0.4 # segundos por negra (150 BPM)

# Melodía original: "nota:duración en corcheas". R = silencio.
const MELODY := [
	"C5:1 E5:1 G5:2 E5:1 G5:1 C6:2",
	"A5:2 G5:1 E5:1 C5:2 E5:2",
	"F5:1 A5:1 C6:2 A5:1 F5:1 A5:2",
	"G5:3 F5:1 E5:1 D5:1 B4:2",
	"C5:1 E5:1 G5:2 C6:1 B5:1 A5:1 G5:1",
	"E5:2 A5:2 G5:1 E5:1 C5:2",
	"F5:1 A5:1 G5:1 F5:1 D5:1 G5:1 B4:2",
	"C5:4 R:2 G4:1 B4:1",
]
const BASS := [
	"C3 G3 C3 G3", "A2 E3 A2 E3", "F2 C3 F2 C3", "G2 D3 G2 D3",
	"C3 G3 C3 G3", "A2 E3 A2 E3", "F2 C3 G2 D3", "C3 G3 C3 G2",
]

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		player.bus = &"SFX"
		add_child(player)
		players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -16.0
	music_player.bus = &"Music"
	add_child(music_player)
	_build_sounds()
	music_player.stream = _build_music()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


func play(sound: String, pitch_variation := 0.0) -> void:
	var player := players[next_player]
	next_player = (next_player + 1) % VOICES
	player.stream = sounds[sound]
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func play_music() -> void:
	if not music_player.playing:
		music_player.play()


func stop_music() -> void:
	music_player.stop()


func _build_sounds() -> void:
	var s := Synth.new(0.18)
	s.note(0.0, 0.18, 280, 680, Synth.SQUARE, 0.35, 0.25)
	sounds["jump"] = s.to_stream()

	s = Synth.new(0.35)
	s.note(0.0, 0.07, 988, 988, Synth.SQUARE, 0.3)
	s.note(0.07, 0.28, 1319, 1319, Synth.SQUARE, 0.3)
	sounds["coin"] = s.to_stream()

	s = Synth.new(0.18)
	s.note(0.0, 0.15, 500, 90, Synth.SQUARE, 0.35)
	s.note(0.0, 0.1, 3000, 3000, Synth.NOISE, 0.25)
	sounds["stomp"] = s.to_stream()

	s = Synth.new(0.12)
	s.note(0.0, 0.1, 180, 90, Synth.TRIANGLE, 0.7)
	s.note(0.0, 0.06, 2500, 2500, Synth.NOISE, 0.2)
	sounds["bump"] = s.to_stream()

	s = Synth.new(0.4)
	var i := 0
	for freq in [1319, 1568, 2093, 1760, 2349, 2637]:
		s.note(i * 0.06, 0.1, freq, freq, Synth.SQUARE, 0.25, 0.25)
		i += 1
	sounds["one_up"] = s.to_stream()

	s = Synth.new(1.1)
	i = 0
	for freq in [988, 932, 880, 831]:
		s.note(i * 0.13, 0.13, freq, freq, Synth.SQUARE, 0.3, 0.5, 0.6)
		i += 1
	s.note(0.55, 0.5, 330, 80, Synth.TRIANGLE, 0.6)
	sounds["die"] = s.to_stream()

	s = Synth.new(1.6)
	i = 0
	for note_name in ["C5", "E5", "G5", "C6", "E6", "G6"]:
		s.note(i * 0.1, 0.12, Synth.freq(note_name), Synth.freq(note_name), Synth.SQUARE, 0.25, 0.5, 0.6)
		i += 1
	s.note(0.6, 1.0, Synth.freq("C6"), Synth.freq("C6"), Synth.SQUARE, 0.25, 0.5, 0.5)
	s.note(0.6, 1.0, Synth.freq("C4"), Synth.freq("C4"), Synth.TRIANGLE, 0.5, 0.5, 0.5)
	sounds["win"] = s.to_stream()

	s = Synth.new(2.0)
	i = 0
	for note_name in ["G4", "E4", "C4"]:
		s.note(i * 0.45, 0.45, Synth.freq(note_name), Synth.freq(note_name), Synth.SQUARE, 0.25, 0.5, 0.7)
		s.note(i * 0.45, 0.45, Synth.freq(note_name) / 2.0, Synth.freq(note_name) / 2.0, Synth.TRIANGLE, 0.5, 0.5, 0.7)
		i += 1
	s.note(1.35, 0.6, Synth.freq("C3"), Synth.freq("B2"), Synth.TRIANGLE, 0.6, 0.5, 0.3)
	sounds["game_over"] = s.to_stream()


func _build_music() -> AudioStreamWAV:
	var eighth := BEAT / 2.0
	var bars := MELODY.size()
	var s := Synth.new(bars * 8 * eighth)
	for bar in bars:
		var t: float = bar * 8 * eighth
		for token: String in MELODY[bar].split(" "):
			var parts := token.split(":")
			var length := int(parts[1]) * eighth
			if parts[0] != "R":
				var f := Synth.freq(parts[0])
				s.note(t, length * 0.95, f, f, Synth.SQUARE, 0.2, 0.5, 0.6)
			t += length
		var beat := 0
		for note_name: String in BASS[bar].split(" "):
			var f := Synth.freq(note_name)
			s.note(bar * 8 * eighth + beat * BEAT, BEAT * 0.9, f, f, Synth.TRIANGLE, 0.45, 0.5, 0.7)
			beat += 1
		for k in 4: # charles en los contratiempos
			s.note(bar * 8 * eighth + k * BEAT + eighth, 0.03, 8000, 8000, Synth.NOISE, 0.08)
	return s.to_stream(true)


## Sintetizador mínimo: mezcla notas en un búfer y lo convierte en AudioStreamWAV.
class Synth:
	const MIX_RATE := 22050
	const SQUARE := 0
	const TRIANGLE := 1
	const NOISE := 2
	const NOTE_INDEX := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

	var buf := PackedFloat32Array()

	func _init(length: float) -> void:
		buf.resize(int(length * MIX_RATE))

	## Frecuencia de una nota tipo "C5", "F#4" o "Bb3".
	static func freq(note_name: String) -> float:
		var semitone: int = NOTE_INDEX[note_name[0]]
		var octave_pos := 1
		if note_name[1] == "#":
			semitone += 1
			octave_pos = 2
		elif note_name[1] == "b":
			semitone -= 1
			octave_pos = 2
		var midi := 12 * (int(note_name.substr(octave_pos)) + 1) + semitone
		return 440.0 * pow(2.0, (midi - 69) / 12.0)

	## Añade una nota. sustain = fracción de la nota a volumen completo antes de apagarse.
	func note(start: float, duration: float, f0: float, f1: float, wave: int, volume: float,
			duty := 0.5, sustain := 0.0) -> void:
		var first := int(start * MIX_RATE)
		var count := mini(int(duration * MIX_RATE), buf.size() - first)
		var attack := 0.004 * MIX_RATE
		var phase := 0.0
		var noise := 0.0
		for i in count:
			var t := float(i) / count
			phase += lerpf(f0, f1, t) / MIX_RATE
			if phase >= 1.0:
				phase -= 1.0
				noise = randf_range(-1.0, 1.0)
			var sample := noise
			if wave == SQUARE:
				sample = 1.0 if phase < duty else -1.0
			elif wave == TRIANGLE:
				sample = 4.0 * absf(phase - 0.5) - 1.0
			var env := minf(1.0, i / attack)
			if t > sustain:
				env *= (1.0 - t) / (1.0 - sustain)
			buf[first + i] += sample * env * volume

	func to_stream(loop := false) -> AudioStreamWAV:
		var data := PackedByteArray()
		data.resize(buf.size() * 2)
		for i in buf.size():
			data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = MIX_RATE
		stream.data = data
		if loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = buf.size()
		return stream
