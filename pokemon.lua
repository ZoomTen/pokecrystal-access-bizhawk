astar = require("deps/a_star")
serpent = require("deps/serpent")
tolk = require("deps/tolk")

EAST = 1
WEST = 2
SOUTH = 4
NORTH = 8
TEXTBOX_PATTERN = "\x79\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7b"
language_names = {}
camera_x = -1
camera_y = -1
pathfind_switch = false
in_options = false
counter = 0
oldtext = "" -- last text seen
current_item = nil
in_keyboard = false
old_kbd_col = nil
old_kbd_row = nil
BAR_LENGTH = 6
last17 = ""
last_textbox_text = nil
old_pressed_keys = {}

function load_language(code)
	local t = { "chars.lua", "fonts.lua", "ram.lua", "sprites.lua" }
	for i, v in ipairs(t) do
		which = "lang/en/" .. v
		local f = loadfile(which)
		if f ~= nil then
			f()
		end
	end
end

function is_printable_screen()
	local s = ""
	for i = 0, 15 do
		s = s .. string.char(memory.read_u8(RAM_SCREEN + i))
	end
	if fonts[s] then
		return true
	else
		return false
	end
end

function load_table(file)
	local res, t
	fp = io.open(file, "rb")
	if fp ~= nil then
		local data = fp:read("*all")
		res, t = serpent.load(data)
		io.close(fp)
	end
	return res, t
end

function translate(char, above)
	if chars[char] then
		if above then
			return chars[above * 256 + char] or chars[char]
		end
		return chars[char]
	else
		return " "
	end
end

function get_screen()
	local raw_text = memory.read_bytes_as_array(RAM_TEXT, 360)
	local printable = is_printable_screen()
	local lines = {}
	local tile_lines = {}
	local line = ""
	local tile_line = ""
	local menu_position = nil
	local line_number = 0
	for i = 1, 360, 20 do
		line_number = line_number + 1
		for j = 0, 19 do
			local char = raw_text[i + j]
			tile_line = tile_line .. string.char(char)
			if char == 0xed then
				menu_position = i
			end
			if i + j == 359 and char == 0xee then
				char = 0x7f
			end
			if printable then
				if language == "ja" then
					above = (tile_lines[line_number - 1] or ""):sub(j + 1)
					if above ~= "" then
						above = string.byte(above)
					else
						above = nil
					end
					if above == 0x7f then
						above = nil
					end
					char = translate(char, above)
				else
					char = translate(char)
				end
			else -- not printable
				char = " "
			end
			line = line .. char
		end
		table.insert(lines, line)
		table.insert(tile_lines, tile_line)
		line = ""
		tile_line = ""
	end -- i
	return {
		lines = lines,
		menu_position = menu_position,
		tile_lines = tile_lines,
		keyboard_showing = keyboard_showing,
		get_outer_menu_text = get_outer_menu_text,
		get_textbox = get_textbox,
	}
end

function read_text(auto)
	local lines = get_screen().lines
	if auto then
		if trim(lines[15]) == trim(last17) then
			lines[15] = ""
		end
		last17 = lines[17]
		local textbox = get_textbox()
		if textbox and should_read_textbox() then
			textbox_text = table.concat(textbox, "")
			if textbox_text ~= last_textbox_text then
				output_lines(textbox)
			end
			last_textbox_text = textbox_text
			return
		else -- no textbox here
			last_textbox_text = nil
		end -- textbox
	end -- auto
	output_lines(lines)
end

function should_read_textbox()
	if screen.tile_lines[3]:match("\x60\x61") or screen.tile_lines[10]:match("\x60\x61") then
		return true
	end
	if trim(screen.lines[15]) == MSG_HOW_MANY then
		return true
	end
	return false
end

function output_lines(lines)
	for i, line in pairs(lines) do
		line = trim(line)
		if line ~= "" then
			tolk.output(line)
		end
	end
end

function trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

function parse_menu_header()
	local ptr = RAM_MENU_HEADER
	local results = {}
	results.flags = memory.read_u8(ptr)
	results.start_y = memory.read_u8(ptr + 1)
	results.start_x = memory.read_u8(ptr + 2)
	results.end_y = memory.read_u8(ptr + 3)
	results.end_x = memory.read_u8(ptr + 4)
	results.ptr = memory.read_u16_le(ptr + 5)
	return results
end

function get_outer_menu_text(screen)
	local textbox = screen:get_textbox()
	if textbox then
		return trim(table.concat(textbox, " "))
	end
	local header = parse_menu_header()
	local lines = get_screen().lines
	local s = ""
	for i = header.end_y + 1, 18 do
		local line = trim(lines[i])
		if i == 15 and line == trim(last17) then
			line = ""
		end
		if line ~= "" then
			s = s .. line .. "\n"
		end
	end
	return s
