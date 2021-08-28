extends TileObject

export var MapPath : NodePath
export var TrailPath : NodePath
export var GoalPath : NodePath

onready var Map : TileMap = get_node(MapPath) 
onready var Trail : Line2D = get_node(TrailPath)
onready var Goal : Sprite = get_node(GoalPath)

var is_moving = false
var dash_speed = 1
var last_direction = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func dash(x,y, speed = 1, chain = false):
	var direction = Vector2(x,y).normalized()
	# If a wall is directly in front of the player, return
	if Map.get_cellv(pos) & Map.cell_walls[direction]:
		return
	
	is_moving = true
	speed = min(speed, 3)
	# Adjust the position of the trail to always be in the center of the tile
	if(last_direction == -direction or Trail.get_point_count() == 1):
		Trail.set_point_position(Trail.get_point_count()-1, position - direction * Trail.width/2)
		
	Trail.add_point(position)
	
	# Keep going forward until there's an intersection
	var tile_count = 1
	while not Map.get_cellv(pos) & Map.cell_walls[direction] :
		pos += direction
		tile_count += 1
		if Map.opening_count(Map.get_cellv(pos)) > 2:
			break
	var next_pos = pos*Map.tile_size+(get_rect().size/8)
	
	# Interpolate between the current position and the next position
	# If the player is chaining multiple dashes, change the interpolation type
	if chain:
		$TrailTween.interpolate_property(self, "position", position, next_pos, 0.08/speed*tile_count, Tween.TRANS_LINEAR)
	else:
		$TrailTween.interpolate_property(self, "position", position, next_pos, 0.08/speed*tile_count, Tween.TRANS_CUBIC)
	$TrailTween.start()
	yield($TrailTween, "tween_all_completed")
	last_direction = direction
	
	# If the player is on the goal, exit and restart
	if(pos == Goal.pos):
		get_owner().restart()
		dash_speed = 1
		last_direction = Vector2(-1,0)
		is_moving = false
		return
	
	# If the player has only one other way to go, dash in that direction
	if (Map.opening_count(Map.get_cellv(pos)) == 2 and speed > 0.5):
		var next_dir = binary_to_vector2(Map.get_cellv(pos) ^ vector2_to_binary(direction))
		dash_speed += 0.2
		dash(next_dir.x, next_dir.y, dash_speed, true)
		return
	
	dash_speed = 1
	is_moving = false
	

func vector2_to_binary(vector : Vector2):
	vector = vector.normalized()
	match vector:
		Vector2(-1,0):
			return 0b1000
		Vector2(1,0):
			return 0b0010
		Vector2(0,-1):
			return 0b0001
		Vector2(0,1):
			return 0b0100

func binary_to_vector2(bin : int):
	match bin:
		0b1000:
			return Vector2(1,0)
		0b0010:
			return Vector2(-1,0)
		0b0001:
			return Vector2(0,1)
		0b0100:
			return Vector2(0,-1)
