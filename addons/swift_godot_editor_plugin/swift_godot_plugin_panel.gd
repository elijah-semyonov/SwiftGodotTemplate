@tool
extends MarginContainer

const MARGIN = 16

@onready var rebuild_button := $VBoxContainer/ButtonsContainer/RebuildButton
@onready var clean_build_check_button := $VBoxContainer/ButtonsContainer/CleanBuildCheckButton
@onready var log := $VBoxContainer/Log

@onready var swift_path = ProjectSettings.globalize_path("res://swift_godot_game")

const PROGRESS_MARKERS := ["˥", "˦", "˧", "˨", "˩", "˨", "˧", "˦"]

signal state_changed(working: bool)

func _ready() -> void:
	rebuild_button.pressed.connect(recompile_swift)
	
	var on_state_changed = func(is_working: bool):
		rebuild_button.disabled = is_working
		clean_build_check_button.disabled = is_working
	
	state_changed.connect(on_state_changed)

func append_log(string: String) -> void:
	log.append_text(string + "\n")

func wait_process_finished(pid: int, progress_text: String):
	var start_time = Time.get_ticks_msec()
	var i = 0
	var initial_log_text = log.get_parsed_text()
	while OS.is_process_running(pid):
		await get_tree().create_timer(0.1).timeout
		var time_passed = (Time.get_ticks_msec() - start_time) / 1000
		log.text = "%s%s %s %s s " % [initial_log_text, progress_text, PROGRESS_MARKERS[i], time_passed]
		i = (i + 1) % PROGRESS_MARKERS.size()
	log.text = initial_log_text

func recompile_swift() -> void:
	state_changed.emit(true)
	log.clear()
	if OS.is_sandboxed():
		state_changed.emit(false)
		append_log("Impossible to launch OS processed. Sandboxed :()")
		return
	
	var target_dir = ProjectSettings.globalize_path("res://addons/swift_godot_extension/bin")
	if not DirAccess.dir_exists_absolute(target_dir):
		var err = DirAccess.make_dir_recursive_absolute(target_dir)
		if err != OK:
			append_log("Error creating directory '" + target_dir + "'")
			state_changed.emit(false)
			return
		append_log("Building from the scratch. Can take some time. Consequent builds will be much faster")
		
	var i = 0
	if clean_build_check_button.button_pressed:
		append_log("Running `swift package clean`")
		var pid := OS.create_process(
			"swift", [
				"package", "clean", 
				"--package-path", swift_path, 
				"--build-path", target_dir
			], false
		)
		if pid == -1:
			append_log("Couldn't execute `swift package clean` command")
			state_changed.emit(false)
			return
		
		await wait_process_finished(pid, "Cleaning")
		append_log("Cleaned")
	
	var gdignore_path: String = target_dir.path_join(".gdignore")
	append_log("Writing %s" % gdignore_path)
	var file = FileAccess.open(gdignore_path, FileAccess.WRITE)
	if file == null:
		var open_error = FileAccess.get_open_error()
		append_log("Error creating/opening '" + gdignore_path + "'")
		state_changed.emit(false)
		return
	else:
		file.close()
	
	append_log("Building into %s" % target_dir)
	var pid := OS.create_process(
		"swift", [
			"build", 
			"--package-path", swift_path, 
			"--build-path", target_dir
		], false)
	if pid == -1:
		append_log("Couldn't execute `swift build` command")
		state_changed.emit(false)
		return
		
	append_log("Running `swift build`")
	await wait_process_finished(pid, "Building")
	append_log("Done! Restarting editor")
	await get_tree().create_timer(1.0).timeout
	EditorInterface.restart_editor(false)
