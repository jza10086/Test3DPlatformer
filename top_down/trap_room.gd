extends Node3D

const Runner = preload("res://games/minigame/GP_test_3d_platformer/top_down/trap_runner.gd")
const RUNNER_SCENE := preload("res://games/minigame/GP_test_3d_platformer/top_down/trap_runner.tscn")
const SAW_SCENE := preload("res://games/assets/GP_platformer_3d_components/top_down/saw_bomb.tscn")
enum Phase { COUNTDOWN, RUNNING, COMPLETE }

@export_range(1, 4) var player_count := 1
## Exactly one local keyboard supplies WASD; additional entities accept set_motion_input.
@export_range(0, 3) var keyboard_player_index := 0
@export_range(0.1, 15.0) var run_speed := 4.3
@export_range(1, 20) var player_health := 3
@export_range(0.1, 5.0) var hit_invulnerability := 1.2
@export_range(0.0, 10.0) var countdown_seconds := 3.0
@export_range(10.0, 600.0) var round_seconds := 300.0
@export var auto_restart := true
@export_range(1.0, 15.0) var restart_seconds := 5.0
@export_group("Attacks")
@export_range(0.5, 20.0) var cannon_interval := 3.2
@export_range(0.5, 20.0) var missile_interval := 7.0
@export_range(0.5, 20.0) var saw_interval := 5.0
## Raise attack frequency gradually; telegraph duration and projectile speed stay fixed.
@export_range(1.0, 3.0) var final_frequency_multiplier := 1.6

var racers: Array[Runner] = []
var view: StandardViewRig
var phase := Phase.COUNTDOWN
var remaining := 0.0
var elapsed := 0.0
var cannon_clock := 0.0
var missile_clock := 0.0
var saw_clock := 0.0
var cannon_index := 0
var missile_index := 0
var target_index := 0
var saw_count := 0

const PreviewInput = preload("res://games/minigame/GP_test_3d_platformer/preview_input.gd")
var preview_input: PreviewInput = PreviewInput.new()

func _enter_tree() -> void:
	if get_parent() == get_tree().root:
		preview_input.install()

func _exit_tree() -> void:
	preview_input.restore()

signal map_finished(elapsed_seconds: float)
var party_input: PartyInput

func _ready() -> void:
	assert(keyboard_player_index < player_count, "Keyboard player must be among the room entrants")
	process_physics_priority = -100
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for i in player_count:
		var runner: Runner = RUNNER_SCENE.instantiate()
		runner.name = "P%d" % (i+1)
		runner.position = $StartGrid.get_child(i).position
		runner.max_health = player_health
		runner.hit_invulnerability = hit_invulnerability
		$Players.add_child(runner)
		runner.run_speed = run_speed
		runner.walk_speed = run_speed
		runner.sprint_speed = run_speed
		runner.input_enabled = false
		runner.get_node("Nameplate").text = runner.name
		racers.append(runner)
	view = StandardViewRig.new()
	view.name = "ViewRig"
	view.actor = racers[keyboard_player_index]
	view.initial_view = StandardViewRig.View.TOP_DOWN
	view.mouse_facing = false
	add_child(view)
	# Reuse the character's perspective follow camera and camera preset, while this
	# room keeps its WASD-only controls (no mouse aiming, zoom or view switching).
	view.set_process_input(false)
	view.set_process_unhandled_input(false)
	start_round()

func start_round() -> void:
	phase = Phase.COUNTDOWN
	remaining = countdown_seconds
	elapsed = 0.0
	cannon_clock = 1.0
	missile_clock = 5.0
	saw_clock = 8.0
	cannon_index = 0
	missile_index = 0
	target_index = 0
	saw_count = 0
	$Emitters.process_mode = Node.PROCESS_MODE_DISABLED
	$Lasers.process_mode = Node.PROCESS_MODE_DISABLED
	for shot in $Attacks.get_children():
		shot.free()
	for emitter in $Emitters.get_children():
		emitter.reset()
	for laser in $Lasers.get_children():
		laser.reset()
	for runner in racers:
		runner.reset_round()
	update_hud()

