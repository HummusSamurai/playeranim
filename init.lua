local model = minetest.get_modpath("3d_armor") and "armor" or "normal"

-- Localize functions to avoid table lookups (better performance)
local vector_new = vector.new
local vector_add = vector.add
local vector_equals = vector.equals
local math_sin = math.sin
local math_deg = math.deg
local get_animation = default.player_get_animation
local get_connected_players = minetest.get_connected_players

-- Animation alias
local STAND = 1
local WALK = 2
local MINE = 3
local WALK_MINE = 4
local SIT = 5
local LAY = 6
local SNEAK = 7
local RESET_BODY = 8

-- Bone alias
local BODY = "Body"
local HEAD = "Head"
local CAPE = "Cape"
local LARM = "Arm_Left"
local RARM = "Arm_Right"
local LLEG = "Leg_Left"
local RLEG = "Leg_Right"

local bone_position = {
	normal = {
		[BODY] = vector_new(0, -3.5, 0),
		[HEAD] = vector_new(0, 6, 0),
		[CAPE] = vector_new(0, 6.5, 1.5),
		[LARM] = vector_new(-3.9, 6.5, 0),
		[RARM] = vector_new(3.9, 6.5, 0),
		[LLEG] = vector_new(-1, 0, 0),
		[RLEG] = vector_new(1, 0, 0)
	},
	armor = {
		[BODY] = vector_new(0, -3.5, 0),
		[HEAD] = vector_new(0, 6.75, 0),
		[CAPE] = vector_new(0, 6.75, 1.5),
		[LARM] = vector_new(2, 6.5, 0),
		[RARM] = vector_new(-2, 6.5, 0),
		[LLEG] = vector_new(1, 0, 0),
		[RLEG] = vector_new(-1, 0, 0)
	}
}

local bone_rotation = {
	normal = {
		[BODY] = vector_new(0, 0, 0),
		[HEAD] = vector_new(0, 0, 0),
		[CAPE] = vector_new(0, 0, 180),
		[LARM] = vector_new(180, 0, 0),
		[RARM] = vector_new(180, 0, 0),
		[LLEG] = vector_new(0, 0, 0),
		[RLEG] = vector_new(0, 0, 0)
	},
	armor = {
		[BODY] = vector_new(0, 0, 0),
		[HEAD] = vector_new(0, 0, 0),
		[CAPE] = vector_new(180, 0, 180),
		[LARM] = vector_new(180, 0, 9),
		[RARM] = vector_new(180, 0, -9),
		[LLEG] = vector_new(0, 0, 0),
		[RLEG] = vector_new(0, 0, 0)
	}
}

local function rotate(player, bone, x, y, z)
	local rotation = vector_add(vector_new(x or 0, y or 0, z or 0), bone_rotation[model][bone])
	player:set_bone_position(bone, bone_position[model][bone], rotation)
end

local step = 0
local animation_speed = {}
local look_pitch = {}

local animations = {
	[STAND] = function(player)
		rotate(player, BODY)
		rotate(player, CAPE)
		rotate(player, LARM)
		rotate(player, RARM)
		rotate(player, LLEG)
		rotate(player, RLEG)
	end,
	[WALK] = function(player)
		local name = player:get_player_name()
		local swing = math_sin(step * 4 * animation_speed[name])
		rotate(player, CAPE, swing * 30 + 35)
		rotate(player, LARM, swing * -40)
		rotate(player, RARM, swing * 40)
		rotate(player, LLEG, swing * 40)
		rotate(player, RLEG, swing * -40)
	end,
	[MINE] = function(player)
		local name = player:get_player_name()
		local pitch = look_pitch[name]
		local swing = math_sin(step * 4 * animation_speed[name])
		local hand_swing = math_sin(step * 8 * animation_speed[name])
		rotate(player, CAPE, swing * 5 + 10)
		rotate(player, LARM)
		rotate(player, RARM, hand_swing * 20 + 80 + pitch)
		rotate(player, LLEG)
		rotate(player, RLEG)
	end,
	[WALK_MINE] = function(player)
		local name = player:get_player_name()
		local pitch = look_pitch[name]
		local swing = math_sin(step * 4 * animation_speed[name])
		local hand_swing = math_sin(step * 8 * animation_speed[name])
		rotate(player, CAPE, swing * 30 + 35)
		rotate(player, LARM, swing * -40)
		rotate(player, RARM, hand_swing * 20 + 80 + pitch)
		rotate(player, LLEG, swing * 40)
		rotate(player, RLEG, swing * -40)
	end,
	[SIT] = function(player)
		local body_pos = vector_new(bone_position[model][BODY])
		body_pos.y = body_pos.y - 6
		player:set_bone_position(BODY, body_pos, vector_new(0, 0, 0))
		rotate(player, LARM)
		rotate(player, RARM)
		rotate(player, LLEG, 90)
		rotate(player, RLEG, 90)
	end,
	[LAY] = function(player)
		player:set_bone_position(BODY, vector_new(0, -9, 0), vector_new(270, 0, 0))
		rotate(player, HEAD)
	end,
	[SNEAK] = function(player)
		rotate(player, BODY, 5)
	end,
	[RESET_BODY] = function(player)
		rotate(player, BODY)
	end
}

