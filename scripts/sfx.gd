extends Node
## Autoload "Sfx": efectos de sonido y música sintetizados por código (estilo chiptune, sin archivos de audio).
## Uso: Sfx.play("jump"), Sfx.play_music("meadow"), Sfx.stop_music(). La tecla M silencia el juego.
##
## Las canciones están en SONGS como texto (acordes, melodía y batería). Se generan en segundo plano
## la primera vez y se guardan en user://music_cache, así después cargan al instante.
## Si cambias una canción, su caché se regenera sola.

const VOICES := 10
const CACHE_DIR := "user://music_cache"
const SYNTH_VERSION := 3 # súbelo si cambias cómo suena el sintetizador (invalida la caché)

## Canciones. Cada compás tiene un acorde (o dos separados por espacio) y una línea de melodía
## con "nota:duración en corcheas" (R = silencio). Batería: 16 semicorcheas por compás,
## K = bombo, S = caja, h = charles, o = charles abierto, . = nada.
## bass: "bounce" (fundamental-quinta), "drive" (corcheas), "half" (blancas), "hold" (redonda).
## arp: "16" (arpegio en semicorcheas), "8" (corcheas) o "" (sin arpegio). pad: acordes de fondo.
const SONGS := {
	"menu": {
		"bpm": 112, "bass": "half", "arp": "8", "pad": true,
		"drums": "K.......S.......",
		"chords": ["F", "Dm", "Bb", "C", "F", "Dm", "Bb C", "F"],
		"melody": [
			"A5:2 C6:2 A5:2 F5:2", "D5:2 F5:2 A5:4", "Bb5:2 A5:1 G5:1 F5:2 D5:2", "C5:2 E5:2 G5:4",
			"A5:1 Bb5:1 C6:2 A5:2 F5:2", "F5:2 D5:2 A5:4", "Bb5:2 G5:2 C6:2 E5:2", "F5:6 R:2",
		],
	},
	"meadow": {
		"bpm": 150, "bass": "bounce", "arp": "16",
		"drums": "K.h.S.h.K.h.S.hh",
		"chords": ["C", "Am", "F", "G", "C", "Am", "F G", "C", "F", "G", "Em", "Am", "F", "G", "C", "C"],
		"melody": [
			"C5:1 E5:1 G5:2 E5:1 G5:1 C6:2", "A5:2 G5:1 E5:1 C5:2 E5:2",
			"F5:1 A5:1 C6:2 A5:1 F5:1 A5:2", "G5:3 F5:1 E5:1 D5:1 B4:2",
			"C5:1 E5:1 G5:2 C6:1 B5:1 A5:1 G5:1", "E5:2 A5:2 G5:1 E5:1 C5:2",
			"F5:1 A5:1 G5:1 F5:1 D5:1 G5:1 B4:2", "C5:4 R:2 G4:1 B4:1",
			"A5:2 C6:2 A5:1 G5:1 F5:2", "G5:2 B5:2 D6:2 B5:2",
			"E5:1 G5:1 B5:2 G5:1 E5:1 G5:2", "A5:3 G5:1 E5:2 C5:2",
			"F5:1 A5:1 C6:1 A5:1 F5:1 A5:1 C6:2", "D6:2 C6:1 B5:1 A5:2 G5:2",
			"E5:1 G5:1 C6:2 G5:1 E5:1 G5:2", "C6:4 R:4",
		],
	},
	"cave": {
		"bpm": 96, "bass": "half", "arp": "8", "pad": true, "lead": "triangle",
		"drums": "K.....h.K.....h.",
		"chords": ["Am", "Am", "F", "E", "Am", "Dm", "E", "E"],
		"melody": [
			"E5:3 C5:1 A4:4", "B4:2 C5:2 E5:4", "F5:3 E5:1 C5:4", "B4:2 G#4:2 E4:4",
			"A4:2 C5:2 E5:2 A5:2", "F5:3 E5:1 D5:4", "C5:2 B4:2 G#4:2 B4:2", "A4:6 R:2",
		],
	},
	"sky": {
		"bpm": 168, "bass": "bounce", "arp": "16",
		"drums": "K.h.S.hoK.h.S.h.",
		"chords": ["D", "Bm", "G", "A", "D", "Bm", "G A", "D"],
		"melody": [
			"F#5:1 A5:1 D6:2 A5:1 F#5:1 A5:2", "B5:2 A5:1 F#5:1 D5:2 F#5:2",
			"G5:1 B5:1 D6:2 B5:1 G5:1 E5:2", "A5:3 G5:1 F#5:1 E5:1 C#5:2",
			"D5:1 F#5:1 A5:1 D6:1 C#6:1 B5:1 A5:2", "B5:2 D6:2 C#6:1 B5:1 F#5:2",
			"G5:1 B5:1 A5:1 G5:1 E5:1 A5:1 C#5:2", "D5:4 R:2 A4:1 C#5:1",
		],
	},
	"volcano": {
		"bpm": 140, "bass": "drive", "arp": "",
		"drums": "K.hKS.h.K.hKS.hh",
		"chords": ["Em", "Em", "C", "D", "Em", "Em", "C B", "B"],
		"melody": [
			"E5:1 E5:1 G5:1 E5:1 B5:2 A5:1 G5:1", "F#5:2 E5:1 D5:1 E5:4",
			"C5:1 E5:1 G5:1 C6:1 B5:2 G5:2", "D5:1 F#5:1 A5:1 D6:1 C6:2 A5:2",
			"E5:1 E5:1 G5:1 E5:1 B5:2 C6:1 B5:1", "A5:2 G5:1 F#5:1 G5:2 E5:2",
			"C5:2 E5:2 D#5:2 F#5:2", "B4:4 D#5:2 F#5:2",
		],
	},
}

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music_player: AudioStreamPlayer
var songs := {} # nombre -> AudioStreamWAV ya generada
var current_song := "" # la canción que debería sonar
var _tasks := {} # nombre -> tarea en segundo plano
var _results := {}
var _mutex := Mutex.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.volume_db = -6.0
		player.bus = &"SFX"
		add_child(player)
		players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -8.0
	music_player.bus = &"Music"
	add_child(music_player)
	_build_sounds()
	for song_name in SONGS:
		_load_or_generate(song_name)


