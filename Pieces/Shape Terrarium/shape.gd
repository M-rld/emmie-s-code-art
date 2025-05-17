extends Node2D

var pos:Vector2i

func GetNeighbor(dir:Vector2i):
	for child in get_parent().get_children():
		if child.pos == self.pos + dir:
			return child

var tickLengthMin := 0.6
var tickLengthMax := 3.0

var shape = SHAPES.SQUARE:
	set(x):
		shape = x
		var textureToLoad:Texture2D
		match x:
			SHAPES.CIRCLE: textureToLoad = preload("res://Pieces/Shape Terrarium/Shapes/circle.svg")
			SHAPES.HEXAGON: textureToLoad = preload("res://Pieces/Shape Terrarium/Shapes/hexagon.svg")
			SHAPES.PENTAGON: textureToLoad = preload("res://Pieces/Shape Terrarium/Shapes/pentagon.svg")
			SHAPES.SQUARE: textureToLoad = preload("res://Pieces/Shape Terrarium/Shapes/square.svg")
			SHAPES.STAR: textureToLoad = preload("res://Pieces/Shape Terrarium/Shapes/star.svg")
			SHAPES.TRIANGLE: textureToLoad = preload("res://Pieces/Shape Terrarium/Shapes/triangle.svg")
		$Anchor/Body.texture = textureToLoad
		$Anchor/Shadow.texture = textureToLoad

@export var COLOR_VALUES:Dictionary[COLORS, Color] = {}
var color = COLORS.WHITE:
	set(x):
		color = x
		self.modulate = COLOR_VALUES[color]

var direction = DIRECTIONS.UP:
	set(x):
		direction = x
		$Anchor/Body.rotation_degrees = x * 90

enum SHAPES {CIRCLE, SQUARE, HEXAGON, PENTAGON, STAR, TRIANGLE}
enum COLORS {WHITE, RED, GREEN, YELLOW, BLUE}
enum DIRECTIONS {UP, RIGHT, DOWN, LEFT, SPINNING}

var transitioning := false

