extends CanvasLayer

@onready var course: ParkourCourse = get_parent()

func _process(_delta: float) -> void:
	var lines := PackedStringArray(["鱿鱼游戏 · 玻璃桥"])
	match course.phase:
		ParkourCourse.Phase.COUNTDOWN:
			lines.append("准备出发  %d" % ceili(maxf(course.remaining, 0.0)))
		ParkourCourse.Phase.RUNNING:
			lines.append("剩余 %03d 秒    已用 %.2f 秒" % [ceili(maxf(0.0, course.time_limit - course.elapsed)), course.elapsed])
		ParkourCourse.Phase.COMPLETE:
			lines.append("比赛结束 · 最终排名")
	lines.append("已到达终点 %d / %d" % [course.results.size(), course.racers.size()])
	var standings := course.ranked_racers()
	var place := 1
	for i in standings.size():
		var racer := standings[i]
		# Unfinished racers with the same score share their place.
		if i == 0 or racer.rank > 0 or standings[i - 1].rank > 0 or racer.tokens != standings[i - 1].tokens:
			place = i + 1
		var result := "完赛 %.3f 秒 · %d 分" % [racer.finish_time, racer.tokens] if racer.rank > 0 else "未完赛 · %d 分" % racer.tokens
		lines.append("%s 第%d名  %s  %s" % ["▶" if racer == course.racers[course.focused] else "  ", place, racer.name, result])
	lines.append("每块桥面每人 +1 · 坠落回起点 · 碎裂平台全员共享")
	$Panel/Rows/Status.text = "\n".join(lines)

