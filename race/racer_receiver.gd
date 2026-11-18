extends ParkourEffectReceiver

@onready var racer: ParkourRacer = get_parent()

func is_active() -> bool:
	return racer.active

func launch(direction: Vector3, speed: float) -> void:
	racer.launch(direction, speed)

func damage(amount: int, lethal: bool) -> bool:
	return racer.damage(amount, lethal)

func collect_token() -> void:
	racer.tokens += 1
