@tool
extends VBoxContainer

const MARGIN = 16

@onready var recompile_button := Button.new()
@onready var log_label := Label.new()
@onready var log := RichTextLabel.new()
@onready var status := Label.new()

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	offset_bottom = MARGIN
	offset_top = MARGIN
	offset_left = MARGIN
	offset_right = MARGIN
		
	recompile_button.text = "Recompile Swift"
	recompile_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(recompile_button)
	recompile_button.pressed.connect(recompile_swift)
		
	status.text = "Awaiting command"
	add_child(status)
	
	log_label.text = "Log:"
	add_child(log_label)
		
	log.scroll_following = true
	log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(log)

func append_log(string: String) -> void:
	log.add_text(string + "\n")

func recompile_swift() -> void:
	recompile_button.disabled = true
	log.clear()
	status.text = "Preparing..."
	if OS.is_sandboxed():
		recompile_button.disabled = false
		append_log("Sandboxed :()")
		return
	var path = ProjectSettings.globalize_path("res://swift_godot_game")
	var target_dir = ProjectSettings.globalize_path("res://addons/swift_godot_extension/bin")
	if not DirAccess.dir_exists_absolute(target_dir):
		var err = DirAccess.make_dir_recursive_absolute(target_dir)
		if err != OK:
			append_log("Error creating directory '" + target_dir + "'")
			return
		append_log("Building from the scratch. Can take some time. Consequent builds will be much faster.")
		
	var gdignore_path: String = target_dir.path_join(".gdignore")
	append_log("Writing %s" % gdignore_path)
	var file = FileAccess.open(gdignore_path, FileAccess.WRITE)
	if file == null:
		var open_error = FileAccess.get_open_error()
		append_log("Error creating/opening '" + gdignore_path + "'")
		return
	else:
		file.close()
	
	append_log("Building into %s" % target_dir)
	var build_args = ["build", "--package-path", path]	
	var output = []
	var pid := OS.create_process(
		"swift", [
			"build", "--package-path", path, "--build-path", target_dir
		], false)
	if pid == -1:
		status.text = "Awaiting command"
		log.append_text("Couldn't execute `swift build` command")
		return
	var progress_markers = ["˥", "˦", "˧", "˨", "˩", "˨", "˧", "˦"]
	var i = 0
	var start_time = Time.get_ticks_msec()	
	status.text = "Running `swift build`"
	while OS.is_process_running(pid):
		await get_tree().create_timer(0.1).timeout
		var time_passed = (Time.get_ticks_msec() - start_time) / 1000
		status.text = "Compiling %s %s s " % [progress_markers[i], time_passed]
		i = (i + 1) % progress_markers.size()
	status.text = "Done"	
	await get_tree().create_timer(3.0).timeout	
	EditorInterface.restart_editor(false)
