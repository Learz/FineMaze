class_name ProcPal

var name = ""
var saturation = 1 
var value = 1 
var darkening = 1 
var invertable = true 

func _init(n : String, s : float, v : float, d : float = 0.2 , i : bool = true):
	name = n
	saturation = s
	value = v
	darkening = d
	invertable = i
	