func Tick():
	if transitioning: StartTimer()
	
	if shape == SHAPES.SQUARE and direction == DIRECTIONS.SPINNING:
		tickLengthMax = min(tickLengthMax, 0.5)
		tickLengthMin = tickLengthMax
	else:
		tickLengthMax = 3.0
		tickLengthMin = 0.6
	
	match shape:
		SHAPES.PENTAGON:
			if direction != DIRECTIONS.SPINNING: 
				StartTimer()
				return
			
			if color != COLORS.WHITE:
				TransitionColor(COLORS.WHITE)
			
			tickLengthMax = 3.0 - get_parent().spinningPentagonsAmount * 0.1
			tickLengthMax = clamp(tickLengthMax, 0.05, 3.0)
			tickLengthMin = tickLengthMax
			
			for neighbor in GetEightNeighborhood():
				if neighbor:
					if neighbor.shape != SHAPES.PENTAGON or neighbor.direction != DIRECTIONS.SPINNING:
						if randi() % 100 < get_parent().spinningPentagonsAmount:
							neighbor.TransitionShape(SHAPES.PENTAGON, true)
							neighbor.TransitionColor(COLORS.WHITE)
							neighbor.TransitionDirection(DIRECTIONS.SPINNING)
							PlaySound("bidit", 1.0 + 0.02 * get_parent().spinningPentagonsAmount)
		
		SHAPES.HEXAGON:
			tickLengthMax = 0.4
			tickLengthMin = 0.4
			
			var hexagonNeighbors := 0
			var lowerColors := []
			for neighbor in GetEightNeighborhood():
				if neighbor:
					if neighbor.shape == SHAPES.HEXAGON:
						hexagonNeighbors += 1
						if neighbor.color < color:
							lowerColors.append(neighbor)
			
			if lowerColors.size() == 1:
				var otherHexagon = lowerColors[0]
				var otherSide = GetNeighbor(-1 * (otherHexagon.pos - self.pos))
				
				if not otherSide or randi() % 100 < 6:
					var nextPos = -1 * (otherHexagon.pos - self.pos)
					if randi() % 2 == 0:
						nextPos = Vector2i(Vector2(nextPos).rotated(deg_to_rad(90)))
					else:
						nextPos = Vector2i(Vector2(nextPos).rotated(deg_to_rad(-90)))
					
					otherSide = GetNeighbor(nextPos)
					
					if otherSide: PlaySound("ieu")
				
				if otherSide:
					var savedColor = color
					otherHexagon.Swap(otherSide)
					TransitionColor(otherSide.color)
					otherSide.TransitionColor(savedColor)
					PlaySound("oa", randf_range(0.8, 1.1))
			
			
			for i in GetEightNeighborhood():
				if i:
					if i.shape != SHAPES.HEXAGON and randi() % 1000 < 5 and hexagonNeighbors == 0 and i.color != color:
						i.TransitionShape(SHAPES.HEXAGON, false, "dit", true)
		
		SHAPES.CIRCLE:
			var sameColorCount := 0
			for neighbor in GetEightNeighborhood():
				if neighbor:
					if neighbor.color == color:
						sameColorCount += 1
			if sameColorCount >= 4 and randi() % 100 < 20:
				CircleSpread()
		
		SHAPES.SQUARE:
			if direction == DIRECTIONS.SPINNING:
				PlaySound("hwa", randf_range(0.5, 0.7))
				tickLengthMax -= 0.03
				tickLengthMin -= 0.03
				if tickLengthMax <= 0.0 or tickLengthMin <= 0.0:
					PlaySound("alk")
					PlaySound("kwaow")
					for cell in get_parent().get_children():
						cell.DoShockwave(self.pos)
					for x in range(-2, 3):
						for y in range(-2, 3):
							var neighbor = GetNeighbor(Vector2(x,y))
							if neighbor:
								neighbor.TurnRandom()
					TransitionDirection(DIRECTIONS.UP)
				else:
					TransitionColor((color + 1) % 5)
			
			var squareNeighbors := 0
			for i in GetEightNeighborhood():
				if i:
					if i.shape == SHAPES.SQUARE:
						squareNeighbors += 1
					elif randi() % 50 == 0:
						if not i.transitioning and i.shape != SHAPES.TRIANGLE:
							i.TransitionShape(SHAPES.SQUARE, false, "dit", true)
			
			if randi() % 100 == 0 and color == COLORS.WHITE and direction != DIRECTIONS.SPINNING:
				if squareNeighbors >= 4 and get_parent().spinningSquaresAmount == 0:
					PlaySound("phlk")
					tickLengthMax = 0.5
					tickLengthMin = 0.5
					TransitionDirection(DIRECTIONS.SPINNING)
		
		SHAPES.TRIANGLE:
			tickLengthMax = 3.0
			tickLengthMin = 1.0
			
			if color == COLORS.BLUE:
				tickLengthMax = 0.5
				tickLengthMin = 0.1
			
			var roll := randi() % 100
			if roll < 10:
				self.TransitionDirection(posmod(direction - 1, 4))
			elif roll < 20:
				self.TransitionDirection(posmod(direction + 1, 4))
			elif roll < 50:
				var neighborTry = GetNeighbor(FacingToDir(direction))
				if neighborTry:
					Swap(neighborTry)
				elif color != COLORS.BLUE:
					var leftNeighbor = GetNeighbor(FacingToDir(posmod(direction - 1, 4)))
					var rightNeighbor = GetNeighbor(FacingToDir(posmod(direction + 1, 4)))
					if leftNeighbor: 
						leftNeighbor.TransitionShape(SHAPES.TRIANGLE, true)
						PlaySound("ping", NOTES_SCALE.pick_random())
					if rightNeighbor: 
						rightNeighbor.TransitionShape(SHAPES.TRIANGLE, true)
						PlaySound("ping", NOTES_SCALE.pick_random())
			
			if roll <= 50:
				PlaySound("flick", randf_range(0.8, 1.4))
	
	StartTimer()

func StartTimer():
	$Timer.start(randf_range(tickLengthMin, tickLengthMax))