func _exit_tree() -> void:
	for task in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(task)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


## pitch_variation: variación aleatoria del tono (0.05 = ±5 %). pitch: tono base (2.0 = una octava más agudo).
func play(sound: String, pitch_variation := 0.0, pitch := 1.0) -> void:
	var player := players[next_player]
	next_player = (next_player + 1) % VOICES
	player.stream = sounds[sound]
	player.pitch_scale = pitch * (1.0 + randf_range(-pitch_variation, pitch_variation))
	player.play()


func play_music(song_name := "meadow") -> void:
	if current_song == song_name and music_player.playing:
		return
	current_song = song_name
	music_player.stop()
	if songs.has(song_name):
		music_player.stream = songs[song_name]
		music_player.play()


func stop_music() -> void:
	music_player.stop()


## Conecta los sonidos de interfaz a todos los botones dentro de root.
func wire_ui(root: Node) -> void:
	for button in root.find_children("*", "BaseButton", true, false):
		if button.has_meta("sfx_wired"):
			continue
		button.set_meta("sfx_wired", true)
		button.focus_entered.connect(play.bind("ui_move"))
		button.pressed.connect(play.bind("ui_select"))


# --- Música: caché y generación en segundo plano ---

func _cache_path(song_name: String) -> String:
	var key := absi(hash(str(SONGS[song_name]) + str(SYNTH_VERSION)))
	return "%s/%s_%d.res" % [CACHE_DIR, song_name, key]


func _load_or_generate(song_name: String) -> void:
	var path := _cache_path(song_name)
	if ResourceLoader.exists(path):
		var stream := ResourceLoader.load(path) as AudioStreamWAV
		if stream:
			songs[song_name] = stream
			return
	_tasks[song_name] = WorkerThreadPool.add_task(_generate_song.bind(song_name))


func _generate_song(song_name: String) -> void: # se ejecuta en otro hilo
	var stream := _build_song(SONGS[song_name])
	_mutex.lock()
	_results[song_name] = stream
	_mutex.unlock()