end

function read_coords()
	local x, y = get_player_xy()
	tolk.output("x " .. x .. ", y " .. y)
end

function get_warps()
	local current_mapid = get_map_id()
	local eventstart = memory.read_u16_le(RAM_MAP_EVENT_HEADER_POINTER)
	local bank = memory.read_u8(RAM_MAP_SCRIPT_HEADER_BANK)
	eventstart = (bank * 16384) + (eventstart - 16384)
	local warps = memory.read_u8(eventstart + 2, "ROM")
	local results = {}
	local warp_table_start = eventstart + 3
	for i = 1, warps do
		local start = warp_table_start + (5 * (i - 1))
		local warpy = memory.read_u8(start, "ROM")
		local warpx = memory.read_u8(start + 1, "ROM")
		local mapid = memory.read_u8(start + 3, "ROM") * 256 + memory.read_u8(start + 4, "ROM")
		local name = "Warp " .. i
		local mapname = get_map_name(mapid)
		if mapname ~= "" then
			name = mapname
		end
		local warp = { x = warpx, y = warpy, name = name, type = "warp", id = "warp_" .. i }
		warp.name = get_name(current_mapid, warp)
		table.insert(results, warp)
	end
	return results
end

function get_signposts()
	local eventstart = memory.read_u16_le(RAM_MAP_EVENT_HEADER_POINTER)
	local bank = memory.read_u8(RAM_MAP_SCRIPT_HEADER_BANK)
	local mapid = get_map_id()
	eventstart = (bank * 16384) + (eventstart - 16384)
	local warps = memory.read_u8(eventstart + 2, "ROM")
	local ptr = eventstart + 3 -- start of warp table
	ptr = ptr + (warps * 5) -- skip them
	-- skip the xy triggers too
	local xt = memory.read_u8(ptr, "ROM")
	ptr = ptr + (xt * 8) + 1
	local signposts = memory.read_u8(ptr, "ROM")
	ptr = ptr + 1
	-- read out the signposts
	local results = {}
	for i = 1, signposts do
		local posty = memory.read_u8(ptr, "ROM")
		local postx = memory.read_u8(ptr + 1, "ROM")
		local name = "signpost " .. i
		local post = { x = postx, y = posty, name = name, type = "signpost", id = "signpost_" .. i }
		post.name = get_name(mapid, post)
		table.insert(results, post)
		ptr = ptr + 5 -- point at the next one
	end
	return results
end

function get_name(mapid, obj)
	return (names[mapid] or {})[obj.id] or obj.name
end

function get_objects()
	local ptr = RAM_MAP_OBJECTS + 16 -- skip the player
	local liveptr = RAM_LIVE_OBJECTS -- live objects
	local results = {}
	local width = memory.read_u8(RAM_MAP_WIDTH)
	local height = memory.read_u8(RAM_MAP_HEIGHT)
	local mapid = get_map_id()
	for i = 1, 15 do
		local sprite = memory.read_u8(ptr + 0x01)
		local y = memory.read_u8(ptr + 0x02)
		local x = memory.read_u8(ptr + 0x03)
		local facing = memory.read_u8(ptr + 0x04)
		local object_struct = memory.read_u8(ptr)
		-- we have map object structs, and object structs. If the first byte of the
		-- map object struct is not 0xff, use that to look up the object struct,
		-- and get its coords.
		-- if object is on screen and on the map
		local l
		if object_struct ~= 0xff and y ~= 255 then
			if language == "ja" then
				l = RAM_OBJECT_STRUCTS + (object_struct * 40)
			else
				l = RAM_OBJECT_STRUCTS + ((object_struct - 1) * 40)
			end
			x = memory.read_u8(l + 0x12)
			y = memory.read_u8(l + 0x13)
			facing = memory.read_u8(l + 0xd)
		end
		local name = "Object " .. i .. string.format(", %x", ptr)
		if sprites[sprite] ~= nil then
			name = sprites[sprite]
		end
		if y ~= 255 and y - 4 <= height * 2 and x - 4 <= width * 2 then
			if memory.read_u8(liveptr + i) == 0 then
				local obj = {
					x = x - 4,
					y = y - 4,
					name = name,
					type = "object",
					id = "object_" .. i,
					facing = facing,
					sprite_id = sprite,
				}
				obj.name = get_name(mapid, obj)
				table.insert(results, obj)
			end
		end
		ptr = ptr + 16
	end
	local collisions = get_map_collisions()
	for y = 0, #collisions do
		for x = 0, #collisions[0] do
			if collisions[y][x] == 147 then
				table.insert(results, { name = "PC", x = x, y = y, id = "pc", type = "object" })
			end
		end
	end
	return results
