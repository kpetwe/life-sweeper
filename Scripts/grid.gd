extends TileMapLayer

class_name Board 

# Sprite map
const CELLS = {
	"1": Vector2i(0, 0),
	"2": Vector2i(1, 0),
	"3": Vector2i(2, 0),
	"4": Vector2i(3, 0),
	"5": Vector2i(4, 0),
	"6": Vector2i(0, 1),
	"7": Vector2i(1, 1),
	"8": Vector2i(2, 1),
	"0": Vector2i(3, 1),
	"RM": Vector2i(4, 1),
	"F": Vector2i(0,2),
	"M": Vector2i(1,2),
	"B": Vector2i(2,2)
}

# source color on sprite map
const TILE_SET_ID = 2

# Board specs
@export var rows = 8
@export var cols = 8
@export var mines = 10

"""
	Game of Life Update Maps
	DEAD = Safe tiles
	ALIVE = Mine tiles
	Index = # neighboring mine tiles
	Value = 0 if dead, 1 if alive at next stage
"""
@export var GOL_DEAD = [0, 0, 0, 1, 0, 0, 0, 0, 0]
@export var GOL_ALIVE = [0, 0, 1, 1, 0, 0, 0, 0, 0]
@export var gol_on = false
@export var view_mines = false


# Tracks cells in the game using hashing
var flagged_cells = {}
var checked_cells = {}
var mine_cells = {}

var game_over = false

"""
	Initializes Scene
"""
func _ready():
	assert(mines < rows * cols && mines >= 0 && rows > 0 && 
		cols > 0 && rows <= 30 && cols <= 24 && mines < 667)
	clear()
	init_board()
	#init_mines()
	#display_text(str(mines) + "/" + str(mines) + "\nMINE\nSWEEPER", -1)
	display_text(default_text(), -1)

func check_mines():
	if (mines > (rows-1)*(cols-1)):
		print("true")
		mines = 10
		mine_spin_box.value = mines
		reset()
		display_text(flag_difference() + "ERROR:\nMINES > " + str((rows-1)*(cols-1)), 1)	


"""
	Button Signals
"""

@export var mine_spin_box: SpinBox

func reset():
	game_over = false
	first_click = true
	flagged_cells = {}
	checked_cells = {}
	mine_cells = {}
	_ready()
	
signal trigger_reset

func set_gol(toggle:bool):
	gol_on = toggle
	if gol_on:
		display_text(flag_difference() + "GOL ON", 1)
	else:
		display_text(flag_difference() + "GOL OFF", 1)
	
func set_view_mines(toggle:bool):
	view_mines = toggle
	if view_mines:
		display_text(flag_difference() + "MINE VIEW\nON", 1)
	else:
		display_text(flag_difference() + "MINE VIEW\nOFF", 1)
	trigger_reset.emit()
	
func set_rows(r):
	trigger_reset.emit()
	rows = int(r)
	check_mines()

func set_cols(c):
	trigger_reset.emit()
	cols = int(c)
	check_mines()

func set_mines(m):
	trigger_reset.emit()
	mines = int(m)
	check_mines()

func set_gol_array(toggle:bool, clicked:String):
	trigger_reset.emit()
	if (clicked[0] == "A"):
		GOL_ALIVE[int(clicked[1])] = toggle
	else:
		GOL_DEAD[int(clicked[1])] = toggle
	


"""
	Draws a blank board
"""
func init_board():
	#print(rows, " ", cols)
	for i in rows:
		for j in cols:
			set_tile_cell(Vector2i(i - rows/2, j-cols/2), "B")

"""
	Forces neighboring 1 tile radius to be safe
"""
var first_click = true
func on_first_click(fcell:Vector2i):
	first_click = false
	init_mines(fcell)
	cell_update(fcell)


"""
	Stores addresses of initial mines
"""
func init_mines(fcell: Vector2i):
	var nbhd = get_neighborhood(fcell, true, false)
	#var nbhd = {}
	#for i in range(-1,2):
		#for j in range(-1,2):
			#nbhd[fcell + Vector2i(i, j)] = null
	
	while mine_cells.size() < mines:
		var cell = Vector2i(randi_range(-rows/2, rows/2-1 + rows % 2), 
			randi_range(-cols/2, cols/2-1 + cols % 2))
		if !nbhd.has(cell):
			mine_cells[cell] = null	
	reveal_mines(mine_cells)
	
