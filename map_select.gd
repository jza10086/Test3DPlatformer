extends Node3D

signal completed(metrics: Dictionary)
const TrapRoom = preload("top_down/trap_room.gd")
const MapInputs = preload("preview_input.gd")
@export var maps: Dictionary[String, String]
var bindings: MapInputs = MapInputs.new()
var party_input: PartyInput
var active_map: Node3D
var playing: bool = false
var controls_blocked: bool = false

func solo_setup(input: PartyInput, _text: RefCounted) -> void:
	party_input = input

func _ready() -> void:
	for title: String in maps:
		%Map.add_item(title)
	%Start.pressed.connect(_start_map)
	$Menu.visible = party_input == null

func solo_start() -> void:
	$Menu.show()

func _start_map() -> void:
	if party_input != null and party_input.input_blocked:
		return
	var scene: PackedScene = load(maps[%Map.get_item_text(%Map.selected)])
	active_map = scene.instantiate()
	if active_map is ParkourCourse:
		var course: ParkourCourse = active_map
		course.party_input = party_input
		course.player_count = 1
	else:
		var room: TrapRoom = active_map
		room.party_input = party_input
		room.player_count = 1
		room.auto_restart = false
	active_map.connect(&"map_finished", _finished, CONNECT_ONE_SHOT)
	bindings.install()
	$Menu.hide()
	add_child(active_map)
	playing = true

func _process(_delta: float) -> void:
	if not playing or party_input == null or controls_blocked == party_input.input_blocked:
		return
	controls_blocked = party_input.input_blocked
	if active_map is ParkourCourse:
		var course: ParkourCourse = active_map
		course.view.set_process_unhandled_input(not controls_blocked)
		if controls_blocked:
			course.view.suspend_controls()
		else:
			course.view.resume_controls()

func _finished(seconds: float) -> void:
	if party_input == null:
		solo_stop()
		$Menu.show()
	else:
		completed.emit({"time": roundi(seconds * 1000.0)})

func solo_stop() -> void:
	playing = false
	if is_instance_valid(active_map):
		active_map.process_mode = Node.PROCESS_MODE_DISABLED
		active_map.queue_free()
		active_map = null
	bindings.restore()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exit_tree() -> void:
	bindings.restore()

func solo_graphics_targets() -> Dictionary:
	if not is_instance_valid(active_map):
		return {}
	return {"world": active_map.find_children("*", "WorldEnvironment", true, false).front(),
		"sun": active_map.find_children("*", "DirectionalLight3D", true, false).front()}

func solo_audio_target() -> PartyGameAudio:
	return null
