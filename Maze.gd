extends TileMap
class_name Maze

signal generation_done

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {Vector2(1, 0): E, Vector2(-1, 0): W,
				Vector2(0, 1): S, Vector2(0, -1): N}

var generation_done = false
var map_seed = 0
var tile_size = 64  # tile size (in pixels)
var width = 18  # width of map (in tiles)
var height = 32  # height of map (in tiles)
onready var Background = $ViewportContainer/Viewport/Background

func _init():
	pass

func opening_count(tile):
	var p = tile
	var nb_openings = 4
	while p:
		nb_openings -= p & 1
		p = p >> 1
		
	return nb_openings

func check_neighbors(cell, unvisited):
	# returns an array of cell's unvisited neighbors
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list


func make_maze(speed = 1):
	generation_done = false
	var unvisited = []  # array of unvisited tiles
	var stack = []
	# fill the map with solid tiles
	clear()
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2(x, y))
			set_cellv(Vector2(x, y), N|E|S|W)
	var current = Vector2(0, 0)
	unvisited.erase(current)
	
	var step_counter = 0
	var skip_speed = 40
	while unvisited:
		step_counter += 1
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			# remove walls from *both* cells
			var dir = next - current
			var current_walls = get_cellv(current) - cell_walls[dir]
			var next_walls = get_cellv(next) - cell_walls[-dir]
			set_cellv(current, current_walls)
			set_cellv(next, next_walls)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()
		if(step_counter%int(skip_speed*speed) == 0):
			yield(get_tree(), 'idle_frame')
			
	generation_done = true
	emit_signal("generation_done")
	erase_walls()


var erase_fraction = 0.2  # amount of wall removal

func erase_walls():
	# randomly remove a percentage of the map's walls
	for i in range(int(width * height * erase_fraction)):
		# pick a random tile not on the edge
		var x = int(rand_range(1, width-1))
		var y = int(rand_range(1, height-1))
		var cell = Vector2(x, y)
		
		# pick a random neighbor
		var neighbor = null #= cell_walls.keys()[randi() % cell_walls.size()]
		match(get_cellv(cell)):
			5:
				neighbor = Vector2(1, 0)
			7:
				neighbor = Vector2(1, 0)
			10:
				neighbor = Vector2(0, 1)
			11:
				neighbor = Vector2(0, -1)
			13:
				neighbor = Vector2(-1, 0)
			14:
				neighbor = Vector2(0, -1)
		
		# if there's a wall between cell and neighbor, remove it
		if neighbor and get_cellv(cell) & cell_walls[neighbor]:
			var walls = get_cellv(cell) - cell_walls[neighbor]
			var n_walls = get_cellv(cell+neighbor) - cell_walls[-neighbor]
			set_cellv(cell, walls)
			set_cellv(cell+neighbor, n_walls)
