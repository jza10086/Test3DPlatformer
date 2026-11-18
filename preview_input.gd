extends RefCounted

## Standalone map previews use the input bindings supplied with the source project.
var added_actions: Array[StringName] = []

func install() -> void:
	var config: ConfigFile = ConfigFile.new()
	var status: Error = config.load("res://games/minigame/GP_test_3d_platformer/preview_input.cfg")
	assert(status == OK, error_string(status))
	for action: String in config.get_section_keys("input"):
		if InputMap.has_action(action):
			continue
		var binding: Dictionary = config.get_value("input", action)
		InputMap.add_action(action, binding.deadzone)
		added_actions.append(action)
		for event: InputEvent in binding.events:
			InputMap.action_add_event(action, event)

func restore() -> void:
	for action: StringName in added_actions:
		InputMap.erase_action(action)
	added_actions.clear()
