extends Control

func _on_resized():
	if($top.size.x > 0 && $left.size.y > 0):
		var window = get_viewport_rect().size
		$top/Top/Top.shape.b.x = -window.x
		$left/Left/Left.shape.b.x = window.y
		$right/Right/Right.shape.b.x = -window.y
		$bottom/Bottom/Bottom.shape.b.x = window.x
