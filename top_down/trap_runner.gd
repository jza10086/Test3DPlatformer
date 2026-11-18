extends ParkourRacer

@export_range(0.1, 5.0) var hit_invulnerability := 1.2
var invulnerability := 0.0
var survival_time := 0.0
var hits := 0

func set_motion_input(movement: Vector2, _mode: StringName = &"Run", _jump := false) -> void:
	super(movement, &"Run", false)

func _physics_process(delta: float) -> void:
	# This room accepts only direction, including inputs injected for other players.
	input_enabled = false
	requested_gait = &"Run"
	sprint_allowed = false
	jump_requested = false
	jump_buffer = 0.0
	if active and not paused:
		survival_time += delta
		invulnerability = maxf(0.0, invulnerability-delta)
		character.visible = invulnerability == 0.0 or fmod(invulnerability,0.16) > 0.08
	super(delta)

func damage(amount: int, lethal: bool) -> bool:
	if not active or paused or invulnerability > 0.0:
		return active
	hits += 1
	health = 0 if lethal else maxi(0,health-amount)
	invulnerability = hit_invulnerability
	if health == 0:
		active = false
		set_paused(true)
		visible = false
		set_deferred("collision_layer",0)
	return active

func reset_round() -> void:
	respawn()
	health = max_health
	hits = 0
	survival_time = 0.0
	invulnerability = 0.0
	visible = true
	character.visible = true
	collision_layer = 2
	active = false
	set_motion_input(Vector2.ZERO)
	set_paused(true)