end

function get_connections()
	local connections = memory.read_u8(RAM_MAP_CONNECTIONS)
	local function hasbit(x, p)
		return x % (p + p) >= p
	end
	local results = {}
	local function add_connection(dir, mapid)
		local name = dir .. " connection"
		local mapname = get_map_name(mapid)
		if mapname ~= "" then
			name = name .. ", " .. mapname
		end
		table.insert(results, { type = "connection", direction = dir, name = name, id = "connection_" .. dir })
	end

	if hasbit(connections, NORTH) then
		add_connection(
			"north",
			memory.read_u8(RAM_MAP_NORTH_CONNECTION) * 256 + memory.read_u8(RAM_MAP_NORTH_CONNECTION + 1)
		)
	end
	if hasbit(connections, SOUTH) then
		add_connection(
			"south",
			memory.read_u8(RAM_MAP_SOUTH_CONNECTION) * 256 + memory.read_u8(RAM_MAP_SOUTH_CONNECTION + 1)
		)
	end
	if hasbit(connections, EAST) then
		add_connection(
			"east",
			memory.read_u8(RAM_MAP_EAST_CONNECTION) * 256 + memory.read_u8(RAM_MAP_EAST_CONNECTION + 1)
		)
	end
	if hasbit(connections, WEST) then
		add_connection(
			"west",
			memory.read_u8(RAM_MAP_WEST_CONNECTION) * 256 + memory.read_u8(RAM_MAP_WEST_CONNECTION + 1)
		)
	end
	return results
end

function get_map_name(mapid)
	if names[mapid] ~= nil and names[mapid]["map"] ~= nil then
		return names[mapid]["map"]
	elseif language_names[mapid] ~= nil and language_names[mapid].map ~= nil then
		return language_names[mapid].map
	elseif default_names[mapid] ~= nil and default_names[mapid].map ~= nil then
		return default_names[mapid].map
	else
		return ""
	end
end

function get_map_info()
	local mapgroup, mapnumber = get_map_gn()
	local results = { group = mapgroup, number = mapnumber, objects = {} }
	for i, warp in ipairs(get_warps()) do
		table.insert(results.objects, warp)
	end
	for i, signpost in ipairs(get_signposts()) do
		table.insert(results.objects, signpost)
	end
	for i, connection in ipairs(get_connections()) do
		table.insert(results.objects, connection)
	end
	for i, object in ipairs(get_objects()) do
		table.insert(results.objects, object)
	end
	return results
end

function get_map_gn()
	local mapgroup = memory.read_u8(RAM_MAP_GROUP)
	local mapnumber = memory.read_u8(RAM_MAP_NUMBER)
	return mapgroup, mapnumber
end

function get_map_id()
	local group, number = get_map_gn()
	return group * 256 + number
end

-- Returns true or false indicating whether we're on a map or not.
function on_map()
	local mapgroup, mapnumber = get_map_gn()
	if (mapnumber == 0 and mapgroup == 0) or memory.read_u8(RAM_IN_BATTLE) ~= 0 then
		return false
	else
		return true
	end
end

function direction(x, y, destx, desty)
	local s = ""
	if y > desty then
		s = y - desty .. " up"
	elseif y < desty then
		s = desty - y .. " down"
	end
	if x > destx then
		s = s .. " " .. x - destx .. " left"
	elseif x < destx then
		s = s .. " " .. destx - x .. " right"
	end
	return s
end

function only_direction(x, y, destx, desty)
	local s = ""
	if y > desty then
		return "up"
	elseif y < desty then
		return "down"
	elseif x > destx then
		return "left"
	elseif x < destx then
		return "right"
	end
	return s
end

-- Read current and around tiles
function read_tiles()
	local player_x, player_y = get_player_xy()
	local collisions = get_map_collisions()
	local s = string.format("Now %d", collisions[player_y][player_x])

	-- Check up tile
	if player_y > 1 then
		s = s .. string.format(", Up %d", collisions[player_y - 1][player_x])
	else -- up is none
		s = s .. ", Up none"
	end -- Check up tile

	-- Check down tile
	if player_y < #collisions then
		s = s .. string.format(", Down %d", collisions[player_y + 1][player_x])
	else -- Down is none
		s = s .. ", Down none"
	end -- Check down tile

	-- Check left tile
	if player_x > 1 then
		s = s .. string.format(", Left %d", collisions[player_y][player_x - 1])
	else -- left is none
		s = s .. ", Left none"
	end -- Check left tile

	-- Check right tile
	if player_x < #collisions[0] then
		s = s .. string.format(", Right %d", collisions[player_y][player_x + 1])
	else -- right is none
		s = s .. ", Right none"
	end -- Check right tile

	tolk.output(s)
