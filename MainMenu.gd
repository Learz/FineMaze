extends Control

onready var Player = $Player as TileObject
onready var PlayerCamera = $Camera2D

var swipe_start = null
var swipe_start_time = 0
var minimum_drag = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	Player.pos = Vector2(4,15)
	Player.position = Player.pos*64+(Player.get_rect().size/8)
	pass # Replace with function body.


func _input(event):
	if !Player.is_moving:
		if event.is_action_pressed("ui_up"):
			Player.dash(0,-1)
		if event.is_action_pressed("ui_down"):
			Player.dash(0,1)
		if event.is_action_pressed("ui_left"):
			Player.dash(-1,0)
		if event.is_action_pressed("ui_right"):
			Player.dash(1,0)


func _gui_input(event):
	if !Player.is_moving:
		if event.is_action_pressed("click"):
			swipe_start = get_viewport().get_mouse_position()
			swipe_start_time = OS.get_ticks_msec()
		if event.is_action_released("click"):
			calculate_swipe(get_viewport().get_mouse_position())


func calculate_swipe(swipe_end):
	if swipe_start == null: 
		return
	var swipe = swipe_end - swipe_start
	var speed = lerp(1,0.3,clamp(((OS.get_ticks_msec() - swipe_start_time)-100) / 500.0, 0.0, 1.0))
	print(speed)
	if (abs(swipe.x) > abs(swipe.y)):
		if abs(swipe.x) > minimum_drag:
			if swipe.x > 0:
				Player.dash(1,0,speed)
			else:
				Player.dash(-1,0,speed)
	else:
		if abs(swipe.y) > minimum_drag:
			if swipe.y > 0:
				Player.dash(0,1,speed)
			else:
				Player.dash(0,-1,speed)

func _on_GenerateMaze_pressed():
	$Tween.interpolate_property(self, "modulate", modulate, Color(1,1,1,0), 1)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	get_tree().change_scene("res://Maze.tscn")