func _process(_delta: float) -> void:
	if _tasks.is_empty():
		return
	_mutex.lock()
	var done := _results.duplicate()
	_results.clear()
	_mutex.unlock()
	for song_name: String in done:
		WorkerThreadPool.wait_for_task_completion(_tasks[song_name])
		_tasks.erase(song_name)
		songs[song_name] = done[song_name]
		_save_cache(song_name, done[song_name])
		if song_name == current_song and not music_player.playing:
			play_music(song_name)


func _save_cache(song_name: String, stream: AudioStreamWAV) -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var path := _cache_path(song_name)
	for file in DirAccess.get_files_at(CACHE_DIR): # borra versiones antiguas de esta canción
		if file.begins_with(song_name + "_") and CACHE_DIR + "/" + file != path:
			DirAccess.remove_absolute(CACHE_DIR + "/" + file)
	ResourceSaver.save(stream, path)


func _build_song(song: Dictionary) -> AudioStreamWAV:
	var beat: float = 60.0 / song.bpm
	var bar_len := beat * 4.0
	var bars: int = song.chords.size()
	var s := Synth.new(bars * bar_len)
	var lead_wave := Synth.TRIANGLE if song.get("lead", "") == "triangle" else Synth.SQUARE
	var lead := {"duty": 0.25, "attack": 0.01, "decay": 0.12, "sustain": 0.55, "release": 0.08,
		"vibrato": 0.25, "vibrato_rate": 5.5, "lowpass": 4500.0}
	for bar in bars:
		var t0 := bar * bar_len
		var chord_names: PackedStringArray = song.chords[bar].split(" ")
		var part_len := bar_len / chord_names.size()
		for p in chord_names.size():
			var chord := Synth.chord(chord_names[p])
			var ts := t0 + p * part_len
			_bass(s, song.bass, chord, ts, part_len, beat)
			_arp(s, song.arp, chord, ts, part_len, beat)
			if song.get("pad", false):
				for m: int in chord:
					var f := Synth.midi_freq(m + 12)
					s.note(ts, part_len, f, f, Synth.TRIANGLE, 0.045,
						{"attack": 0.25, "decay": 0.2, "sustain": 0.8, "release": 0.3})
		var t := t0
		for token in (song.melody[bar] as String).split(" "):
			var parts := token.split(":")
			var length := float(parts[1]) * beat / 2.0
			if parts[0] != "R":
				var f := Synth.freq(parts[0])
				s.note(t, length * 0.9, f, f, lead_wave, 0.17 if lead_wave == Synth.SQUARE else 0.32, lead)
			t += length
		var pattern: String = song.drums
		for k in 16:
			var dt := t0 + k * beat / 4.0
			match pattern[k]:
				"K": s.kick(dt)
				"S": s.snare(dt)
				"h": s.hat(dt, false)
				"o": s.hat(dt, true)
	return s.to_stream(true, 0.62)


func _bass(s: Synth, style: String, chord: Array, t: float, length: float, beat: float) -> void:
	var root := Synth.midi_freq(chord[0] - 12)
	var fifth := Synth.midi_freq(chord[2] - 12)
	var opts := {"attack": 0.005, "decay": 0.1, "sustain": 0.7, "release": 0.04}
	var beats := int(round(length / beat))
	match style:
		"bounce":
			for b in beats:
				var f := root if b % 2 == 0 else fifth
				s.note(t + b * beat, beat * 0.85, f, f, Synth.TRIANGLE, 0.42, opts)
		"drive":
			var drive := {"duty": 0.5, "attack": 0.003, "decay": 0.08, "sustain": 0.5, "release": 0.03, "lowpass": 700.0}
			for e in beats * 2:
				var f := root * (2.0 if e % 4 == 2 else 1.0)
				s.note(t + e * beat / 2.0, beat * 0.4, f, f, Synth.SQUARE, 0.22, drive)
		"half":
			for h in maxi(int(beats / 2.0), 1):
				var f := root if h % 2 == 0 else fifth
				s.note(t + h * beat * 2.0, beat * 1.9, f, f, Synth.TRIANGLE, 0.42, opts)
		_:
			s.note(t, length * 0.95, root, root, Synth.TRIANGLE, 0.42, opts)