end

-- Playback tile sounds
function play_tile_sound(type, pan, vol, play_stair)
	if type == 0x14 or type == 0x18 then
		tolk.play_sound("sounds/s_grass.wav", 0, pan, vol)
	elseif type == 0x12 then
		tolk.play_sound("sounds/s_cut.wav", 0, pan, vol)
	elseif type == 0x23 then
		tolk.play_sound("sounds/s_ice.wav", 0, pan, vol)
	elseif type == 0x24 then
		tolk.play_sound("sounds/s_whirl.wav", 0, pan, vol)
	elseif type == 0x29 then
		tolk.play_sound("sounds/s_water.wav", 0, pan, vol)
	elseif type == 0x33 then
		tolk.play_sound("sounds/s_waterfall.wav", 0, pan, vol)
	elseif type > 0xA0 then
		tolk.play_sound("sounds/s_mad.wav", 0, pan, vol)
	elseif play_stair and (type == 0x71 or type == 0x72 or type == 0x76 or type == 0x7B) then
		tolk.play_sound("sounds/s_stair.wav", 0, pan, vol)
	elseif play_stair and type == 0x60 then
		tolk.play_sound("sounds/s_hole.wav", 0, pan, vol)
	else
		tolk.play_sound("sounds/s_default.wav", 0, pan, vol)
	end -- switch tile type
end

-- reset camera focus when camera_xy equal -1
function reset_camera_focus(player_x, player_y)
	if camera_x == -1 then
		camera_x = player_x
	end
	if camera_y == -1 then
		camera_y = player_y
	end
end

-- Moving camera focus
function camera_move(y, x, ignore_wall)
	local player_x, player_y = get_player_xy()
	reset_camera_focus(player_x, player_y)
	camera_y = camera_y + y
	camera_x = camera_x + x

	local collisions = get_map_collisions()
	local pan = (camera_x - player_x) * 5
	local vol = 40 - math.abs(player_y - camera_y)

	-- clipping pan and volume
	if pan > 100 then
		vol = vol - ((pan / 5) - 20)
		pan = 100
	end
	if pan < -100 then
		vol = vol - math.abs((pan / 5) - 20)
		pan = -100
	end
	if vol < 5 then
		vol = 5
	end

	if camera_y >= 0 and camera_x >= 0 and camera_y <= #collisions and camera_x <= #collisions[1] then
		local objects = get_objects()
		for i, obj in pairs(objects) do
			if obj.x == camera_x and obj.y == camera_y then
				if obj.sprite_id == 90 then
					tolk.play_sound("sounds/s_boulder.wav", 0, pan, vol)
				elseif obj.sprite_id == 89 then
					tolk.play_sound("sounds/s_rock.wav", 0, pan, vol)
				end -- sprite_id
			end -- obj.xy
		end -- for

		if inpassible_tiles[collisions[camera_y][camera_x]] then
			if ignore_wall then
				camera_x = camera_x - x
				camera_y = camera_y - y
			end
			tolk.play_sound("sounds/s_wall.wav", 0, pan, vol)
		else
			tolk.play_sound("sounds/pass.wav", 0, pan, vol)
			play_tile_sound(collisions[camera_y][camera_x], pan, vol, true)
		end
	else
		camera_x = camera_x - x
		camera_y = camera_y - y
		tolk.play_sound("sounds/s_wall.wav", 0, pan, vol)
	end
end

function set_camera_default()
	camera_x = -1
	camera_y = -1
	camera_move(0, 0, true)
end

function camera_move_left()
	camera_move(0, -1, true)
end

function camera_move_right()
	camera_move(0, 1, true)
end

function camera_move_up()
	camera_move(-1, 0, true)
end

function camera_move_down()
	camera_move(1, 0, true)
end

function camera_move_left_ignore_wall()
	camera_move(0, -1, false)
end

function camera_move_right_ignore_wall()
	camera_move(0, 1, false)
end

function camera_move_up_ignore_wall()
	camera_move(-1, 0, false)
end

function camera_move_down_ignore_wall()
	camera_move(1, 0, false)
end

function compare(t1, t2)
	if #t1 ~= #t2 then
		return false
	end
	for i, v in ipairs(t1) do
		if t1[i] ~= t2[i] then
			return false
		end
	end
	return true
