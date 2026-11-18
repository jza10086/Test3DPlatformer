class_name ParkourRacer
extends StandardPlayerActor

const IcePlatform = preload("res://games/assets/GP_platformer_3d_components/obstacles/ice_platform.gd")
const OneShotPlatform = preload("res://games/assets/GP_platformer_3d_components/obstacles/one_shot_platform.gd")
const SeesawPlatform = preload("res://games/assets/GP_platformer_3d_components/obstacles/seesaw_platform.gd")
const PlatformScore = preload("res://games/assets/GP_platformer_3d_components/items/platform_score.gd")

@export_range(1, 20) var max_health := 3
@onready var receiver: ParkourEffectReceiver = $ParkourReceiver
var health: int
var tokens := 0
var checkpoint_count := 0
var rank := 0
var finish_time := 0.0
var active := false
var previous_position: Vector3
var _previous_surfaces: Array[Node] = []
var _ground_grip := 1.0

func _ready() -> void:
	super()
	health = max_health
	respawned.connect(_reset_after_fall)
	previous_position = global_position

func _reset_after_fall() -> void:
	health = max_health
	jump_requested = false
	previous_position = global_position
	_previous_surfaces.clear()
	_ground_grip = 1.0

func integrate_horizontal(current: Vector2, target: Vector2, grounded: bool, delta: float) -> Vector2:
	# The base integrator multiplies each ground acceleration by this time step.
	return super(current, target, grounded, delta * _ground_grip if grounded else delta)

func _physics_process(delta: float) -> void:
	previous_position = global_position
	super(delta)
	if not active:
		return
	_ground_grip = 1.0
	var contacts: Array[Node] = []
	var collisions: Array[KinematicCollision3D] = []
	for i in get_slide_collision_count():
		collisions.append(get_slide_collision(i))
	# Floor snapping can keep an idle racer grounded without a slide collision.
	# A test-only sweep also finds support at capsule edges without moving the racer.
	if is_on_floor():
		var support := move_and_collide(-up_direction * 0.03, true)
		if support:
			collisions.append(support)
	for hit in collisions:
		for j in hit.get_collision_count():
			var body := hit.get_collider(j) as Node3D
			var normal := hit.get_normal(j)
			if normal.dot(up_direction) >= cos(floor_max_angle):
				if body.is_in_group(&"parkour_scoring_platform") and normal.dot(body.global_basis.y.normalized()) > 0.7:
					var score: PlatformScore = body.get_node("Score")
					score.collect(receiver)
				if body is IcePlatform:
					_ground_grip = minf(_ground_grip, body.friction)
				elif body is OneShotPlatform and normal.dot(body.global_basis.y.normalized()) > 0.7:
					body.stepped_on()
					if body.collision.disabled:
						lose_ground_support()
				elif body is SeesawPlatform and normal.dot(body.global_basis.y.normalized()) > 0.7:
					body.report_support(get_instance_id(), global_position)
			if not body.is_in_group(&"parkour_effect_surface"):
				continue
			var surface: ParkourSurface = body.get_node("SurfaceEffect")
			if not surface.accepts(hit.get_normal(j)) or surface in contacts:
				continue
			contacts.append(surface)
			if surface not in _previous_surfaces:
				var alive := surface.effect.apply(receiver, body.global_basis)
				if not alive:
					return
	_previous_surfaces = contacts

func damage(amount: int, lethal: bool) -> bool:
	health = 0 if lethal else maxi(0, health - amount)
	if health == 0:
		respawn()
		return false
	return true
