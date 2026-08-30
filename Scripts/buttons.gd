extends Node

@export var option_screen: MarginContainer
@export var board: Board
@export var page2: ColorRect
@export var page1: ColorRect
@export var numberbutton: Button
@export var help_icons: Array[Sprite2D]

signal newgame
var change = false

func _ready():
	board.trigger_reset.connect(set_change)
	newgame.connect(board.reset)

func set_default():
	get_tree().reload_current_scene()

func quit_pressed():
	get_tree().quit()

func toggle_visibility(object):
	object.visible = !object.visible
		

func options_pressed():
	if option_screen.visible && change:
		change = false
		newgame.emit()
	toggle_visibility(option_screen)
	toggle_visibility(board)
	
	if board.visible:
		page1.visible = false
		page2.visible = false
		numberbutton.visible = false
	else:
		numberbutton.visible = true
		numberbutton.text = "(1/2)"
		page2.visible = false
		page1.visible = true
		icon_visibility(true)

func icon_visibility(visible):
	for icon in help_icons:
		icon.visible = visible			
	
func set_change():
	change = true
	
func next_pressed():
	toggle_visibility(page1)
	toggle_visibility(page2)
	if page2.is_visible_in_tree():
		numberbutton.text = "(2/2)"
		icon_visibility(false)
	else:
		numberbutton.text ="(1/2)"
		icon_visibility(true)