end

function handle_user_actions()
	local kbd = input.get()
	local pressed_keys = {}
	for k, v in pairs(kbd) do
		if v then
			table.insert(pressed_keys, k)
		end
	end
	table.sort(pressed_keys)

	if #pressed_keys == 0 or compare(pressed_keys, old_pressed_keys) then
		old_pressed_keys = pressed_keys
		return
	end
	old_pressed_keys = pressed_keys
	local command
	for keys, cmd in pairs(commands) do
		if compare(keys, pressed_keys) then
			command = cmd
			break
		end
	end
	if command == nil then
		return
	end
	tolk.silence()
	local fn = command[1]
	local needs_map = command[2]
	if needs_map and not on_map() then
		tolk.output("Not on a map.")
	else
		fn()
	end -- not on map
end

function read_current_item()
	local info = get_map_info()
	reset_current_item_if_needed(info)
	read_item(info.objects[current_item])
end

function reset_current_item_if_needed(info)
	if info.group * 256 + info.number ~= current_map then
		current_item = 1
		current_map = info.group * 256 + info.number
	elseif info.objects[current_item] == nil then
		current_item = 1
	end
end

function read_next_item()
	local info = get_map_info()
	reset_current_item_if_needed(info)
	current_item = current_item + 1
	if current_item > #info.objects then
		current_item = 1
	end
	read_current_item()
end

function read_previous_item()
	local info = get_map_info()
	reset_current_item_if_needed(info)
	current_item = current_item - 1
	if current_item == 0 or current_item > #info.objects then
		current_item = #info.objects
	end
	read_current_item()
end

function set_pathfind_switch()
	pathfind_switch = not pathfind_switch

	if pathfind_switch then
		tolk.output("enable special skils.")
		inpassible_tiles[18] = false
		inpassible_tiles[36] = false
		inpassible_tiles[41] = false
		inpassible_tiles[51] = false
	else
		tolk.output("disable special skils.")
		inpassible_tiles[18] = true
		inpassible_tiles[36] = true
		inpassible_tiles[41] = true
		inpassible_tiles[51] = true
	end
end

function pathfind()
	local info = get_map_info()
	reset_current_item_if_needed(info)
	local obj = info.objects[current_item]
	find_path_to(obj)
end

function read_item(item)
	local x, y = get_player_xy()
	local map_id = get_map_id()
	local s = get_name(mapid, item)
	if item.x then
		s = s .. ": " .. direction(x, y, item.x, item.y)
	end
	if item.facing then
		s = s .. " facing " .. facing_to_string(item.facing)
	end
	tolk.output(s)
end

function get_map_blocks()
	-- map width, height in blocks
	local width = memory.read_u8(RAM_MAP_WIDTH)
	local height = memory.read_u8(RAM_MAP_HEIGHT)
	local row_width = width + 6 -- including border
	ptr = 0xc800             -- start of overworld
	-- there is a border of 3 blocks on each edge of the map.
	local blocks = {}
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local block = memory.read_u8(ptr + (width + 6) * 3 + (y * row_width) + (x + 3))
			blocks[y] = blocks[y] or {}
			blocks[y][x] = block
		end
	end
	return blocks
end

function get_map_collisions()
	local blocks = get_map_blocks()
	local width = #blocks[0]
	local collisions = {}
	function add_collision(x, y, type)
		collisions[y] = collisions[y] or {}
		collisions[y][x] = type
	end

	local collision_bank = memory.read_u8(RAM_COLLISION_BANK)
	local collision_addr = memory.read_u16_le(RAM_COLLISION_ADDR)
	collision_addr = (collision_bank * 16384) + (collision_addr - 16384)

	for y = 0, #blocks do
		for x = 0, width do
			-- Each block is a 2x2 walkable tile. The collision data is
			-- (top left, top right, bottom left, bottom right).
			-- We have block data for the first half of the xy pair here.
			local block_index = blocks[y][x]
			local ptr = collision_addr + (block_index * 4)
			add_collision(x * 2, y * 2, memory.read_u8(ptr, "ROM"))
			add_collision(x * 2 + 1, y * 2, memory.read_u8(ptr + 1, "ROM"))
			add_collision(x * 2, y * 2 + 1, memory.read_u8(ptr + 2, "ROM"))
			add_collision(x * 2 + 1, y * 2 + 1, memory.read_u8(ptr + 3, "ROM"))
		end -- x
	end -- y
	return collisions
end