func living_racers() -> Array[Runner]:
	var living: Array[Runner] = []
	for runner in racers:
		if runner.active:
			living.append(runner)
	return living

func next_target(living: Array[Runner]) -> Runner:
	var runner := living[target_index % living.size()]
	target_index += 1
	return runner

func _physics_process(delta: float) -> void:
	match phase:
		Phase.COUNTDOWN:
			remaining -= delta
			if remaining <= 0.0:
				phase = Phase.RUNNING
				for runner in racers:
					runner.active = true
					runner.set_paused(false)
				$Emitters.process_mode = Node.PROCESS_MODE_INHERIT
				$Lasers.process_mode = Node.PROCESS_MODE_INHERIT
		Phase.RUNNING:
			var living := living_racers()
			if living.is_empty() or elapsed >= round_seconds:
				end_round()
			else:
				var movement := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
				racers[keyboard_player_index].set_motion_input(Vector2.ZERO if party_input != null and party_input.input_blocked else movement)
				elapsed = minf(round_seconds,elapsed+delta)
				var frequency := lerpf(1.0,final_frequency_multiplier,elapsed/round_seconds)
				cannon_clock -= delta*frequency
				missile_clock -= delta*frequency
				saw_clock -= delta*frequency
				if cannon_clock <= 0.0:
					var cannon: Node3D = $Emitters.get_child(cannon_index % 4)
					cannon.arm(next_target(living).receiver)
					cannon_index += 1
					cannon_clock += cannon_interval
				if missile_clock <= 0.0:
					var missile: Node3D = $Emitters.get_child(4+missile_index % 2)
					missile.arm(next_target(living).receiver)
					missile_index += 1
					missile_clock += missile_interval
				if saw_clock <= 0.0:
					var saw := SAW_SCENE.instantiate()
					# Lock the marked floor position now; the target can run out before impact.
					saw.position = $Attacks.to_local(next_target(living).global_position)
					saw.position.y = 0.0
					$Attacks.add_child(saw)
					saw_count += 1
					saw_clock += saw_interval
		Phase.COMPLETE:
			if auto_restart:
				remaining -= delta
				if remaining <= 0.0:
					start_round()
	update_hud()

func end_round() -> void:
	phase = Phase.COMPLETE
	remaining = restart_seconds
	$Emitters.process_mode = Node.PROCESS_MODE_DISABLED
	$Lasers.process_mode = Node.PROCESS_MODE_DISABLED
	for shot in $Attacks.get_children():
		shot.queue_free()
	for laser in $Lasers.get_children():
		laser.reset()
	for emitter in $Emitters.get_children():
		emitter.reset()
	for runner in racers:
		runner.set_paused(true)
		runner.character.visible = true

	map_finished.emit(elapsed)

func standings() -> Array[Runner]:
	var ordered := racers.duplicate()
	ordered.sort_custom(func(a: Runner,b: Runner) -> bool:
		if a.active != b.active: return a.active
		if not a.active and not is_equal_approx(a.survival_time,b.survival_time): return a.survival_time > b.survival_time
		return a.health > b.health if a.health != b.health else a.get_index() < b.get_index())
	return ordered

func update_hud() -> void:
	var status := "准备 %d" % ceili(maxf(0.0,remaining))
	if phase == Phase.RUNNING:
		var seconds := ceili(maxf(0.0,round_seconds-elapsed))
		status = "剩余 %02d:%02d · 存活 %d/%d" % [seconds/60,seconds%60,living_racers().size(),racers.size()]
	elif phase == Phase.COMPLETE:
		status = "回合结束" + (" · %d 秒后重开" % ceili(maxf(0.0,remaining)) if auto_restart else "")
	$HUD/Panel/Rows/Status.text = "陷阱房 · 俯视生存\n"+status
	var lines := PackedStringArray()
	for runner in standings():
		lines.append("%s  %s  %.1fs" % [runner.name,"生命 %d" % runner.health if runner.health > 0 else "已淘汰",runner.survival_time])
	$HUD/Panel/Rows/Players.text = "\n".join(lines)