var shapeTween:Tween
func TransitionShape(to:SHAPES, instant := false, sound := "", triggerStars:=false):
	if shape == SHAPES.PENTAGON and direction == DIRECTIONS.SPINNING:
		return
	if shape == SHAPES.PENTAGON and get_parent().shapesAmount[SHAPES.PENTAGON] == 1:
		PlaySound("alk", 0.5)
		TransitionColor(COLORS.WHITE)
		TransitionDirection(DIRECTIONS.SPINNING)
		return
	
	transitioning = true
	if shapeTween: shapeTween.kill()
	shapeTween = get_tree().create_tween()
	
	tickLengthMax = 3.0
	tickLengthMin = 0.6
	
	if not instant:
		shapeTween.tween_property(self, "scale", Vector2(0.8, 0.8), 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if sound.length() > 0:
		shapeTween.tween_callback(PlaySound.bind(sound))
	if not instant and shape == SHAPES.STAR and triggerStars:
		var starsInNeighborHood := []
		for i in GetEightNeighborhood():
			if i:
				if i.shape == SHAPES.STAR:
					starsInNeighborHood.append(i)
		
		if starsInNeighborHood.size() == 0:
			shapeTween.tween_callback(StarExplosion)
		else:
			shapeTween.tween_callback(StarMutation.bind(starsInNeighborHood.pick_random()))
	
	shapeTween.tween_callback(CallbackSet.bind("shape", to))
	shapeTween.tween_property(self, "scale", Vector2(1, 1), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).from(Vector2(0.8,0.8))
	shapeTween.tween_callback(CallbackSet.bind("transitioning", false))

func StarMutation(target):
	target.TransitionColor(randi() % 5)
	PlaySound("wwmb")

func StarExplosion():
	PlaySound("alk", 1.4)
	PlaySound("kwaow", 1.4)
	for cell in get_parent().get_children():
		cell.DoShockwave(self.pos, 0.3)
	for x in range(-2, 3):
		for y in range(-2, 3):
			var neighbor = GetNeighbor(Vector2(x,y))
			if neighbor:
				if randi() % 100 < 80:
					neighbor.DelayedTransition(
						Vector2(neighbor.pos).distance_to(Vector2(self.pos)) / 10.0,
						null,
						color,
						null,
						"flick"
					)
				if randi() % 100 < 50:
					neighbor.DelayedTransition(
						randf_range(0.0, 2.0),
						SHAPES.STAR,
						null,
						null, 
						"ping"
					)

var colorTween:Tween 
func TransitionColor(to:COLORS):
	#transitioning = true
	if colorTween: colorTween.kill()
	colorTween = get_tree().create_tween()
	color = to
	
	$Anchor/Body.position = Vector2(0, -10)
	$Anchor/Body.scale = Vector2(0.4, 0.4)
	
	colorTween.set_parallel(true)
	colorTween.tween_property($Anchor/Body, "scale", Vector2(0.3, 0.3), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	colorTween.tween_property($Anchor/Body, "position", Vector2.ZERO, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	#colorTween.tween_callback(CallbackSet.bind("transitioning", false)).set_delay(0.8)

var alternate := 1
var directionTween:Tween
func TransitionDirection(to:DIRECTIONS):
	#transitioning = true
	if directionTween: directionTween.kill()
	directionTween = get_tree().create_tween()
	
	$Anchor.scale = Vector2(0.8, 0.8)
	
	alternate *= -1
	self.rotation = deg_to_rad(randf_range(20, 40)) * alternate
	direction = to
	directionTween.set_parallel(true)
	directionTween.tween_property(self, "rotation", 0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	directionTween.tween_property($Anchor, "scale", Vector2(1, 1), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	# directionTween.tween_callback(CallbackSet.bind("transitioning", false)).set_delay(0.8)

func FacingToDir(facing:DIRECTIONS) -> Vector2i:
	match facing:
		DIRECTIONS.UP: return Vector2i.UP
		DIRECTIONS.RIGHT: return Vector2i.RIGHT
		DIRECTIONS.DOWN: return Vector2i.DOWN
		DIRECTIONS.LEFT: return Vector2i.LEFT
	return Vector2i.ZERO

const EIGHT_NEIGHBORHOOD = [
	Vector2i(1,0),
	Vector2i(1,1),
	Vector2i(0,1),
	Vector2i(-1,1),
	Vector2i(-1,-1),
	Vector2i(0,-1),
	Vector2i(1,-1),
	Vector2i(-1,0)
]
func GetEightNeighborhood() -> Array:
	var toReturn := []
	for i in EIGHT_NEIGHBORHOOD:
		toReturn.append(GetNeighbor(i))
	return toReturn

func Swap(other:Node):
	if not other: return
	var newDir = other.direction
	var newColor = other.color
	var newShape = other.shape
	other.TransitionDirection(self.direction)
	other.TransitionShape(self.shape, true)
	other.TransitionColor(self.color)
	self.TransitionDirection(newDir)
	self.TransitionShape(newShape, true)
	self.TransitionColor(newColor)

var shockwaveTween:Tween
func DoShockwave(from:Vector2i, power := 1.0):
	if from == self.pos: return
	
	if shockwaveTween: shockwaveTween.kill()
	shockwaveTween = get_tree().create_tween()
	var delay = Vector2(from).distance_to(self.pos) / 10.0
	var falloff = 1 / Vector2(from).distance_to(self.pos)
	
	shockwaveTween.tween_property(
		$Anchor, "position", Vector2(self.pos - from).normalized() * 30 * falloff * power, 0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(delay)
	shockwaveTween.tween_property($Anchor, "position", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUART)

const NOTES_SCALE = [1.0, 1.2599388379, 1.4984709480, 1.8876146789, 2.2454128440]

func DelayedTransition(delay:float, targetShape=null, targetColor=null, targetDirection=null, soundName="", circleSpread:=false):
	transitioning = true
	var newTimer := get_tree().create_timer(delay)
	newTimer.timeout.connect(
		func():
			if targetShape != null: self.TransitionShape(targetShape, true)
			if targetColor != null: self.TransitionColor(targetColor)
			if targetDirection != null: self.TransitionDirection(targetDirection)
			if soundName.length() > 0: self.PlaySound(soundName, NOTES_SCALE.pick_random())
			
			if circleSpread:
				for neighbor in self.GetEightNeighborhood():
					if neighbor:
						if neighbor.color == self.color and neighbor.shape != SHAPES.CIRCLE:
							if neighbor.shape != SHAPES.PENTAGON and neighbor.direction != DIRECTIONS.SPINNING:
								neighbor.CircleSpread()
			
			self.transitioning = false 
	)

func CircleSpread():
	DelayedTransition(
		randf_range(0.2, 1.0),
		SHAPES.CIRCLE,
		null,
		null,
		"bluh",
		true
	)

func TurnRandom():
	DelayedTransition(
		randf_range(0.0, 2.0),
		randi() % 6,
		randi() % 5,
		null,
		"ping"
	)

func CallbackSet(type:String, value:Variant):
	match type:
		"transitioning": 
			transitioning = value
			if not value:
				$Timer.start(randf_range(tickLengthMin, tickLengthMax))
		"shape": 
			shape = value
			if shape == SHAPES.HEXAGON:
				tickLengthMax = 0.4
				tickLengthMin = 0.4
			$Timer.start(0.4)
		"color": color = value
		"direction": direction = value

func _process(delta):
	if direction == DIRECTIONS.SPINNING:
		$Anchor/Body.rotation_degrees += abs(6 * sin(Time.get_ticks_msec() / 1000.0 * 4)) - 1
	
	$Anchor/Shadow.scale = $Anchor/Body.scale
	$Anchor/Shadow.skew = $Anchor/Body.skew
	$Anchor/Shadow.rotation = $Anchor/Body.rotation
	$Anchor/Shadow.modulate = $Anchor/Body.modulate
	$Anchor/Shadow.position = $Anchor/Body.position + Vector2(6,6)

func PlaySound(soundName:String, pitch := 1.0):
	var newSound := AudioStreamPlayer2D.new()
	newSound.stream = load("res://Pieces/Shape Terrarium/Sounds/" + soundName + ".wav")
	newSound.pitch_scale = pitch
	self.add_child(newSound)
	newSound.play()
	newSound.finished.connect(RemoveSoundPlayer.bind(newSound))

func RemoveSoundPlayer(node:AudioStreamPlayer2D):
	node.queue_free()