function find_path_to(obj)
	local path
	local width = memory.read_u8(RAM_MAP_WIDTH)
	local height = memory.read_u8(RAM_MAP_HEIGHT)

	if obj.type == "connection" then
		if obj.direction == "north" then
			dest_y = 0
			for dest_x = 0, width * 2 - 1 do
				if not inpassible_tiles[get_collision_data_xy(dest_x + 4, dest_y + 3)] then
					path = find_path_to_xy(dest_x, dest_y)
				end
				if path ~= nil then
					break
				end
			end
		elseif obj.direction == "south" then
			dest_y = height * 2 - 1
			for dest_x = 0, width * 2 - 1 do
				if not inpassible_tiles[get_collision_data_xy(dest_x + 4, dest_y + 5)] then
					path = find_path_to_xy(dest_x, dest_y)
				end
				if path ~= nil then
					break
				end
			end
		elseif obj.direction == "east" then
			dest_x = width * 2 - 1
			for dest_y = 0, height * 2 - 1 do
				if not inpassible_tiles[get_collision_data_xy(dest_x + 5, dest_y + 4)] then
					path = find_path_to_xy(dest_x, dest_y)
				end
				if path ~= nil then
					break
				end
			end
		elseif obj.direction == "west" then
			dest_x = 0
			for dest_y = 0, height * 2 - 1 do
				if not inpassible_tiles[get_collision_data_xy(dest_x + 3, dest_y + 4)] then
					path = find_path_to_xy(dest_x, dest_y)
				end
				if path ~= nil then
					break
				end
			end
		end
	else
		path = find_path_to_xy(obj.x, obj.y, true)
	end
	if path == nil then
		tolk.output("no path")
		return
	end
	speak_path(clean_path(path))
end

function find_path_to_xy(dest_x, dest_y, search)
	local player_x, player_y = get_player_xy()
	local collisions = get_map_collisions()
	local allnodes = {}
	local width = #collisions[0]
	local start = nil
	local dest = nil
	-- set all the objects to walls
	for i, object in ipairs(get_objects()) do
		collisions[object.y][object.x] = 7
	end
	for i, warp in ipairs(get_warps()) do
		if warp.x ~= dest_x and warp.y ~= dest_y then
			collisions[warp.y][warp.x] = 7
		end
	end
	if inpassible_tiles[collisions[dest_y][dest_x]] then
		local to_search = {
			{ dest_y + 1, dest_x },
			{ dest_y - 1, dest_x },
			{ dest_y - 2, dest_x },
			{ dest_y,     dest_x + 1 },
			{ dest_y,     dest_x - 1 },
			{ dest_y,     dest_x + 2 },
			{ dest_y,     dest_x - 2 },
		}
		if search then
			for i, pos in ipairs(to_search) do
				if
					collisions[pos[1]] ~= nil
					and collisions[pos[1]][pos[2]] ~= nil
					and not inpassible_tiles[collisions[pos[1]][pos[2]]]
				then
					dest_y = pos[1]
					dest_x = pos[2]
					break
				end
			end
		else
			return nil
		end
	end
	-- generate the all nodes list for pathfinding, and track the start and end nodes
	for y = 0, #collisions do
		for x = 0, width do
			local n = { x = x, y = y, type = collisions[y][x] }
			table.insert(allnodes, n)
			if x == player_x and y == player_y then
				start = n
			end
			if x == dest_x and y == dest_y then
				dest = n
			end
		end -- x
	end -- y
	local valid = function(node, neighbor)
		if node.type == 0xa0 and neighbor.x == node.x + 2 and neighbor.y == node.y then
			return true
		elseif node.type == 0xa1 and neighbor.x == node.x - 2 and neighbor.y == node.y then
			return true
		elseif node.type == 0xa2 and neighbor.x == node.x and neighbor.y == node.y - y then
			return true
		elseif node.type == 0xa3 and neighbor.x == node.x and neighbor.y == node.y + 2 then
			return true
		elseif astar.dist_between(node, neighbor) ~= 1 then
			return false
		elseif inpassible_tiles[neighbor.type] then
			return false
		end
		return true
	end -- valid
	path = astar.path(start, dest, allnodes, true, valid)
	return path
end

function clean_path(path)
	local start = path[1]
	local new_path = {}
	for i, node in ipairs(path) do
		if i > 1 then
			local last = path[i - 1]
			table.insert(new_path, only_direction(last.x, last.y, node.x, node.y))
		end -- i > 1
	end -- for
	return group_unique_items(new_path)
end

function speak_path(path)
	for _, v in ipairs(path) do
		tolk.output(v[2] .. " " .. v[1])
	end
end

