local model = minetest.get_modpath("3d_armor") and "armor" or "normal"

-- Localize functions to avoid table lookups (better performance)
local vector_new = vector.new
local vector_add = vector.add

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
local full_step = {}
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
		local r = math.sin(step / full_step[name] * 2 * math.rad(120))
		rotate(player, CAPE, r*30+35)
		rotate(player, LARM, r*-40)
		rotate(player, RARM, r*40)
		rotate(player, LLEG, r*40)
		rotate(player, RLEG, r*-40)
	end,
	[MINE] = function(player)
		local name = player:get_player_name()
		local r = math.sin(step / full_step[name] * 2 * math.rad(120))
		local pitch = player:get_look_pitch() * 180 / math.pi
		rotate(player, CAPE, r*5+10)
		rotate(player, LARM)
		rotate(player, RARM, r*20+80+pitch)
		rotate(player, LLEG)
		rotate(player, RLEG)
	end,
	[WALK_MINE] = function(player)
		local name = player:get_player_name()
		local r = math.sin(step / full_step[name] * 2 * math.rad(120))
		local pitch = player:get_look_pitch() * 180 / math.pi
		rotate(player, CAPE, r*30+35)
		rotate(player, LARM, r*-40)
		rotate(player, RARM, r*20+80+pitch)
		rotate(player, LLEG, r*40)
		rotate(player, RLEG, r*-40)
	end,
	[SIT] = function(player)
		local body_pos = table.copy(bone_position[model][BODY])
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

-- Animation speed
local function anim_speed(name, bool_sneak)
	local n = bool_sneak and 0.7 or 0.5
	if n ~= full_step[name] then
		full_step[name] = n
	end
end

-- Animate
local current_animation = {}
local function animate(player, anim)
	local name = player:get_player_name()
	if anim == SNEAK or anim == RESET_BODY then
		if current_animation[name][1] ~= anim then
			current_animation[name][1] = anim
			animations[anim](player)
		end
	elseif anim == WALK or anim == MINE or anim == WALK_MINE
	or current_animation[name][2] ~= anim then
		current_animation[name][2] = anim
		animations[anim](player)
	end
end

-- Head animate
local current_head = {}
local function head_rotate(player, controls)
	local pitch = player:get_look_pitch() * 180 / math.pi
	local look = vector_new(pitch, 0, 0)
	if controls.left ~= controls.right then
		look.y = controls.right and 10 or -10
	end

	local name = player:get_player_name()
	local old_pitch, old_look = current_head[name][1], current_head[name][2]
	if old_pitch ~= pitch or (not old_look or not vector.equals(old_look, look)) then
		current_head[name] = {pitch, look}
		rotate(player, HEAD, look.x, look.y, look.z)
	end
end

-- Sneak move
local function sneak(player, bool_sneak)
	animate(player, bool_sneak and SNEAK or RESET_BODY)
end

-- Initialization
minetest.register_on_joinplayer(function(player)
	if model == "normal" then
		player:set_properties({
			mesh = "character.b3d",
			textures = {"character.png"}
		})
	end
	local name = player:get_player_name()
	full_step[name] = 0.5
	current_head[name] = {}
	current_animation[name] = {}
	animate(player, STAND)
end)

-- Remove data
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	full_step[name] = nil
	current_head[name] = nil
	current_animation[name] = nil
end)

minetest.register_globalstep(function(dtime)
	step = dtime+step
	if step >= 3600 then
		step = 0
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		local anim = default.player_get_animation(player).animation

		if anim == "lay" then -- No head rotate
			animate(player, STAND) -- Reset
			animate(player, LAY)
		else
			local name = player:get_player_name()
			local controls = player:get_player_control()
			local bool_sneak = controls.sneak

			if anim == "walk" then
				anim_speed(name, bool_sneak)
				animate(player, WALK)
				sneak(player, bool_sneak)
			elseif anim == "mine" then
				anim_speed(name, bool_sneak)
				animate(player, MINE)
				sneak(player, bool_sneak)
			elseif anim == "walk_mine" then
				anim_speed(name, bool_sneak)
				animate(player, WALK_MINE)
				sneak(player, bool_sneak)
			elseif anim == "sit" then
				animate(player, SIT)
			else
				animate(player, STAND)
				sneak(player, bool_sneak)
			end

			head_rotate(player, controls)
		end
	end
end)