"""
	Handle mouse interaction with screen
	@param InputEvent event: event to handle
"""
func _input(event: InputEvent):
	# can change to shade darker when hovering perhaps
	if event is not InputEventMouseButton || !event.pressed || !self.visible || game_over:
		return
		
	# turns mouse click into integer/grid coords
	var cell = local_to_map(get_local_mouse_position())
	#print(cell)
	
	# Clicking flag button resets flags
	if cell.x == 20 && cell.y == -12:
		reset_flags()
	
	if !in_bounds(cell) :
		return
		
	if (event.button_index == 1 || event.button_index == 2) && first_click:
		on_first_click(cell)
		return 

	if event.button_index == 1 && !flagged_cells.has(cell):
		grid_update(cell, true)
	elif event.button_index == 2:
		flag_update(cell)
		

"""
	Updates flag on board
	@param Vector2i cell: Cell to add or remove a flag from
"""
func flag_update(cell: Vector2i):
	if (checked_cells.has(cell)):
		return
	if flagged_cells.has(cell):
		erase_cell(cell)
		set_tile_cell(cell, "B")
		flagged_cells.erase(cell)
		display_text(default_text(), -1)
		# go back to displaying mine if needed
		if mine_cells.has(cell):
			reveal_mines({cell:null})	
	elif flagged_cells.size() < mine_cells.size():
		erase_cell(cell)
		set_tile_cell(cell, "F")
		flagged_cells[cell] = null
		# a little redundant but doesn't print "OUT OF FLAGS" otherwise
		display_text(default_text(), -1)	
	elif flagged_cells.size() >= mine_cells.size():
		display_text(flag_difference() + "OUT OF\n FLAGS", 1)

"""
	Recalls all flags if button is clicked
"""
func reset_flags():
	for flag in flagged_cells:
		erase_cell(flag)
		set_tile_cell(flag, "B")
	flagged_cells = {}
	display_text(default_text(), -1)
	reveal_mines(mine_cells)


"""
	Display Text
"""

@export var display: RichTextLabel

func flag_difference():
	if first_click:
		return "\t" + str(mines) + "/" + str(mines) + "\n"
	
	return "\t" + str(mine_cells.size() - flagged_cells.size()) + "/" + str(mine_cells.size()) + "\n"

func default_text():
	return flag_difference() + "MINE\nSWEEPER"

func display_text(txt: String, delay:int):
	display.text = txt
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		display_text(default_text(), -1)
		

"""
	Updates Grid display
	@param Vector2i cell: Location of cell that was clicked
	@param bool safe: True if it's safe to perform GOL update 
"""
func grid_update(cell: Vector2i, safe: bool):
	# Unsafe tile hit
	if mine_cells.has(cell):
		display_text(flag_difference() + "GAME\nLOST", -1)
		game_over = true
		reveal_mines(mine_cells)
		set_tile_cell(cell, "RM")
		return
	
	# Reveal neighboring tiles if enough flags placed
	elif checked_cells.has(cell):
		safe = neighbor_update(cell)
	
	# Safe tile hit
	elif !checked_cells.has(cell):
		cell_update(cell)
		
	# Evolves board at end of move
	if gol_on && safe:
		gol_update()
		
	display_text(default_text(), -1)
	
	# All safe tiles revealed
	if game_won():
		display_text(flag_difference() + "GAME\nWON", -1)
		game_over = true
		reveal_mines(mine_cells)

"""
	Check if the game is won
"""
func game_won():
	var safe_tiles = (rows*cols - mine_cells.size())
	var known_safe = checked_cells.size()
	if (gol_on):
		# Prevents game for ending early if a dead cells
		# comes to life
		for mine in mine_cells:
			if checked_cells.has(mine):
				known_safe -= 1
	
	return known_safe >= safe_tiles
		
"""
	Display location of mines
"""
func reveal_mines(mine_set):
	if (view_mines || game_over):
		for cell in mine_set:
			erase_cell(cell)
			set_tile_cell(cell, "M")

"""
	If enough flags have been put down, reveal neighboring
	tiles.
	@param Vector2i cell: Location of cell that was clicked
	@return bool: true if it is safe to perform GOL update
"""
func neighbor_update(cell: Vector2i):
	var nbhd = get_neighborhood(cell, false, false)
	var mc = count_mines(cell, nbhd)
	var fc = 0
	var safe = false
	
	# Check that there's a matching number of flags
	for nbh in nbhd:
		if flagged_cells.has(nbh):
			fc += 1
	#for i in range(-1, 2):
		#for j in range(-1, 2):
			#if flagged_cells.has(Vector2i(i, j) + cell):
				#fc += 1
	if mc == fc:
		# Update hidden cells
		for nbh in nbhd:
			if !checked_cells.has(nbh) && !flagged_cells.has(nbh):
				grid_update(nbh, false)
				safe = true
		#for i in range(-1, 2):
			#for j in range(-1, 2):
				#var tc = Vector2i(i, j) + cell
				## prevent infinite loop and revealing a mine tile as "safe"
				#if !checked_cells.has(tc) && !flagged_cells.has(tc):
					#grid_update(tc, false)
					#safe = true
	return safe
	