inpassible_tiles = {
	[7] = true,
	[18] = true,
	[21] = true,
	[36] = true,
	[38] = true,
	[39] = true,
	[41] = true,
	[51] = true,
	[144] = true,
	[145] = true,
	[149] = true,
	[163] = false,
	[165] = false,
	[178] = true,
}

function rename_current()
	local info = get_map_info()
	reset_current_item_if_needed(info)
	local id = get_map_id()
	local obj_id = info.objects[current_item].id
	name = inputbox.inputbox(
		"Name object",
		"Enter a new name for " .. info.objects[current_item].name,
		info.objects[current_item].name
	)
	if name == nil then
		return
	end
	names[id] = names[id] or {}
	if trim(name) ~= "" then
		names[id][obj_id] = trim(name)
	else
		names[id][obj_id] = nil
	end
	write_names()
end

function write_names()
	local file = io.open("names.lua", "wb")
	file:write(serpent.block(names, { comment = false }))
	io.close(file)
	tolk.output("names saved")
end

function rename_map()
	local id = get_map_id()
	local obj_id = "map"
	name = inputbox.inputbox("Rename map", "Enter a new name for " .. names[id][obj_id], names[id][obj_id])
	if name == nil then
		return
	end
	names[id] = names[id] or {}
	if trim(name) ~= "" then
		names[id][obj_id] = trim(name)
	else
		names[id][obj_id] = nil
	end
	write_names()
end

function read_mapname()
	local name = get_map_name(get_map_id())
	tolk.output(name)
end