local function update_look_pitch(player)
	local name = player:get_player_name()
	local pitch = math_deg(player:get_look_pitch())

	if look_pitch[name] ~= pitch then
		look_pitch[name] = pitch
	end
end

local function set_animation_speed(player, bool_sneak)
	local name = player:get_player_name()
	local speed = bool_sneak and 0.75 or 2

	if animation_speed[name] ~= speed then
		animation_speed[name] = speed
	end
end

local current_animation = {}

local function set_animation(player, anim)
	local name = player:get_player_name()

	if anim == LAY or anim == SNEAK or anim == RESET_BODY then
		if current_animation[name][1] ~= anim then
			current_animation[name][1] = anim
			animations[anim](player)
		end
		return
	end

	if anim == WALK or anim == MINE or anim == WALK_MINE then
		current_animation[name][2] = anim
		animations[anim](player)
		return
	end

	if current_animation[name][2] ~= anim then
		current_animation[name][2] = anim
		animations[anim](player)
	end
end

local current_head = {}

local function head_rotate(player, controls)
	local name = player:get_player_name()

	local pitch = look_pitch[name]
	local look = vector_new(pitch, 0, 0)
	if controls.left ~= controls.right then
		look.y = controls.right and 10 or -10
	end

	local old_pitch, old_look = current_head[name][1], current_head[name][2]
	if old_pitch ~= pitch or (not old_look or not vector_equals(old_look, look)) then
		current_head[name] = {pitch, look}
		rotate(player, HEAD, look.x, look.y, look.z)
	end
end

local function set_sneak_animation(player, bool_sneak)
	set_animation(player, bool_sneak and SNEAK or RESET_BODY)
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	current_head[name] = {}
	current_animation[name] = {}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	animation_speed[name] = nil
	look_pitch[name] = nil
	current_head[name] = nil
	current_animation[name] = nil
end)

minetest.register_globalstep(function(dtime)
	step = step + dtime
	if step >= 3600 then
		step = 1
	end

	for _, player in ipairs(get_connected_players()) do
		local animation = get_animation(player).animation

		if animation == "lay" then -- No head rotate
			set_animation(player, STAND) -- Reset
			set_animation(player, LAY)
		else
			local controls = player:get_player_control()
			local bool_sneak = controls.sneak

			update_look_pitch(player)

			if animation == "walk" then
				set_animation_speed(player, bool_sneak)
				set_animation(player, WALK)
				set_sneak_animation(player, bool_sneak)
			elseif animation == "mine" then
				set_animation_speed(player, bool_sneak)
				set_animation(player, MINE)
				set_sneak_animation(player, bool_sneak)
			elseif animation == "walk_mine" then
				set_animation_speed(player, bool_sneak)
				set_animation(player, WALK_MINE)
				set_sneak_animation(player, bool_sneak)
			elseif animation == "sit" then
				set_animation(player, SIT)
			else
				set_animation(player, STAND)
				set_sneak_animation(player, bool_sneak)
			end

			head_rotate(player, controls)
		end
	end
end)