func _arp(s: Synth, style: String, chord: Array, t: float, length: float, beat: float) -> void:
	if style == "":
		return
	var step := beat / (4.0 if style == "16" else 2.0)
	var notes := [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[1] + 12]
	var opts := {"duty": 0.125, "attack": 0.002, "decay": 0.06, "sustain": 0.3, "release": 0.03, "lowpass": 3500.0}
	for i in int(round(length / step)):
		var f := Synth.midi_freq(notes[i % 4])
		s.note(t + i * step, step * 0.8, f, f, Synth.SQUARE, 0.05, opts)


# --- Efectos de sonido ---

func _build_sounds() -> void:
	var s := Synth.new(0.2)
	s.note(0.0, 0.16, 260, 640, Synth.SQUARE, 0.32, {"duty": 0.25, "decay": 0.14, "sustain": 0.2, "lowpass": 6000.0})
	sounds["jump"] = s.to_stream()

	s = Synth.new(0.22)
	s.note(0.0, 0.08, 500, 900, Synth.SQUARE, 0.25, {"duty": 0.125, "decay": 0.07, "sustain": 0.3})
	s.note(0.06, 0.12, 750, 1400, Synth.SQUARE, 0.25, {"duty": 0.125, "decay": 0.1, "sustain": 0.3})
	sounds["double_jump"] = s.to_stream()

	s = Synth.new(0.45)
	var coin := {"duty": 0.25, "decay": 0.05, "sustain": 0.6, "release": 0.15, "lowpass": 7000.0}
	s.note(0.0, 0.06, 988, 988, Synth.SQUARE, 0.25, coin)
	s.note(0.06, 0.22, 1319, 1319, Synth.SQUARE, 0.25, coin)
	s.note(0.06, 0.22, 2637, 2637, Synth.SINE, 0.12, coin)
	sounds["coin"] = s.to_stream()

	s = Synth.new(0.2)
	s.note(0.0, 0.13, 420, 80, Synth.SQUARE, 0.32, {"decay": 0.12, "sustain": 0.2, "lowpass": 3000.0})
	s.note(0.0, 0.06, 4000, 4000, Synth.NOISE, 0.25, {"decay": 0.05, "sustain": 0.0, "lowpass": 3000.0})
	s.kick(0.0, 0.6)
	sounds["stomp"] = s.to_stream()

	s = Synth.new(0.14)
	s.note(0.0, 0.1, 160, 90, Synth.TRIANGLE, 0.7, {"decay": 0.09, "sustain": 0.1})
	s.note(0.0, 0.04, 3000, 3000, Synth.NOISE, 0.2, {"decay": 0.04, "sustain": 0.0})
	sounds["bump"] = s.to_stream()

	s = Synth.new(0.4)
	s.note(0.0, 0.3, 2500, 2500, Synth.NOISE, 0.45, {"decay": 0.28, "sustain": 0.0, "lowpass": 2500.0})
	for k in 5:
		s.note(0.04 + k * 0.05, 0.03, 1500, 1500, Synth.NOISE, 0.25, {"decay": 0.03, "sustain": 0.0})
	s.note(0.0, 0.15, 140, 60, Synth.TRIANGLE, 0.6, {"decay": 0.14, "sustain": 0.0})
	sounds["break"] = s.to_stream()

	s = Synth.new(0.5)
	s.note(0.0, 0.4, 300, 900, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.7, "vibrato": 1.5, "vibrato_rate": 16.0, "vibrato_delay": 0.0, "lowpass": 5000.0})
	sounds["item_appear"] = s.to_stream()

	s = Synth.new(0.7)
	var i := 0
	for note_name in ["C5", "E5", "G5", "C6", "E6", "G6", "C7"]:
		var f := Synth.freq(note_name)
		s.note(i * 0.055, 0.12, f, f, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.5, "release": 0.1})
		s.note(i * 0.055, 0.12, f * 0.5, f * 0.5, Synth.TRIANGLE, 0.25, {"sustain": 0.5, "release": 0.1})
		i += 1
	sounds["power_up"] = s.to_stream()

	s = Synth.new(0.6)
	i = 0
	for note_name in ["G5", "D5", "A4", "D4"]:
		var f := Synth.freq(note_name)
		s.note(i * 0.09, 0.1, f, f * 0.94, Synth.SQUARE, 0.22, {"duty": 0.5, "sustain": 0.5, "lowpass": 3000.0})
		i += 1
	sounds["power_down"] = s.to_stream()

	s = Synth.new(0.55)
	i = 0
	for freq in [1319, 1568, 2637, 2093, 2349, 3136]:
		s.note(i * 0.07, 0.1, freq, freq, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.6, "release": 0.08})
		i += 1
	sounds["one_up"] = s.to_stream()

	s = Synth.new(0.4)
	s.note(0.0, 0.3, 180, 620, Synth.TRIANGLE, 0.6, {"sustain": 0.6, "vibrato": 3.0, "vibrato_rate": 18.0, "vibrato_delay": 0.03})
	sounds["spring"] = s.to_stream()

	s = Synth.new(0.9)
	var bell := {"attack": 0.002, "decay": 0.5, "sustain": 0.0, "release": 0.1}
	s.note(0.0, 0.5, 1319, 1319, Synth.SINE, 0.35, bell)
	s.note(0.0, 0.5, 2637, 2637, Synth.SINE, 0.12, bell)
	s.note(0.12, 0.7, 1976, 1976, Synth.SINE, 0.35, bell)
	s.note(0.12, 0.7, 3951, 3951, Synth.SINE, 0.1, bell)
	sounds["checkpoint"] = s.to_stream()

	s = Synth.new(1.3)
	i = 0
	for freq in [988, 932, 880, 831]:
		s.note(i * 0.13, 0.12, freq, freq, Synth.SQUARE, 0.25, {"sustain": 0.6, "lowpass": 5000.0})
		i += 1
	s.note(0.55, 0.6, 330, 70, Synth.TRIANGLE, 0.6, {"sustain": 0.7, "release": 0.1, "vibrato": 0.8, "vibrato_rate": 8.0})
	sounds["die"] = s.to_stream()

	s = Synth.new(2.2)
	i = 0
	var fanfare := {"duty": 0.25, "sustain": 0.6, "release": 0.06, "lowpass": 6000.0}
	for note_name in ["C5", "E5", "G5", "C6", "E6", "G6"]:
		var f := Synth.freq(note_name)
		s.note(i * 0.1, 0.1, f, f, Synth.SQUARE, 0.2, fanfare)
		i += 1
	for chord_note in ["C6", "E5", "G5"]:
		var f := Synth.freq(chord_note)
		s.note(0.65, 1.2, f, f, Synth.SQUARE, 0.12, {"duty": 0.25, "sustain": 0.7, "release": 0.3, "vibrato": 0.3})
	s.note(0.65, 1.2, Synth.freq("C3"), Synth.freq("C3"), Synth.TRIANGLE, 0.5, {"sustain": 0.8, "release": 0.3})
	s.kick(0.65)
	s.snare(0.65)
	sounds["win"] = s.to_stream(false, 0.75)

	s = Synth.new(2.4)
	i = 0
	for note_name in ["G4", "E4", "C4"]:
		var f := Synth.freq(note_name)
		s.note(i * 0.45, 0.42, f, f, Synth.SQUARE, 0.2, {"duty": 0.5, "sustain": 0.6, "lowpass": 2500.0})
		s.note(i * 0.45, 0.42, f / 2.0, f / 2.0, Synth.TRIANGLE, 0.45, {"sustain": 0.7})
		i += 1
	s.note(1.35, 0.8, Synth.freq("C3"), Synth.freq("B2"), Synth.TRIANGLE, 0.6, {"sustain": 0.7, "release": 0.3})
	sounds["game_over"] = s.to_stream()

	s = Synth.new(0.05)
	s.note(0.0, 0.03, 900, 900, Synth.SQUARE, 0.15, {"duty": 0.125, "decay": 0.03, "sustain": 0.0, "lowpass": 4000.0})
	sounds["ui_move"] = s.to_stream()

	s = Synth.new(0.06)
	s.note(0.0, 0.04, 3000, 3000, Synth.NOISE, 0.18, {"attack": 0.001, "decay": 0.04, "sustain": 0.0, "lowpass": 1600.0})
	s.note(0.0, 0.03, 140, 110, Synth.TRIANGLE, 0.25, {"attack": 0.001, "decay": 0.03, "sustain": 0.0})
	sounds["step"] = s.to_stream()

	s = Synth.new(0.14)
	s.note(0.0, 0.1, 2500, 2500, Synth.NOISE, 0.35, {"attack": 0.001, "decay": 0.1, "sustain": 0.0, "lowpass": 1200.0})
	s.note(0.0, 0.09, 110, 55, Synth.TRIANGLE, 0.6, {"attack": 0.001, "decay": 0.09, "sustain": 0.0})
	sounds["land"] = s.to_stream()

	s = Synth.new(0.22)
	s.note(0.0, 0.18, 5000, 5000, Synth.NOISE, 0.22, {"attack": 0.005, "decay": 0.17, "sustain": 0.0, "lowpass": 3500.0})
	s.note(0.0, 0.16, 700, 500, Synth.SQUARE, 0.06, {"duty": 0.125, "decay": 0.15, "sustain": 0.0, "lowpass": 2500.0})
	sounds["skid"] = s.to_stream()

	s = Synth.new(0.5)
	s.note(0.0, 0.08, 400, 1500, Synth.TRIANGLE, 0.25, {"attack": 0.001, "decay": 0.08, "sustain": 0.0})
	s.note(0.06, 0.35, 3000, 3000, Synth.NOISE, 0.35, {"attack": 0.001, "decay": 0.34, "sustain": 0.0, "lowpass": 4000.0})
	for k in 6:
		s.note(0.12 + k * 0.045, 0.02, 9000, 9000, Synth.NOISE, 0.18, {"attack": 0.001, "decay": 0.02, "sustain": 0.0})
	sounds["firework"] = s.to_stream()

	s = Synth.new(0.15)
	s.note(0.0, 0.05, 700, 700, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.5, "lowpass": 5000.0})
	s.note(0.05, 0.08, 1050, 1050, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.5, "lowpass": 5000.0})
	sounds["ui_select"] = s.to_stream()

	s = Synth.new(0.2)
	s.note(0.0, 0.06, 880, 880, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.5})
	s.note(0.07, 0.1, 587, 587, Synth.SQUARE, 0.2, {"duty": 0.25, "sustain": 0.5})
	sounds["pause"] = s.to_stream()