function read_menu_item(lines, pos)
	local line = math.floor(pos / 20) + 1
	local l = lines[line]
	tolk.play_sound("sounds/menusel.wav", 0, (200 * (line - 1) / #lines) - 100, 30)
	tolk.output(l)
	if lines[line + 1]:match("\xc2\xa5") then
		tolk.output(lines[line + 1])
	end
	if in_options and not lines[line + 1]:match("^%s*$") then
		tolk.output(lines[line + 1])
	end
end

function get_enemy_health()
	local function read_bar(addr)
		local count
		-- no bar here
		if memory.read_u8(addr + BAR_LENGTH) ~= 0x6b then
			return nil
		end
		local total = 0
		for i = 0, BAR_LENGTH - 1 do
			if memory.read_u8(addr + i) == 0x6a then
				total = total + 1
			end
		end
		return total
	end
	local enemy = read_bar(RAM_TEXT + (2 * 20) + 4)
	if enemy == nil then
		return nil
	else
		return string.format("%d of %d", enemy, BAR_LENGTH)
	end
end

function read_enemy_health()
	local health = get_enemy_health()
	if health == nil then
		tolk.output("no bar found")
	else
		tolk.output(enemy_health)
	end
end

function group_unique_items(t)
	if #t == 0 then
		return t
	end
	if #t == 1 then
		return { { t[1], 1 } }
	end
	local nt = {}
	local last = t[1]
	local last_count = 1
	for i = 2, #t do
		if t[i] == last then
			last_count = last_count + 1
		else
			table.insert(nt, { last, last_count })
			last = t[i]
			last_count = 1
		end
	end
	table.insert(nt, { last, last_count })
	return nt
end

function read_keyboard()
	local x = memory.read_u8(RAM_KEYBOARD_X)
	local y = memory.read_u8(RAM_KEYBOARD_Y)
	local t = KEYBOARD_UPPER
	if screen.lines[17]:match(KEYBOARD_UPPER_STRING) ~= nil then
		t = KEYBOARD_LOWER
	end
	local word = t[y + 1][x + 1] or "unknown"
	tolk.output(word)
end

function get_block(mapx, mapy)
	local width = memory.read_u8(RAM_MAP_WIDTH)
	local row_width = width + 6
	local ptr = 0xc801 + row_width
	-- now we're on the second row, second column
	local skip_rows = math.floor(mapy / 2)
	local skip_cols = math.floor(mapx / 2)
	local block = memory.read_u8(ptr + (skip_rows * row_width) + skip_cols)
	return block
end

function get_collision_data(block)
	local collision_bank = memory.read_u8(RAM_COLLISION_BANK)
	local collision_addr = memory.read_u16_le(RAM_COLLISION_ADDR)
	collision_addr = (collision_bank * 16384) + (collision_addr - 16384)
	return memory.gbromreadbyterange(collision_addr + (block * 4), 4)
end

function get_collision_data_xy(mapx, mapy)
	local block = get_block(mapx, mapy)
	if block == 0 then
		return 255
	end
	local data = get_collision_data(block)
	if mapx % 2 == 0 then
		i = 1
	else
		i = 2
	end
	if mapy % 2 ~= 0 then
		i = i + 2
	end
	return data[i]
end

function keyboard_showing(screen)
	if screen.lines[17]:match(KEYBOARD_STRING) ~= nil then
		return true
	end
	return false
end

function get_textbox()
	local lines = {}
	if screen.tile_lines[13] == TEXTBOX_PATTERN then
		for i = 14, 17 do
			table.insert(lines, screen.lines[i])
		end
		return lines
	end
	return nil
end

function handle_keyboard()
	col = memory.read_u8(RAM_KEYBOARD_X)
	row = memory.read_u8(RAM_KEYBOARD_Y)
	if row ~= old_kbd_row or col ~= old_kbd_col then
		read_keyboard()
		old_kbd_row = row
		old_kbd_col = col
	end -- if the row/col changed
end

function read_health_if_needed()
	if not (last_menu_pos == nil and screen.menu_position ~= nil) then
		return
	end
	enemy_health = get_enemy_health()
	if enemy_health == nil then
		return
	end
	tolk.output(screen.lines[11])
	tolk.output("enemy health: " .. enemy_health)
end

function facing_to_string(d)
	d = d >> 2
	if d == 0 then
		return "down"
	end
	if d == 1 then
		return "up"
	end
	if d == 2 then
		return "left"
	end
	if d == 3 then
		return "right"
	end
	return "unknown"
end

function get_player_xy()
	return memory.read_u8(RAM_PLAYER_X), memory.read_u8(RAM_PLAYER_Y)
end

commands = {
	[{ "Y" }] = { read_coords, true },
	[{ "J" }] = { read_previous_item, true },
	[{ "K" }] = { read_current_item, true },
	[{ "L" }] = { read_next_item, true },
	[{ "P" }] = { pathfind, true },
	[{ "P", "shift" }] = { set_pathfind_switch, true },
	[{ "T" }] = { read_text, false },
	[{ "R" }] = { read_tiles, true },
	[{ "M" }] = { read_mapname, true },
	[{ "K", "shift" }] = { rename_current, true },
	[{ "M", "shift" }] = { rename_map, true },
	[{ "S" }] = { camera_move_left, true },
	[{ "F" }] = { camera_move_right, true },
	[{ "E" }] = { camera_move_up, true },
	[{ "C" }] = { camera_move_down, true },
	[{ "D" }] = { set_camera_default, true },
	[{ "S", "shift" }] = { camera_move_left_ignore_wall, true },
	[{ "F", "shift" }] = { camera_move_right_ignore_wall, true },
	[{ "E", "shift" }] = { camera_move_up_ignore_wall, true },
	[{ "C", "shift" }] = { camera_move_down_ignore_wall, true },
	[{ "H" }] = { read_enemy_health, false },
}

function main_loop()
	counter = counter + 1
	handle_user_actions()
	screen = get_screen()
	local text = table.concat(screen.lines, "")
	if screen:keyboard_showing() then
		handle_keyboard()
	end -- handling keyboard
	if text ~= oldtext then
		want_read = true
		text_updated_counter = counter
		oldtext = text
	end
	if want_read and (counter - text_updated_counter) >= 20 then
		-- if we're in a menu
		if screen.menu_position ~= nil then
			-- if the menu outer text changed
			outer_text = screen:get_outer_menu_text()
			if not in_options and last_outer_text ~= outer_text then
				-- probably a different menu, mom's questions cause this
				if outer_text ~= "" then
					tolk.output(outer_text)
				end
				last_outer_text = outer_text
			end
			read_health_if_needed()
			read_menu_item(screen.lines, screen.menu_position)
			last_menu_pos = screen.menu_position
		else
			last_menu_pos = nil
			if in_options then
				in_options = false
			end
			read_text(true)
		end
		want_read = false
	end
end

function on_footstep()
	local type = memory.read_u8(RAM_STANDING_TILE)
	camera_x = -1
	camera_y = -1
	play_tile_sound(type, 0, 30, false)
end

function on_bankswitch()
	if emu.getregister("A") == 57 and emu.getregister("H") == 0x41 and emu.getregister("L") == 0xd0 then
		in_options = true
	end
end

-- main

tolk.output("ready")
res, names = load_table("names.lua")

if res == nil then
	names = {}
end

res, default_names = load_table("lang/en/" .. "default_names.lua")

if res == nil then
	tolk.output("Unable to load default names file.")
	default_names = {}
end

load_language("en")
event.on_bus_exec(on_footstep, RAM_FOOTSTEP_FUNCTION)
event.on_bus_exec(on_bankswitch, RAM_BANK_SWITCH)
event.onframeend(main_loop, "frame loop")