"""
	Recursively reveals safe tiles
	@param Vector2i cell: location of cell we're revealing
"""
func cell_update(cell: Vector2i):
	if !in_bounds(cell) || checked_cells.has(cell):
		return
		
	if flagged_cells.has(cell):
		flagged_cells.erase(cell)
	
	var nbhd = get_neighborhood(cell, false, false)
	var mc = count_mines(cell, nbhd)
	
	# casts integer to string for numbered tiles
	set_tile_cell(cell, "%d" % mc)
	# add revealed tile to list
	checked_cells[cell] = null

	# add neighboring safe tiles to list
	if mc == 0:
		for nbh in nbhd:
			cell_update(nbh)
		#for i in range(-1, 2):
			#for j in range(-1, 2):
				#if (i != 0 || j != 0):
					#cell_update(cell + Vector2i(i, j))

"""
	Perform game of life updates on the board grid
"""	
func gol_update():
	var new_mine_cells = {}
	
	# loops through grid an updates mines
	for i in rows:
		for j in cols:
			var cell = Vector2i(i - rows/2, j-cols/2)
			var mc = count_mines(cell, get_neighborhood(cell, false, true))
			var res
			if mine_cells.has(cell):
				res = GOL_ALIVE[mc]
			else:
				res = GOL_DEAD[mc]
			if res:
				new_mine_cells[cell] = null
					
	
	# View GOL Updates
	if(view_mines):
		for mine in new_mine_cells:
			if(!mine_cells.has(mine)):
				erase_cell(mine)
				set_tile_cell(mine, "M")
		for mine in mine_cells:
			if(!new_mine_cells.has(mine)):
				erase_cell(mine)
				set_tile_cell(mine, "B")
	
	mine_cells = new_mine_cells
	
	# Update visible cells
	for cell in checked_cells:
		erase_cell(cell)
		if mine_cells.has(cell):
			set_tile_cell(cell, "M")
		else:
			var mc = count_mines(cell, get_neighborhood(cell, false, false))
			set_tile_cell(cell, "%d" % mc)
	
	for cell in flagged_cells:
		erase_cell(cell)
		set_tile_cell(cell,"F")

"""
	Counts the number of neighboring mines
	@param Vector2i cell: location of cell we're checking
	@return int: number of mines
"""
func count_mines(cell: Vector2i, nbhd:Dictionary):
	var mc = 0
	#var nbhd = get_neighborhood(cell, false, false)
	for nbh in nbhd:
		if mine_cells.has(nbh):
			mc += 1
	#for i in range(-1, 2):
		#for j in range(-1, 2):
			#if (i!= 0 || j !=0) && mine_cells.has(cell + Vector2i(i, j)):
				#mc += 1
	return mc

# Sets tile display
func set_tile_cell(cell:Vector2i, type): 
	set_cell(cell, TILE_SET_ID, CELLS[type])

# Check if cell is on the grid
func in_bounds(cell: Vector2i):
	if (cell.x >= -rows/2 && cell.x <= rows/2 -1 + rows % 2):
		if (cell.y >= -cols/2 && cell.y <= cols/2 - 1 + cols % 2):
			return true
	return false

# Get neighboring cells
func get_neighborhood(cntr:Vector2i, include_self:bool, wrap:bool):
	var nbhd = {}
	for i in range(-1, 2):
		for j in range(-1, 2):
			var cell = cntr + Vector2i(i, j)
			# if i am including the center cell or i am not including the
			# center cell and this cell is a valid neighbor
			if (include_self || (!include_self && (i != 0 || j != 0))):
				# either cell is in bounds (if-else statements not entered
				# or the cell is out of bounds but we're including wrapped cells
				if (in_bounds(cell) || wrap):
					if cell.x < -rows/2:
						cell.x = rows/2 - 1 + rows % 2
					elif cell.x > rows/2 - 1 + rows % 2:
						cell.x = -rows/2
					if cell.y < -cols/2:
						cell.y = cols/2 - 1 + cols % 2
					elif cell.y > cols/2 - 1 + cols % 2:
						cell.y = -cols/2
					nbhd[cell] = null
	return nbhd
