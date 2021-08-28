extends Control

export (Array, Resource) var palettes : Array
export (Vector2) var resolution_override

onready var Goal = $ViewportContainer/Viewport/Goal
onready var Map = $ViewportContainer/Viewport/TileMap
onready var Background = $ViewportContainer/Viewport/Background

var game_started = false

var pal : Array = [
	ProcPal.new("B&W",0,1,1,false),
	ProcPal.new("Basic",1,1,0.5),
	ProcPal.new("Pastel",0.2,1),
	ProcPal.new("Contrast",1,1,1,false),
	]
var cur_pal = 1

onready var Player = $ViewportContainer/Viewport/Player
onready var Trail = $ViewportContainer/Viewport/Trail
onready var PlayerCamera = $ViewportContainer/Viewport/Camera2D
onready var zoom_multiplier = float(Map.width)/(get_viewport().size.x / Map.tile_size)
onready var zoom_level = min(12.0/(get_viewport().size.x / Map.tile_size), zoom_multiplier)

var swipe_start = null
var swipe_start_time = 0
var minimum_drag = 50

func _init():
	pass

func _ready():
	randomize()
#	if !map_seed:
#		map_seed = randi()
#	seed(map_seed)
#	print("Seed: ", map_seed)

#	if resolution_override:
#		get_viewport().size = resolution_override
#	else:
#		get_viewport().size = OS.get_window_size()
	PlayerCamera.zoom = Vector2(zoom_level,zoom_level)
	PlayerCamera.offset = Vector2(0,-200)
	PlayerCamera.rotation_degrees = -20
	
	
	Map.tile_size = Map.cell_size.x
	
#	Background.rect_min_size = Vector2(width*2*tile_size, height*2*tile_size)
	PlayerCamera.limit_right = Map.width*Map.tile_size
	PlayerCamera.limit_bottom = Map.height*Map.tile_size
	Goal.position = Vector2((Map.width*Map.tile_size)-Map.tile_size, (Map.height*Map.tile_size)-Map.tile_size)
	Goal.pos = Vector2(Map.width-1,Map.height-1)
#	$Viewport.size = Vector2(width,height)*tile_size
	Trail.add_point(Player.position)
	change_color()
	Map.make_maze()


func _input(event):
	if Map.generation_done and !Player.is_moving:
		if event.is_action_pressed("ui_up"):
			Player.dash(0,-1)
		if event.is_action_pressed("ui_down"):
			Player.dash(0,1)
		if event.is_action_pressed("ui_left"):
			Player.dash(-1,0)
		if event.is_action_pressed("ui_right"):
			Player.dash(1,0)
		if event.is_action_pressed("restart"):
			restart()


func _gui_input(event):
	if Map.generation_done and !Player.is_moving:
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


func _physics_process(delta):
	if Map.generation_done:
		PlayerCamera.position = Player.position
		Trail.set_point_position(Trail.get_point_count()-1, Player.position)


func restart():
	Map.generation_done = false
	Player.pos = Vector2(0,0)
	Player.scale = Vector2(0.25,0.25)
	$Tween.remove(PlayerCamera)
	$Tween.interpolate_property(Player, "position", Player.position, Vector2(0,0)+(Player.get_rect().size/8), 1, Tween.TRANS_CUBIC)
	$Tween.interpolate_property(PlayerCamera, "zoom", PlayerCamera.zoom, Vector2(zoom_multiplier, zoom_multiplier), 1, Tween.TRANS_QUINT, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	Trail.clear_points()
	Trail.add_point(Player.position)
	zoom_level = min(12.0/(get_viewport().size.x / Map.tile_size), zoom_multiplier)
	change_color()
	Map.make_maze()

func change_color():
	$PauseMenu/MenuScreen/PaletteButton.text = pal[cur_pal].name
	var main_color = Color(0).from_hsv(randf(),pal[cur_pal].saturation,pal[cur_pal].value)
	var invert = (randi()%2)*int(pal[cur_pal].invertable)
##	var cur_palette = palettes.colors[palettes.size()-1]
#	var cur_palette = palettes[0].colors[randi() % palettes[0].colors.size()]
	$Tween.interpolate_property(Map, "modulate", Map.modulate, main_color.darkened(pal[cur_pal].darkening*invert), 1)
	$Tween.interpolate_property(Background, "color", Background.color, main_color.darkened(pal[cur_pal].darkening*(1-invert)), 1)
	$Tween.interpolate_property(Trail, "default_color", Trail.default_color, main_color.darkened(pal[cur_pal].darkening*(1-invert)).linear_interpolate(Color.white, 0.5), 1)
	$Tween.start()


func _on_TextureButton_pressed():
	$PauseMenu/MenuScreen.visible = !$PauseMenu/MenuScreen.visible


func _on_RestartBtn_pressed():
	$PauseMenu/MenuScreen.visible = false
	restart()


func _on_PrevPal_pressed():
	cur_pal = (cur_pal-1)%pal.size()
	change_color()


func _on_NextPal_pressed():
	cur_pal = (cur_pal+1)%pal.size()
	change_color()


func _on_PaletteLabel_pressed():
	cur_pal = (cur_pal+1)%pal.size()
	change_color()


func _on_StartButton_pressed():
	$Tween.interpolate_property($MainMenu, "modulate", $MainMenu.modulate, Color(1,1,1,0), 1, Tween.TRANS_QUINT)
	$Tween.interpolate_property(PlayerCamera, "offset", PlayerCamera.offset, Vector2(0,0), 1, Tween.TRANS_QUINT)
	$Tween.interpolate_property(PlayerCamera, "rotation_degrees", PlayerCamera.rotation_degrees, 0, 1, Tween.TRANS_QUINT)
	$Tween.interpolate_property(PlayerCamera, "zoom", PlayerCamera.zoom, Vector2(zoom_multiplier,zoom_multiplier), 1, Tween.TRANS_QUINT)
	$Tween.start()
	$Timer.stop()
	$Timer.start(0.1)
	$PauseMenu.visible = true
	game_started = true


func _on_Tween_tween_completed(object, key):
	if(object == $MainMenu):
		$MainMenu.visible = false


func _on_TileMap_generation_done():
	if not game_started:
		$Timer.start()
		yield($Timer, "timeout")
		if not game_started:
			Map.make_maze(0.2)
			return
	$Tween.interpolate_property(PlayerCamera, "zoom", PlayerCamera.zoom, Vector2(zoom_level,zoom_level), 3, Tween.TRANS_QUINT, Tween.EASE_IN_OUT)
	$Tween.start()
