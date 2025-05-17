extends Node2D

func _ready():
	RenderingServer.set_default_clear_color(Color.WHITE)
	var shape := $Shape
	self.remove_child(shape)
	for x in 8:
		for y in 8:
			var newShape := shape.duplicate()
			newShape.position = Vector2(x*90+80, y*90+80)
			newShape.pos = Vector2i(x,y)
			self.add_child(newShape)
	for child in self.get_children():
		child.get_node("Timer").start(0)

var shapesAmount := {}
var spinningPentagonsAmount := 0
var spinningSquaresAmount := 0
func _process(delta):
	shapesAmount = {
		0: 0,
		1: 0,
		2: 0,
		3: 0,
		4: 0,
		5: 0
	}
	spinningPentagonsAmount = 0
	spinningSquaresAmount = 0
	for child in self.get_children():
		shapesAmount[child.shape] += 1
		if child.shape == 3 and child.direction == 4:
			spinningPentagonsAmount += 1
		if child.shape == 1 and child.direction == 4:
			spinningSquaresAmount += 1
	