## Sintetizador: mezcla notas en un búfer y lo convierte en AudioStreamWAV.
class Synth:
	const MIX_RATE := 22050
	const SQUARE := 0
	const TRIANGLE := 1
	const NOISE := 2
	const SAW := 3
	const SINE := 4
	const NOTE_INDEX := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

	var buf := PackedFloat32Array()
	var rng := RandomNumberGenerator.new()

	func _init(length: float) -> void:
		buf.resize(int(length * MIX_RATE))
		rng.seed = 1234

	## Número MIDI de una nota tipo "C5", "F#4" o "Bb3".
	static func midi(note_name: String) -> int:
		var semitone: int = NOTE_INDEX[note_name[0]]
		var octave_pos := 1
		if note_name[1] == "#":
			semitone += 1
			octave_pos = 2
		elif note_name[1] == "b":
			semitone -= 1
			octave_pos = 2
		return 12 * (int(note_name.substr(octave_pos)) + 1) + semitone

	static func midi_freq(m: int) -> float:
		return 440.0 * pow(2.0, (m - 69) / 12.0)

	static func freq(note_name: String) -> float:
		return midi_freq(midi(note_name))

	## Notas MIDI (fundamental en la octava 3, tercera y quinta) de un acorde tipo "C", "Am" o "F#m".
	static func chord(chord_name: String) -> Array:
		var minor := chord_name.ends_with("m")
		var root := midi(chord_name.trim_suffix("m") + "3")
		return [root, root + (3 if minor else 4), root + 7]

	## Añade una nota con envolvente ADSR. Opciones (opts): duty, attack, decay, sustain (nivel 0-1),
	## release, vibrato (semitonos), vibrato_rate (Hz), vibrato_delay (s), lowpass (Hz).
	func note(start: float, duration: float, f0: float, f1: float, wave: int, volume: float, opts := {}) -> void:
		var duty: float = opts.get("duty", 0.5)
		var attack: float = maxf(opts.get("attack", 0.005) * MIX_RATE, 1.0)
		var decay: float = maxf(opts.get("decay", 0.08) * MIX_RATE, 1.0)
		var sustain: float = opts.get("sustain", 0.7)
		var release: float = maxf(opts.get("release", 0.05) * MIX_RATE, 1.0)
		var vibrato: float = opts.get("vibrato", 0.0) * 0.0578 # aprox. 2^(x/12) - 1 para x pequeños
		var vibrato_step: float = TAU * opts.get("vibrato_rate", 6.0) / MIX_RATE
		var vibrato_start: float = opts.get("vibrato_delay", 0.12) * MIX_RATE
		var lowpass: float = opts.get("lowpass", 0.0)
		var lp := 1.0 if lowpass <= 0.0 else 1.0 - exp(-TAU * lowpass / MIX_RATE)
		var first := int(start * MIX_RATE)
		var gate := maxi(int(duration * MIX_RATE), 1)
		var total := mini(gate + int(release), buf.size() - first)
		var phase := 0.0
		var noise := 0.0
		var filtered := 0.0
		var level := 0.0
		for i in total:
			var freq_now := lerpf(f0, f1, minf(float(i) / gate, 1.0))
			if vibrato > 0.0 and i > vibrato_start:
				freq_now *= 1.0 + vibrato * sin(vibrato_step * i)
			phase += freq_now / MIX_RATE
			if phase >= 1.0:
				phase -= floorf(phase)
				noise = rng.randf_range(-1.0, 1.0)
			var sample := noise
			if wave == SQUARE:
				sample = 1.0 if phase < duty else -1.0
			elif wave == TRIANGLE:
				sample = 4.0 * absf(phase - 0.5) - 1.0
			elif wave == SAW:
				sample = 2.0 * phase - 1.0
			elif wave == SINE:
				sample = sin(TAU * phase)
			var env: float
			if i < gate:
				if i < attack:
					env = i / attack
				elif i < attack + decay:
					env = lerpf(1.0, sustain, (i - attack) / decay)
				else:
					env = sustain
				level = env
			else:
				env = level * (1.0 - (i - gate) / release)
			filtered += lp * (sample - filtered)
			buf[first + i] += filtered * env * volume

	func kick(start: float, volume := 0.75) -> void:
		note(start, 0.13, 150, 42, SINE, volume, {"attack": 0.001, "decay": 0.12, "sustain": 0.0, "release": 0.01})
		note(start, 0.008, 6000, 6000, NOISE, volume * 0.3, {"attack": 0.001, "decay": 0.008, "sustain": 0.0})

	func snare(start: float, volume := 0.32) -> void:
		note(start, 0.13, 7000, 7000, NOISE, volume, {"attack": 0.001, "decay": 0.12, "sustain": 0.0, "lowpass": 6000.0})
		note(start, 0.06, 200, 150, TRIANGLE, volume * 1.2, {"attack": 0.001, "decay": 0.06, "sustain": 0.0})

	func hat(start: float, open: bool, volume := 0.1) -> void:
		var length := 0.12 if open else 0.03
		note(start, length, 11000, 11000, NOISE, volume, {"attack": 0.001, "decay": length, "sustain": 0.0})

	## gain: volumen general (baja si al mezclar muchas notas se satura).
	func to_stream(loop := false, gain := 0.9) -> AudioStreamWAV:
		var data := PackedByteArray()
		data.resize(buf.size() * 2)
		for i in buf.size():
			var x := clampf(buf[i] * gain, -1.0, 1.0)
			x = x * 1.5 - 0.5 * x * x * x # saturación suave en vez de recortar en seco
			data.encode_s16(i * 2, int(x * 32000.0))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = MIX_RATE
		stream.data = data
		if loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = buf.size()
		return stream
