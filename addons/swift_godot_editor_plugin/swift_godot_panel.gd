@tool
extends VBoxContainer

const MARGIN = 16

@onready var recompile_button := Button.new()
@onready var log_label := Label.new()
@onready var log := RichTextLabel.new()

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
	
	log_label.text = "Log:"
	add_child(log_label)
		
	log.scroll_following = true
	log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(log)

func append_log(string: String) -> void:
	log.add_text(string)

func recompile_swift() -> void:
	recompile_button.disabled = true
	log.clear()
	if OS.is_sandboxed():
		recompile_button.disabled = false
		printerr("Sandboxed :()")
		return
	var path = ProjectSettings.globalize_path("res://swift_godot_game")
	var target_dir = ProjectSettings.globalize_path("res://addons/swift_godot_extension/bin")
	if not DirAccess.dir_exists_absolute(target_dir):
		var err = DirAccess.make_dir_recursive_absolute(target_dir)
		if err != OK:
			append_log("Error creating directory '" + target_dir + "'")
			return
	
	var gdignore_path: String = target_dir.path_join(".gdignore")
	var file = FileAccess.open(gdignore_path, FileAccess.WRITE)
	if file == null:
		var open_error = FileAccess.get_open_error()
		append_log("Error creating/opening '" + gdignore_path + "'")
		return
	else:
		file.close()
	
	var build_args = ["build", "--package-path", path]	
	var output = []
	var dictionary = OS.execute_with_pipe(
		"swift", [
			"build", "--package-path", path, "--build-path", target_dir
		], false)
	if dictionary.is_empty():
		recompile_button.disabled = false
		return
	var stdio: FileAccess = dictionary["stdio"]
	var pid: int = dictionary["pid"]
	var progress_markers = ["/", "-", "\\", "|"]
	var i = 0	
	while OS.is_process_running(pid):
		await get_tree().create_timer(0.1).timeout
		log.text = "Compiling " + progress_markers[i]
		i = (i + 1) % progress_markers.size()	
	append_log(stdio.get_as_text())
	append_log("Relaunching in 3 seconds")
	await get_tree().create_timer(3.0).timeout
	var project_path = ProjectSettings.globalize_path("res://")
	var arguments = ["--path", project_path, "--editor"]
	var editor_exec_path = OS.get_executable_path()	
	OS.execute(editor_exec_path, arguments)
	get_tree().call_deferred("quit", 0)
