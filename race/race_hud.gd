extends CanvasLayer

@onready var course: ParkourCourse = get_parent()

func _process(_delta: float) -> void:
	var racer := course.racers[course.focused]
	var lines := PackedStringArray([course.course_title])
	match course.phase:
		ParkourCourse.Phase.COUNTDOWN:
			lines.append("准备出发   %d" % ceili(course.remaining))
		ParkourCourse.Phase.RUNNING:
			lines.append("已用 %06.2f s" % course.elapsed)
			if course.time_limit > 0.0:
				lines.append("剩余 %d 秒" % ceili(maxf(0.0, course.time_limit - course.elapsed)))
		ParkourCourse.Phase.COMPLETE:
			lines.append("比赛结束")
	var slots := course.racers.size() if course.qualification_slots == 0 else mini(course.qualification_slots, course.racers.size())
	lines.append("已冲线 %d / %d    晋级名额 %d" % [course.results.size(), course.racers.size(), slots])
	for entrant in course.racers:
		var status := "过点 %d/%d   HP %d   道具 %d" % [entrant.checkpoint_count, course.checkpoints.size(), entrant.health, entrant.tokens]
		if entrant.rank > 0:
			status = "第 %d 名    %.3f s" % [entrant.rank, entrant.finish_time]
		elif course.phase == ParkourCourse.Phase.COMPLETE:
			status = "未完赛"
		lines.append("%s %s    %s" % ["▶" if racer == entrant else "  ", entrant.name, status])
	var item := course.nearest_item(racer)
	if item:
		lines.append("E  ·  " + item.prompt)
	$Panel/Rows/Status.text = "\n".join(lines)
